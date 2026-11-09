return table.freeze({
	gold = Color3.fromRGB(255, 211, 27),
	whiteGold = Color3.fromRGB(255, 251, 180),
	stone = Color3.fromRGB(103, 98, 75),
	 -- Phase 5 (Enhanced): a barrage. 10 to 15 rocks, thrown one after another every throwGap seconds - he never waits for
	 -- one to land. rockScale shrinks them so fifteen fit round him; blockWaveDamage is each landing's ring (there are many)
	rocks = { 10, 15 }, rockScale = 0.55, throwGap = 0.3, blockWaveDamage = 8,
})
