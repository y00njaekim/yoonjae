export EDITOR=nvim
export VISUAL=nvim
alias vi=nvim
alias vim=nvim

# history
alias history='fc -l 1'
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
