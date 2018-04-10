class Const
	if RUBY_PLATFORM[/darwin/]
		FONT = 'Apple Symbols'
		PIECE_FIX_X = 12
		PIECE_FIX_Y = 20
		FOG_SIZE = 70
		FOG_FIX_X = 3
		FOG_FIX_Y = -15
		PROMO_FIX_X = 3
		PROMO_FIX_Y = 10
	else
		FONT = 'Arial'
		PIECE_FIX_X = 10
		PIECE_FIX_Y = 10
		FOG_SIZE = 45
		FOG_FIX_X = 0
		FOG_FIX_Y = -10
		PROMO_FIX_X = 0
		PROMO_FIX_Y = 0
	end
end
