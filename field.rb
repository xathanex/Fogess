require 'Const'

class Field
	SIZE = 70

	attr_accessor :active, :piece, :fogged
	attr_reader :x, :y, :piece, :active

	def initialize x, y, board, painter
		@x = x; @y = y
		@pos = { x: x*SIZE+100, y: (8-y)*SIZE }
		
		if (x+y).odd?
			@color = :beige
			@active_color = :palegreen
		else
			@color = :sienna
			@active_color = :seagreen
		end
		
		@piece = nil
		@last_active = @active = false
		@last_fogged = @fogged = true
		
		@painter = painter
		if @painter
			@painter.fill @painter.public_send(color)
			@r = @painter.rect(left: @pos[:x], top: @pos[:y], width: SIZE)
			@r.click do
				board.clicked(self)
			end
			@fog = @painter.para("\u2601", left: @pos[:x]+Const::FOG_FIX_X, top: @pos[:y]+Const::FOG_FIX_Y, font: Const::FONT, stroke: @painter.gray, size: Const::FOG_SIZE)
		end
	end

	def check_fog is_white, board
		dist = [-1, 0, 1]
		@fogged = board.flat_fields.none? do |f|
			val = (dist.include?(f.x - @x) and dist.include?(f.y - @y))
			val and f.piece and f.piece.is_white == is_white and !f.is_a?(EnPassant)
		end
	end

	def color
		if @active
			@active_color
		else
			@color
		end
	end

	def draw
		return if @painter.nil?
		
		@r.style(fill: @painter.public_send(color)) if @active != @last_active
		(@fogged ? @fog.show : @fog.hide) if @fogged != @last_fogged
			
		if @piece
			@piece.toggle(!@fogged)
			@piece.draw(@pos[:x], @pos[:y])
		end

		@last_active = @active
		@last_fogged = @fogged
	end

	def to_s
		"#{x}:#{y}:#{ piece ? piece.to_s : '-' }"
	end
end
