require 'Board'
require 'Piece'

Shoes.app(width: 800, height: 600, title: 'Fogess') do
	background white
	b = Board.new(self)
	Board.game_board = b
	(1..8).each do |col|
		b.set(Pawn.new(true, self), col, 2)
		b.set(Pawn.new(false, self), col, 7)
	end
	b.set(Rook.new(true, self), 1, 1); b.set(Rook.new(true, self), 8, 1)
	b.set(Rook.new(false, self), 1, 8); b.set(Rook.new(false, self), 8, 8)
	b.set(Knight.new(true, self), 2, 1); b.set(Knight.new(true, self), 7, 1)
	b.set(Knight.new(false, self), 2, 8); b.set(Knight.new(false, self), 7, 8)
	b.set(Bishop.new(true, self), 3, 1); b.set(Bishop.new(true, self), 6, 1)
	b.set(Bishop.new(false, self), 3, 8); b.set(Bishop.new(false, self), 6, 8)
	b.set(Queen.new(true, self), 4, 1)
	b.set(Queen.new(false, self), 4, 8)
	b.set(King.new(true, self), 5, 1)
	b.set(King.new(false, self), 5, 8)
	Board.add_to_history(b)
	b.flat_fields.each{|f| f.check_fog(true, b) }
	b.draw
	finish do
		quit
	end
end
