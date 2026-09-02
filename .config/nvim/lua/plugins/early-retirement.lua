return {
	{
		"chrisgrieser/nvim-early-retirement",
		event = "VeryLazy",
		config = true,
		opts = {
			retirementAgeMins = 20,
			ignoreAltFile = true, -- 직전 버퍼는 보호
			minimumBufferNum = 10, -- 이 개수 넘을 때만 동작
			ignoreUnsavedChangesBufs = true,
			ignoreVisibleBufs = true, -- 창에 떠 있으면 보호
			notificationOnAutoClose = false,
		},
	},
}
