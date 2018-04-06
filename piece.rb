class Piece
	FONT = 'Apple Symbols'
	BLACK = :black
	WHITE = :orange
	attr_accessor :first_move, :is_white

	def initialize white, painter
		@first_move = true
		@is_white = !!white

		reset_moves

		@painter = painter
		@painter.fill(@painter.black)
		@painter.stroke(@painter.black)
		@fig = @painter.title(@figure, font: FONT, stroke: @painter.public_send(@is_white ? WHITE : BLACK))
	end

	def draw x, y
		@fig.move(x+12, y+20) if @last_pos != [x, y]
		@last_pos = [x, y]
	end

	def toggle show
		if show
			@fig.show
		else
			@fig.hide
		end
	end

	def remove
		@fig.remove
	end

	def check_move from, to, board, check_check = true
		if check_check
			after_move_board = board.clone
			after_move_board.fields[to.x][to.y].piece = after_move_board.fields[from.x][from.y].piece
			after_move_board.fields[from.x][from.y].piece = nil
			return !after_move_board.check_check(from.piece.is_white)
		end
		true
	end

	def reset_moves
		@moves = {}
		(1..8).each do |x|
			@moves[x] = {}
			(1..8).each do |y|
				@moves[x][y] = nil
			end
		end
	end

	def can_move? from, to, board, check_check = true
		@moves[to.x][to.y] = check_move(from, to, board, check_check) if @moves[to.x][to.y].nil?
		@moves[to.x][to.y]
	end

	def have_move? from, board
		board.flat_fields.any?{|to| can_move?(from, to, board) }
	end

	def to_s
		"#{ @is_white ? 'W' : 'B'}#{ self.class.name[0] }"
	end
end

class Pawn < Piece
	def initialize white, painter
		@figure = "\u265F"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = false
		dir = @is_white ? 1 : -1
		if to.x - from.x == 0
			valid = to.piece.nil?
			valid &&= ((to.y - from.y == dir) or (to.y - from.y == dir*2 and @first_move and board.fields[from.x][from.y+dir].piece.nil?))
		elsif [-1, 1].include?(to.x - from.x)
			valid = (to.piece and to.piece.is_white != @is_white)
			valid &&= to.y - from.y == dir
		end
		valid and super(from, to, board, check_check)
	end
end

class EnPassant < Piece
	def initialize white, painter
		@figure = (@is_white ? "\u2659" : "\u265F")
		super white, painter
		remove
	end

	def check_move from, to, board, check_check = true
		false
	end

	def to_s
		'-'
	end
end

class Rook < Piece
	def initialize white, painter
		@figure = "\u265C"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = (from.x == to.x or from.y == to.y)
		valid &&= (to.piece.nil? or to.piece.is_white != @is_white or to.piece.is_a?(EnPassant))

		min_x, max_x = [from.x, to.x].sort
		min_y, max_y = [from.y, to.y].sort

		valid &&= begin
			v = true
			max_x.downto(min_x).each do |x|
				max_y.downto(min_y).each do |y|
					field = board.fields[x][y]
					v &&= (field.piece.nil? or field.piece.is_a?(EnPassant)) if field != from and field != to
				end
			end
			v
		end

		valid and super(from, to, board, check_check)
	end
end

class Knight < Piece
	def initialize white, painter
		@figure = "\u265E"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = (to.piece.nil? or to.piece.is_white != @is_white or to.piece.is_a?(EnPassant))
		valid &&= (([-1, 1].include?(to.x - from.x) and [-2, 2].include?(to.y - from.y)) or ([-2, 2].include?(to.x - from.x) and [-1, 1].include?(to.y - from.y)))
		valid and super(from, to, board, check_check)
	end
end

class Bishop < Piece
	def initialize white, painter
		@figure = "\u265D"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = (to.piece.nil? or to.piece.is_white != @is_white or to.piece.is_a?(EnPassant))
		valid &&= [(to.y - from.y), (from.y - to.y)].include?(to.x - from.x)

		min_x, max_x = [from.x, to.x].sort
		min_y, max_y = [from.y, to.y].sort

		valid &&= begin
			v = true
			max_x.downto(min_x).each do |x|
				max_y.downto(min_y).each do |y|
					if [y - from.y, from.y - y].include?(x - from.x)
						field = board.fields[x][y]
						v &&= (field.piece.nil? or field.piece.is_a?(EnPassant)) if field != from and field != to
					end
				end
			end
			v
		end

		valid and super(from, to, board, check_check)
	end
end

class Queen < Piece
	def initialize white, painter
		@figure = "\u265B"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = (to.piece.nil? or to.piece.is_white != @is_white or to.piece.is_a?(EnPassant))

		rook_con = Proc.new{|x, y| x == from.x or y == from.y }
		bishop_con = Proc.new{|x, y| [y - from.y, from.y - y].include?(x - from.x) }
		con = if rook_con.call(to.x, to.y)
			rook_con
		elsif bishop_con.call(to.x, to.y)
			bishop_con
		end
		valid &&= !con.nil?

		min_x, max_x = [from.x, to.x].sort
		min_y, max_y = [from.y, to.y].sort

		valid &&= begin
			v = true
			max_x.downto(min_x).each do |x|
				max_y.downto(min_y).each do |y|
					if con and con.call(x, y)
						field = board.fields[x][y]
						v &&= (field.piece.nil? or field.piece.is_a?(EnPassant)) if field != from and field != to
					end
				end
			end
			v
		end

		valid and super(from, to, board, check_check)
	end
end

class King < Piece
	def initialize white, painter
		@figure = "\u265A"
		super white, painter
	end

	def check_move from, to, board, check_check = true
		valid = (to.piece.nil? or to.piece.is_white != @is_white or to.piece.is_a?(EnPassant))
		if to.y == from.y and [-2, 2].include?(to.x - from.x)
			valid &&= @first_move
			rook_x = (to.x - from.x == 2 ? 8 : 1)
			rook = board.fields[rook_x][from.y].piece
			valid &&= (rook and rook.first_move and rook.is_white == @is_white)
			valid &&= !board.check_check(@is_white)
			valid &&= begin
				target = board.fields[(to.x + from.x)/2][from.y]
				check_move(from, target, board, true) and target.piece.nil?
			end
		else
			valid &&= [-1, 0, 1].include?(to.x - from.x)
			valid &&= [-1, 0, 1].include?(to.y - from.y)
			valid &&= to != from
		end
		valid and super(from, to, board, check_check)
	end
end
