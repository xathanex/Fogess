require 'Field'
require 'Piece'

class Board
	attr_reader :fields

	def initialize painter
		@active = true
		@white_turn = true
		@moves_since_last_capture = 0

		@painter = painter
		@fields = {}
		(1..8).each do |row|
			@painter.para((9-row).to_s, top: row*Field::SIZE-Field::SIZE/1.5, left: 100) if @painter
			@fields[row] = {}
			(1..8).each do |col|
				@fields[row][col] = Field.new(row, col, self, painter)
			end
		end
		if @painter
			@painter.fill(@painter.black)
			('A'..'H').each_with_index do |letter, i|
				@painter.para(letter, top: 8*Field::SIZE, left: 120+(i+1)*Field::SIZE)
			end
		end
	end

	def draw
		@overlay ||= @painter.rect(left: 0, top: 0, width: 800, fill: @painter.gray).tap(&:hide)
		@fields.each do |row, cols|
			cols.each do |col, field|
				field.draw
			end
		end
	end

	def set piece, x, y
		@fields[x][y].piece = piece
	end

	def move from_field, to_field
		@active = false
		promotion = false
		captured = from_field.piece.is_a?(Pawn)
		en_passant_field = nil


		if from_field.piece.is_a?(King) and [-2, 2].include?(to_field.x - from_field.x)
			rook_from_x = (to_field.x - from_field.x > 0 ? 8 : 1)
			rook_to_x = (to_field.x + from_field.x)/2

			from_rook_field = @fields[rook_from_x][from_field.y]
			to_rook_field = @fields[rook_to_x][from_field.y]

			to_rook_field.piece = from_rook_field.piece
			from_rook_field.piece = nil
		elsif from_field.piece.is_a?(Pawn) 
			if [-2, 2].include?(to_field.y - from_field.y)
				en_passant = EnPassant.new(from_field.piece.is_white, @painter)
				en_passant_field = @fields[from_field.x][(to_field.y + from_field.y)/2]
				set(en_passant, en_passant_field.x, en_passant_field.y)
			elsif to_field.piece.is_a?(EnPassant)
				pawn_field = @fields[to_field.x][from_field.y]
				pawn_field.piece.remove
				pawn_field.piece = nil
				captured = true
			elsif (from_field.piece.is_white ? 8 : 1) == to_field.y
				promotion = true
			end
		end

		if to_field.piece
			to_field.piece.remove
			captured = true
		end
		from_field.piece.first_move = false
		to_field.piece = from_field.piece
		from_field.piece = nil

		flat_fields.each do |f|
			if f.piece.is_a?(EnPassant) and f != en_passant_field
				f.piece.remove
				f.piece = nil 
			end
		end
	
		if promotion
			@promotion_field = to_field
			@painter.dialog(width: 250, height: 70, title: 'Promotion') do
				background white
				{ "\u265C" => Rook, "\u265E" => Knight, "\u265D" => Bishop, "\u265B" => Queen }.each_with_index do |pair, index|
					sign, klass = pair
					fill white
					stroke black
					x = 10+60*index
					y = 10
					r = rect(left: x, top: y, width: 50)
					r.click do
						Board.game_board.promote_to(klass)
						close
					end
					t = title(sign, font: Const::FONT, left: x+Const::PROMO_FIX_X, top: y+Const::PROMO_FIX_Y, stroke: public_send(Board.game_board.turn ? Piece::WHITE : Piece::BLACK))
				end
				finish do
					Board.game_board.promote_to(Queen)
				end
			end
		else
			move_done(captured)
		end
	end

	def flat_fields
		@fields.values.flat_map(&:values)
	end

	def check_end_condition
		self.class.add_to_history(self)
		fields = flat_fields.select{|f| f.piece and f.piece.is_white == @white_turn }
		done = if fields.none?{|f| f.piece.have_move?(f, self) }
			if check_check(@white_turn)
				"Checkmate! #{ @white_turn ? 'Black' : 'White' } wins."
			else
				"Stalemate! It's a draw."
			end
		elsif @moves_since_last_capture >= 50
			"Fifty-move rule! It's a draw."
		elsif self.class.threefold_repetition?
			"Threefold Repetition! It's a draw."
		end
		if done
			flat_fields.each{|f| f.fogged = false }
			draw
			@painter.alert(done, title: 'Game Over')
			@painter.quit
		end
		done
	end

	def clicked field
		return unless @active
		if @active_field.nil? and field.piece and !field.piece.is_a?(EnPassant) and field.piece.is_white == @white_turn
			@active_field = field
			flat_fields.each do |target|
				target.active = @active_field.piece.can_move?(@active_field, target, self)
			end
			@active_field.active = true
		elsif @active_field and @active_field != field and @active_field.piece.can_move?(@active_field, field, self)
			move(@active_field, field)
			@fields.values.flat_map(&:values).map{|f| f.active = false }
			@active_field = nil
		elsif @active_field and @active_field == field
			@fields.values.flat_map(&:values).map{|f| f.active = false }
			@active_field = nil
		end
		draw
	end

	def promote_to piece_klass
		is_white = @promotion_field.piece.is_white
		@promotion_field.piece.remove
		@promotion_field.piece = nil
		set(piece_klass.new(is_white, @painter), @promotion_field.x, @promotion_field.y)
		move_done(true)
	end

	def move_done captured
		@promotion_field = nil
		@active = true
		if captured
			@moves_since_last_capture = 0
		else
			@moves_since_last_capture += 1
		end
		@white_turn = !@white_turn
		flat_fields.map(&:piece).compact.each(&:reset_moves)
		if !check_end_condition
			flat_fields.each{|f| f.check_fog(@white_turn, self) }
			draw

			@overlay.show
			@painter.alert("Your move, #{ @white_turn ? 'White' : 'Black' }.", title: nil)
			@overlay.hide
		end
	end

	def check_check white
		fields = flat_fields
		king_field = fields.find{|f| f.piece and f.piece.is_white == white and f.piece.is_a?(King) }
		fields.any?{|f| f.piece and f.piece.is_white != white and f.piece.check_move(f, king_field, self, false) }
	end

	def clone
		new_board = self.class.new(nil)
		flat_fields.select(&:piece).each do |f|
			new_board.set(f.piece, f.x, f.y)
		end
		new_board
	end

	def turn
		@white_turn
	end

	def to_s
		s = ""
		(1..8).each do |x|
			(1..8).each do |y|
				piece = @fields[x][y].piece
				s = "#{s}#{ piece ? piece.to_s : '--' }"
			end
		end
		s
	end

	def self.add_to_history board
		@history ||= []
		@history << board.to_s
	end

	def self.threefold_repetition?
		pattern = @history.last
		@history.count(pattern) >= 3
	end

	def self.game_board= board
		@game_board = board
	end

	def self.game_board
		@game_board
	end
end
