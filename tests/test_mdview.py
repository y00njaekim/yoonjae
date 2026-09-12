import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('state', ROOT / '.claude/bin/mdview-state.py')
state = importlib.util.module_from_spec(spec)
spec.loader.exec_module(state)


class ThreadRouting(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.options = {}
        self.enterContext(patch.object(state, 'ROOT', Path(self.temp.name)))
        self.enterContext(patch.dict(os.environ, TMUX='/tmp/test,1,0', TMUX_PANE='%1'))
        self.enterContext(patch.object(state, 'tmux', side_effect=self.tmux))

    def tmux(self, *args):
        pane = args[args.index('-t') + 1]
        if args[0] == 'show-options':
            return self.options.get(pane, '')
        if '-pu' in args:
            self.options.pop(pane, None)
        else:
            self.options[pane] = args[-1]
        return ''

    def event(self, sid, event='Stop', text='answer', provider='claude', **extra):
        state.capture(provider, dict(session_id=sid, hook_event_name=event,
                                    last_assistant_message=text, **extra))

    def test_two_panes_and_providers_with_same_id(self):
        self.event('same', text='Claude\n\nanswer')
        with patch.dict(os.environ, TMUX_PANE='%2'):
            self.event('same', text='Codex answer', provider='codex')
        self.assertEqual(state.resolve('%1').read_text(), 'Claude\n\nanswer\n')
        self.assertEqual(state.resolve('%2').read_text(), 'Codex answer\n')
        self.assertEqual(state.resolve('%1'), state.ROOT / '.claude/last-message/threads/same/latest.md')
        self.assertEqual(state.resolve('%2'), state.ROOT / '.codex/last-message/threads/same/latest.md')

    def test_switch_and_late_stop(self):
        self.event('old')
        self.event('new', 'SessionStart')
        with self.assertRaises(ValueError):
            state.resolve('%1')
        self.event('old', text='late')
        self.event('old', 'SessionEnd')
        self.assertEqual(self.options['%1'], 'claude/new')
        self.event('new', text='new answer')
        self.assertEqual(state.resolve('%1').read_text(), 'new answer\n')
        self.event('new', 'SessionEnd')
        with self.assertRaises(ValueError):
            state.resolve('%1')

    def test_resume_and_prompt_rebind(self):
        self.event('first', text='saved')
        self.event('second', 'UserPromptSubmit')
        self.event('first', 'SessionStart')
        self.assertEqual(state.resolve('%1').read_text(), 'saved\n')

    def test_no_global_fallback_or_path_traversal(self):
        (state.ROOT / 'latest.md').write_text('wrong thread')
        with self.assertRaises(ValueError):
            state.resolve('%1')
        with self.assertRaises(ValueError):
            self.event('../escape')

    def test_transcript_preserves_multiline_and_skips_tools(self):
        path = state.ROOT / 'transcript.jsonl'
        path.write_text('\n'.join([json.dumps({'type': 'assistant', 'message': {'content': [
            {'type': 'text', 'text': 'line one\nline two'},
            {'type': 'text', 'text': 'paragraph'}]}}),
            json.dumps({'type': 'assistant', 'message': {'content': [{'type': 'tool_use'}]}}), '{partial']))
        self.event('test', text='', transcript_path=str(path))
        self.assertEqual(state.resolve('%1').read_text(), 'line one\nline two\n\nparagraph\n')

    def test_subagent_does_not_hijack_pane_or_answer(self):
        self.event('parent')
        self.event('child', agent_id='child')
        self.assertEqual(self.options['%1'], 'claude/parent')
        self.assertFalse((state.ROOT / '.claude/last-message/threads/child').exists())

    def test_without_tmux_still_saves_by_id(self):
        with patch.dict(os.environ, TMUX=''):
            self.event('desktop', provider='codex')
        self.assertEqual(self.options, {})
        self.assertEqual((state.ROOT / '.codex/last-message/threads/desktop/latest.md').read_text(), 'answer\n')


class CodexThreadRouting(ThreadRouting):
    def setUp(self):
        super().setUp()
        global state
        original = state
        codex_spec = importlib.util.spec_from_file_location('codex_state', ROOT / '.codex/bin/mdview-state.py')
        state = importlib.util.module_from_spec(codex_spec)
        codex_spec.loader.exec_module(state)
        self.addCleanup(lambda: globals().__setitem__('state', original))
        self.enterContext(patch.object(state, 'ROOT', Path(self.temp.name)))
        self.enterContext(patch.object(state, 'tmux', side_effect=self.tmux))


if __name__ == '__main__':
    unittest.main()
