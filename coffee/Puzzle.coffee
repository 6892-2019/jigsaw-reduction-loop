render = undefined

JS.require 'JS.Set', 'JS.Hash', (Set, Hash) ->

	sum = (nums) -> _.reduce nums, ((total, num) -> num + total), 0
	target_sum_3_partition = (nums) -> sum(nums) * 3 / nums.length
	
	class Piece
		
		# Rotation degrees
		@CCW_0 = 0
		@CCW_90 = 1
		@CCW_180 = 2
		@CCW_270 = 3
		# Basic piece of a puzzle
		constructor: (@position) -> # [x, y]
		
		rotate: ->

		
	class Block extends Piece
		# Stores entries in right, top, left, bottom order
		constructor: (position, @entries) -> super position 
		
		# Entry indices
		@RIGHT = 0
		@TOP = 1
		@LEFT = 2
		@BOTTOM = 3
		
		rotate: (amount) -> 
			for i in [0...amount]
				@entries.unshift @entries.pop()
				
		# SVG
		@Tile = SVG.invent(
			create: 'g'
			inherit: SVG.G
			extend:
				constructor_: (entries) ->
					@rect(1, 1).fill('ivory').move -0.5, -0.5
					colors = ['#000', '#555', '#aaa', '#fff']
					for i in [0...4]
						@polygon([[0.5, -0.5], [0.25, -0.25], [0.25, 0.25], [0.5, 0.5]]).fill(colors[entries[i] %% colors.length]).rotate -90 * i, 0, 0
					return this
					
			construct:
				block_tile: (entries) -> @put(new Block.Tile).constructor_ entries
		)
		
		@tile_before_drag = (e) ->
			@should_rotate = true
			
		@tile_drag_move = (e) ->
			@front()
			[x, y] = [Math.floor(@cx()), Math.floor(@cy())]
			if x != @piece.position[0] or y != @piece.position[1]
				@should_rotate = false
				@puzzle.swap_pieces @piece.position[0], @piece.position[1], x, y
				
		@tile_drag_end = (e) ->
			@x @piece.position[0] + 0.5
			@y @piece.position[1] + 0.5
			if @should_rotate
				@rotate @transform().rotation - 90
				@piece.rotate()
				
		
		#@STRIP_COLORS = ['#f00', '#f80', '#840', '#fc0', '#ff0', '#8f0', '#0f0', '#0f8', '#0ff', '#088', '#08f', '#00f', '#80f', '#808', '#f0f', '#f08']
		@STRIP_COLORS = ['#f00', '#ff0', '#0f0', '#0ff', '#00f', '#f0f', '#f88', '#880', '#080', '#088', '#88f', '#808', '#000', '#555', '#aaa', '#fff']
		
		
	class UnsignedBlock extends Block
		# Positive integer entries only!
		constructor: (position, entries) -> super position, entries
		
		reduce_signed: (u0, u1, u2, u3) -> # arguments are unique positive integers
			# Return the 4 signed blocks that can simulate this unsigned one
			return [new SignedBlock([0, 0], [-u1, @entries[1], -@entries[2], u2]), new SignedBlock([1, 0], [@entries[0], -@entries[1], u1, -u0]),
					new SignedBlock([0, 1], [u3, -u2, @entries[2], -@entries[3]]), new SignedBlock([1, 1], [-@entries[0], u0, -u3, @entries[3]])]
					
		# SVG
		@Tile = SVG.invent(
			create: 'g'
			inherit: SVG.G
			extend:
				constructor_: (entries) ->
					@block_tile(entries)
					for i in [0...4]
						num = entries[i]
						digits = Math.floor(Math.log2(num) / 4) + 2 # include initial 0 to prevent digit-splitting cheats like fe -> ffee
						for d in [0...digits]
							height = 0.25 * (2 * digits - 1 - 2 * d) / (2 * digits - 1)
							@polygon([[0.5, -height], [0.25, -height], [0.25, height], [0.5, height]]).fill(Block.STRIP_COLORS[num %% 0x10]).rotate -90 * i, 0, 0
							num //= 0x10
					return this
					
			construct:
				ublock_tile: (entries) -> @put(new UnsignedBlock.Tile).constructor_ entries
		)
		
		
	class SignedBlock extends Block
		# Positive and negative integer entries only!
		constructor: (position, entries) -> super position, entries
		
		reduce_jigsaw: (size) -> 
			edge_to_polyomino = (num) -> # Encodes a number edge into a jigsaw edge
				pos_num = Math.abs num
				entries = []
				i = 2
				while pos_num > 0
					if pos_num %% 2 != 0
						entries.push [i, 0]
					pos_num //= 2
					i += 1
				
				poly = new Polyomino [0, 0], entries
				if num > 0
					poly.rotate_around Piece.CCW_180, size / 2, 0
				return poly
				
			return new Jigsaw [0, 0], (edge_to_polyomino(num) for num in @entries)
		
		
	class Jigsaw extends Block
		# Entries are polyominos XOR'd with a block
		constructor: (position, entries) -> super position, entries
		
		reduce_polyomino: (size) ->
			square = Polyomino.square size
			for [entry, rotation] in _.zip @entries, [Piece.CCW_270, Piece.CCW_0, Piece.CCW_90, Piece.CCW_180]
				console.dir [entry, rotation]
				poly = entry.copy()
				poly.rotate_around rotation, size / 2, size / 2
				square.this_xor poly
			return square
		
		
	class Polyomino extends Piece
		# Stores entries as a list of offset positions
		constructor: (position, @entries) ->
			# Can take `entries` as an array or set of points
			super position
			unless @entries instanceof Set
				@entries = new Set @entries
				
		copy: (other) ->
			return new Polyomino @position[..], new Set @entries
		
		@square: (size) ->
			entries = _.flatten (([x, y] for x in [0...size]) for y in [0...size]), true
			return new Polyomino [0, 0], entries
			
		this_xor: (other) -> # XORs and modifies this polyomino with `other`, used for reducing jigsaw pieces to polyominos
			# Doesn't care about position
			@entries = @entries.xor other.entries
		
		shift_offset: (x, y) -> # shifts the offsets of the blocks instead of the overall position
			@entries.forEach (entry) ->
				entry[0] += x
				entry[1] += y
			@entries.rebuild()
				
		rotate_offset: (amount) -> # rotates offsets counterclockwise around the origin, amount is Piece.CCW_xx
			@entries = switch amount
				when Piece.CCW_90  then new Set @entries.map (entry) -> [entry[1], -entry[0] - 1]
				when Piece.CCW_180 then new Set @entries.map (entry) -> [-entry[0] - 1, -entry[1] - 1]
				when Piece.CCW_270 then new Set @entries.map (entry) -> [-entry[1] - 1, entry[0]]
				else @entries
				
		rotate_around: (amount, x, y) ->
			@shift_offset -x, -y
			@rotate_offset amount
			@shift_offset x, y
		
		reoffset: ->
			# Re-offset to origin
			[min_x, min_y] = [@entries.min((a, b) -> (a[0] - b[0]))[0], @entries.min((a, b) -> (a[1] - b[1]))[1]]
			@entries.forEach (entry) ->
				entry[0] -= min_x
				entry[1] -= min_y
			@entries.rebuild()
		
		rotate: (amount) ->
			@rotate_offset amount
			@reoffset()
		
		neighbors: (point) -> # returns the neighbors of a point in right, up, left, down order
			return  [
						if @entries.contains [point[0] + 1, point[1]] then [point[0] + 1, point[1]] else null
						if @entries.contains [point[0], point[1] - 1] then [point[0], point[1] - 1] else null
						if @entries.contains [point[0] - 1, point[1]] then [point[0] - 1, point[1]] else null
						if @entries.contains [point[0], point[1] + 1] then [point[0], point[1] + 1] else null
					]
		
		reduce_unsigned: (common, ustart) -> # common: common number to use for edge, ustart: start of unique numbers
			block_map = new Hash _.flatten (@entries.map (entry) -> [entry, (undefined for i in [0...4])]), true
			@entries.forEach (entry) =>
				for nb, i in poly.neighbors entry
					if nb? and @entries.contains nb
						unless block_map.get(entry)[i]?
							block_map.get(entry)[i] = ustart # edges inside jigsaw get unique color that acts like glue
							block_map.get(nb)[(i + 2) % 4] = ustart
							ustart += 1
					else
						block_map.get(entry)[i] = common # edges of jigsaw get color common to all edges
			
			return block_map.map (pair) -> new UnsignedBlock pair.key[..], pair.value
		
	
	class Puzzle
		constructor: (@width, @height) ->
		
		from_3_partition: (nums) -> 
		init_render: (draw) -> # Renders the puzzle
		
		
	class EdgeMatch extends Puzzle
		constructor: (width, height, @pieces) -> super width, height # Expects a row-major array of pieces
		
		get_piece: (x, y) -> return @pieces[y * @width + x]
		set_piece: (x, y, piece) -> @pieces[y * @width + x] = piece
		
		swap_pieces: (x1, y1, x2, y2) -> #Assumes that the piece at x1, y1 is invading the spot x2, y2
			piece1 = @get_piece x1, y1
			piece2 = @get_piece x2, y2
			piece1.position = [x2, y2]
			piece2?.position = [x1, y1]
			piece2?.svg?.animate(400, '>').x(x1 + 0.5).y(y1 + 0.5)
			@set_piece x1, y1, piece2
			@set_piece x2, y2, piece1
		
	
	class UnsignedEdgeMatch extends EdgeMatch
		constructor: (width, height, pieces) -> super width, height, pieces
		
		@from_3_partition: (nums) -> 
			target_sum = target_sum_3_partition nums
			width = target_sum + 2
			height = nums.length / 3 + 2
			uem = new UnsignedEdgeMatch width, height, ((new UnsignedBlock [0, 0], (undefined for i in [0...4])) for i in [0...width * height])
			
			# Update positions
			for y in [0...height]
				for x in [0...width]
					uem.get_piece(x, y).position = [x, y]
					
			unique = 1
			# Give the frame unique colors
			for x in [0...width]
				uem.get_piece(x, 0).entries[Block.TOP] = unique
				uem.get_piece(x, height - 1).entries[Block.BOTTOM] = unique + 1
				unique += 2
			for y in [0...height]
				uem.get_piece(0, y).entries[Block.LEFT] = unique
				uem.get_piece(width - 1, y).entries[Block.RIGHT] = unique + 1
				unique += 2
				
			# Give the frame-inside matching unique colors
			for x in [0...width - 1]
				uem.get_piece(x, 0).entries[Block.RIGHT] = unique
				uem.get_piece(x + 1, 0).entries[Block.LEFT] = unique
				uem.get_piece(x, height - 1).entries[Block.RIGHT] = unique + 1
				uem.get_piece(x + 1, height - 1).entries[Block.LEFT] = unique + 1
				unique += 2
			for y in [0...height - 1]
				uem.get_piece(0, y).entries[Block.BOTTOM] = unique
				uem.get_piece(0, y + 1).entries[Block.TOP] = unique
				uem.get_piece(width - 1, y).entries[Block.BOTTOM] = unique + 1
				uem.get_piece(width - 1, y + 1).entries[Block.TOP] = unique + 1
				unique += 2
				
			common_horz = unique
			common_vert = unique + 1
			unique += 2
			# Give the inner frame the "glue" color
			for x in [1...width - 1]
				uem.get_piece(x, 0).entries[Block.BOTTOM] = common_vert
				uem.get_piece(x, height - 1).entries[Block.TOP] = common_vert
			for y in [1...height - 1]
				uem.get_piece(0, y).entries[Block.RIGHT] = common_horz
				uem.get_piece(width - 1, y).entries[Block.LEFT] = common_horz
				
			
			# Now for the filling in the pie: all the a_i gadgets
			index = 0
			for num in nums
				for i in [0...num]
					piece = uem.get_piece index %% (width - 2) + 1, index // (width - 2) + 1
					piece.entries[Block.TOP] = common_vert
					piece.entries[Block.BOTTOM] = common_vert
					piece.entries[Block.LEFT] = if i == 0 then common_horz else unique
					if i != 0
						unique += 1
					piece.entries[Block.RIGHT] = if i == num - 1 then common_horz else unique
					index += 1
			
			return uem
			
		init_render: (draw) ->
			for x in [0..@width] # note: 2 dots
				draw.line(x, 0, x, @height).stroke({color: '#000', width: 1/16})
			for y in [0..@height]
				draw.line(0, y, @width, y).stroke({color: '#000', width: 1/16})
				
			for y in [0...@height]
				for x in [0...@width]
					piece = @get_piece(x, y)
					if piece?
						tile = draw.ublock_tile(@get_piece(x, y).entries).move x + 0.5, y + 0.5
						tile.draggable(
							minX: 0.5
							maxX: @width + 0.5
							minY: 0.5
							maxY: @height + 0.5
						)
						.on('beforedrag', Block.tile_before_drag)
						.on('dragmove', Block.tile_drag_move)
						.on('dragend', Block.tile_drag_end)
						
						tile.puzzle = this
						tile.piece = piece
						piece.svg = tile
					
	
	class SignedEdgeMatch extends EdgeMatch
		constructor: (width, height, pieces) -> super width, height, pieces
		
		
	class JigsawPuzzle extends EdgeMatch
		constructor: (width, height, pieces) -> super width, height, pieces
		
		
	class PolyominoPack extends Puzzle
		constructor: (width, height, @pieces) -> super width, height # Expects an array of pieces
		
	
	draw = SVG drawing
	render = ->
		uem = UnsignedEdgeMatch.from_3_partition [1, 5, 3, 12, 8, 19, 7, 4, 13, 4, 2, 10]
		
		draw.clear()
		draw.size uem.width * 64, uem.height * 64
		draw.viewbox 0, 0, uem.width, uem.height
		
		uem.init_render draw

	#sb = new SignedBlock [0, 0], [1, 3, -6, -7]
	#jig = sb.reduce_jigsaw 7
	#poly = jig.reduce_polyomino 7
	
	
	#str_ = ''
	#for num in block.entries
	#	str_ += "#{num.toString()} "
	#document.getElementById('result').innerHTML = "[#{str_}]"