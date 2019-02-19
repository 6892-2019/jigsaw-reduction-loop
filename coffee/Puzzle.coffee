render_3_partition = undefined
reduce = undefined
set_size = undefined

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
				@inner.rotate Math.round (@inner.transform().rotation - 90) % 360
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
					colors = ['#000', '#555', '#aaa', '#fff']
					for i in [0...4]
						@polygon([[0.5, -0.5], [0.25, -0.25], [0.25, 0.25], [0.5, 0.5]]).fill(colors[entries[i] %% colors.length]).rotate -90 * i, 0, 0
					for i in [0...4]
						num = entries[i]
						digits = Math.floor(Math.max(0, Math.log2(num)) / 4) + 2 # include initial 0 to prevent digit-splitting cheats like fe -> ffee
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
			
		# SVG
		@Tile = SVG.invent(
			create: 'g'
			inherit: SVG.G
			extend:
				constructor_: (entries) ->
					@block_tile(entries)
					colors = ['#000', '#222', '#444', '#666', '#999', '#bbb', '#ddd', '#fff']
					for i in [0...4]
						@polygon([[0.5, -0.5], [0.25, -0.25], [0.25, 0], [0.5, 0]]).fill(colors[Math.abs(entries[i]) %% (colors.length / 2) + (entries[i] < 0) * (colors.length / 2)]).rotate -90 * i, 0, 0
						@polygon([[0.5,  0.5], [0.25,  0.25], [0.25, 0], [0.5, 0]]).fill(colors[Math.abs(entries[i]) %% (colors.length / 2) + (entries[i] > 0) * (colors.length / 2)]).rotate -90 * i, 0, 0
					for i in [0...4]
						abs = Math.abs entries[i]
						digits = Math.floor(Math.max(0, Math.log2(abs)) / 4) + 2 # include initial 0 to prevent digit-splitting cheats like fe -> ffee
						for d in [0...digits]
							height = 0.25 - 0.5 * (2 * digits - 1 - 2 * d) / (2 * digits - 1)
							polygon =
								if entries[i] >= 0
									@polygon([[0.5, height], [0.25, height], [0.25, 0.25], [0.5, 0.25]])
								else
									@polygon([[0.5, -height], [0.25, -height], [0.25, -0.25], [0.5, -0.25]])
							polygon.fill(Block.STRIP_COLORS[abs %% 0x10]).rotate(-90 * i, 0, 0)
							abs //= 0x10
					return this
					
			construct:
				sblock_tile: (entries) -> @put(new SignedBlock.Tile).constructor_ entries
		)
		
		
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
			
		# SVG
		@Tile = SVG.invent(
			create: 'g'
			inherit: SVG.G
			extend:
				constructor_: (poly) ->
					@block_tile(entries)
					poly.entries.forEach (entry) ->
						@rect(1, 1).fill('#0ff').move entry[0] + 0.5, entry[1] + 0.5
					return this
					
			construct:
				polyomino_tile: (entries) -> @put(new Polyomino.Tile).constructor_ poly
		)
		
	
	class Puzzle
		constructor: (@width, @height) ->
		
		from_3_partition: (nums) -> 
		init_render: (draw) -> # Renders the puzzle
		
		reduce: ->
		
		
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
			
		init_render: (draw, element_func) ->
			for x in [0..@width] # note: 2 dots
				draw.line(x, 0, x, @height).stroke({color: '#000', width: 1/16})
			for y in [0..@height]
				draw.line(0, y, @width, y).stroke({color: '#000', width: 1/16})
				
			for y in [0...@height]
				for x in [0...@width]
					piece = @get_piece(x, y)
					if piece?
						tile = draw.group() # Make a group buffer because otherwise svg.draggable assumes that rotations need to be respected
						tile.inner = element_func.call tile, @get_piece(x, y).entries
						tile.move x + 0.5, y + 0.5
						if x > 0 and x < @width - 1 and y > 0 and y < height - 1
							tile.draggable(
								minX: 1.5
								maxX: @width - 0.5
								minY: 1.5
								maxY: @height - 0.5
							)
							.on('beforedrag', Block.tile_before_drag)
							.on('dragmove', Block.tile_drag_move)
							.on('dragend', Block.tile_drag_end)
						
						tile.puzzle = this
						tile.piece = piece
						piece.svg = tile
		
	
	class UnsignedEdgeMatch extends EdgeMatch
		constructor: (width, height, pieces) ->
			unless pieces
				pieces = ((new UnsignedBlock [i %% width, i // width], (undefined for i in [0...4])) for i in [0...width * height])
			super width, height, pieces
			
		@puzzle_name = 'Unsigned Edge Matching with Frame'
		@reduce_to = -> SignedEdgeMatch
		
		reduce: ->
			sem = new SignedEdgeMatch 2 * @width - 2, 2 * @height - 2
			
			# Corners
			sem.get_piece(0, 0).entries = @get_piece(0, 0).entries[..]
			sem.get_piece(sem.width - 1, 0).entries = @get_piece(@width - 1, 0).entries[..]
			sem.get_piece(0, sem.height - 1).entries = @get_piece(0, @height - 1).entries[..]
			sem.get_piece(sem.width - 1, sem.height - 1).entries = @get_piece(@width - 1, @height - 1).entries[..]
			
			# Edges
			for x in [1...@width - 1]
				sem.get_piece(2 * x, 0).entries = @get_piece(x, 0).entries[..]
				(sem.get_piece(2 * x - 1, 0).entries = @get_piece(x, 0).entries[..])[Block.BOTTOM] *= -1
				sem.get_piece(2 * x - 1, sem.height - 1).entries = @get_piece(x, @height - 1).entries[..]
				(sem.get_piece(2 * x, sem.height - 1).entries = @get_piece(x, @height - 1).entries[..])[Block.TOP] *= -1
				
			for y in [1...@height - 1]
				sem.get_piece(0, 2 * y - 1).entries = @get_piece(0, y).entries[..]
				(sem.get_piece(0, 2 * y).entries = @get_piece(0, y).entries[..])[Block.RIGHT] *= -1
				sem.get_piece(sem.width - 1, 2 * y).entries = @get_piece(@width - 1, y).entries[..]
				(sem.get_piece(sem.width - 1, 2 * y - 1).entries = @get_piece(@width - 1, y).entries[..])[Block.LEFT] *= -1
			
			unique = 1 + Math.max ...(Math.max(...piece.entries) for piece in @pieces when piece?)
			for y in [1...@height - 1]
				for x in [1...@width - 1]
					if @get_piece(x, y)?
						for sblock in @get_piece(x, y).reduce_signed unique, unique + 1, unique + 2, unique + 3
							sem.get_piece(2 * x - 1 + sblock.position[0], 2 * y - 1 + sblock.position[1]).entries = sblock.entries
						unique += 4
			
			return [sem, 2]
		
		@from_3_partition: (nums) -> 
			target_sum = target_sum_3_partition nums
			width = target_sum + 2
			height = nums.length / 3 + 2
			uem = new UnsignedEdgeMatch width, height
			
			# Update positions
			for y in [0...height]
				for x in [0...width]
					uem.get_piece(x, y).position = [x, y]
					
			# Frame outside
			for x in [0...width]
				uem.get_piece(x, 0).entries[Block.TOP] = 0
				uem.get_piece(x, height - 1).entries[Block.BOTTOM] = 0
			for y in [0...height]
				uem.get_piece(0, y).entries[Block.LEFT] = 0
				uem.get_piece(width - 1, y).entries[Block.RIGHT] = 0
				
			# Frame inside
			for x in [0...width - 1]
				uem.get_piece(x, 0).entries[Block.RIGHT] = 0
				uem.get_piece(x + 1, 0).entries[Block.LEFT] = 0
				uem.get_piece(x, height - 1).entries[Block.RIGHT] = 0
				uem.get_piece(x + 1, height - 1).entries[Block.LEFT] = 0
			for y in [0...height - 1]
				uem.get_piece(0, y).entries[Block.BOTTOM] = 0
				uem.get_piece(0, y + 1).entries[Block.TOP] = 0
				uem.get_piece(width - 1, y).entries[Block.BOTTOM] = 0
				uem.get_piece(width - 1, y + 1).entries[Block.TOP] = 0
				
			common_horz = 1
			common_vert = 2
			unique = 3
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
			super.init_render draw, draw.ublock_tile
					
	
	class SignedEdgeMatch extends EdgeMatch
		constructor: (width, height, pieces) ->
			unless pieces
				pieces = ((new SignedBlock [i %% width, i // width], (undefined for i in [0...4])) for i in [0...width * height])
			super width, height, pieces
			
		@puzzle_name = 'Signed Edge Matching with Frame'
		@reduce_to = -> JigsawPuzzle
		
		@from_3_partition: (nums) -> 
			target_sum = target_sum_3_partition nums
			width = target_sum + 2
			height = nums.length / 3 + 2
			sem = new SignedEdgeMatch width, height
					
			# Give the frame the same color, since a piece of the opposite color would be needed for a match
			for x in [0...width]
				sem.get_piece(x, 0).entries[Block.TOP] = 0
				sem.get_piece(x, height - 1).entries[Block.BOTTOM] = 0
			for y in [0...height]
				sem.get_piece(0, y).entries[Block.LEFT] = 0
				sem.get_piece(width - 1, y).entries[Block.RIGHT] = 0
				
			# Frame inside
			for x in [0...width - 1]
				sem.get_piece(x, 0).entries[Block.RIGHT] = 0
				sem.get_piece(x + 1, 0).entries[Block.LEFT] = 0
				sem.get_piece(x, height - 1).entries[Block.RIGHT] = 0
				sem.get_piece(x + 1, height - 1).entries[Block.LEFT] = 0
			for y in [0...height - 1]
				sem.get_piece(0, y).entries[Block.BOTTOM] = 0
				sem.get_piece(0, y + 1).entries[Block.TOP] = 0
				sem.get_piece(width - 1, y).entries[Block.BOTTOM] = 0
				sem.get_piece(width - 1, y + 1).entries[Block.TOP] = 0
				
			common_horz = 1
			common_vert = 2
			unique = 3
			# Give the inner frame the "glue" color
			for x in [1...width - 1]
				sem.get_piece(x, 0).entries[Block.BOTTOM] = common_vert
				sem.get_piece(x, height - 1).entries[Block.TOP] = -common_vert
			for y in [1...height - 1]
				sem.get_piece(0, y).entries[Block.RIGHT] = common_horz
				sem.get_piece(width - 1, y).entries[Block.LEFT] = -common_horz
				
			
			# Now for the filling in the pie: all the a_i gadgets
			index = 0
			for num in nums
				for i in [0...num]
					piece = sem.get_piece index %% (width - 2) + 1, index // (width - 2) + 1
					piece.entries[Block.TOP] = -common_vert
					piece.entries[Block.BOTTOM] = common_vert
					piece.entries[Block.LEFT] = if i == 0 then -common_horz else -unique
					if i != 0
						unique += 1
					piece.entries[Block.RIGHT] = if i == num - 1 then common_horz else unique
					index += 1
			
			return sem
		
		init_render: (draw) ->
			super.init_render draw, draw.sblock_tile
		
		
	class JigsawPuzzle extends EdgeMatch
		constructor: (width, height, pieces) -> super width, height, pieces
		@puzzle_name = 'Jigsaw Puzzle'
		@reduce_to = -> PolyominoPack
		
		
	class PolyominoPack extends Puzzle
		constructor: (width, height, @pieces) -> super width, height # Expects an array of pieces
		@puzzle_name = 'Polyomino Packing'
		@reduce_to = -> UnsignedEdgeMatch
		
	
	draw = SVG drawing
	puzzle_type = UnsignedEdgeMatch
	size = 64
	width = 0
	height = 0
	puzzle = null
	
	set_puzzle_text = ->
		document.getElementById('puzzle_type').innerHTML = puzzle_type.puzzle_name
		document.getElementById('reduce_text').value = "Reduce to #{puzzle_type.reduce_to().puzzle_name}"
		
	set_size_text = -> document.getElementById('size').value = size.toString()
	
	set_puzzle_text()
	set_size_text()	
			
	render_3_partition = ->
		str = document.getElementById('3_partition').value
		bad_3_partition = document.getElementById('bad_3_partition')
		bad_3_partition.innerHTML = ''
		
		strs = _.filter str.split(' '), (str) -> str != '' # JavaScript for some reason keeps the empty strings
		if strs.length == 0
			bad_3_partition.innerHTML = "Congrats. Because you didn't enter any numbers, you just divided by 0. Catastrophe incoming..."
			return
		if strs.length % 3 != 0
			bad_3_partition.innerHTML = "The number of numbers must be divisible by 3."
			return
			
		nums = []
		for str in strs
			num = parseFloat str
			if num < 1 or not Number.isInteger(num)
				bad_3_partition.innerHTML = "#{str} is not a positive integer."
				return
			nums.push num
			
		unless Number.isInteger target_sum_3_partition nums
			bad_3_partition.innerHTML = "The sum of the numbers must be divisible by the number of numbers divided by 3."
			return
		puzzle = puzzle_type.from_3_partition nums
		render()
	
	
	render = ->
		draw.clear()
		[width, height] = [puzzle.width, puzzle.height]
		draw.size width * size, height * size
		draw.viewbox 0, 0, width, height
		
		puzzle.init_render draw

	
	reduce = ->
		puzzle_type = puzzle_type.reduce_to()
		set_puzzle_text()
		
		if puzzle?
			[puzzle, blowup] = puzzle.reduce()
			size /= blowup;
			document.getElementById('size').value = size.toString()
			render()
		
		
	set_size = ->
		bad_size = document.getElementById('bad_size')
		bad_size.innerHTML = ''
		
		num = parseFloat document.getElementById('size').value
		if not Number.isFinite(num) or num <= 0
			bad_size.innerHTML = 'Size must be positive.'
			return
			
		size = num
		set_size_text()
		draw.size width * size, height * size
		
	#sb = new SignedBlock [0, 0], [1, 3, -6, -7]
	#jig = sb.reduce_jigsaw 7
	#poly = jig.reduce_polyomino 7
	
	
	#str_ = ''
	#for num in block.entries
	#	str_ += "#{num.toString()} "
	#document.getElementById('result').innerHTML = "[#{str_}]"
	
	#test example: [1, 5, 3, 12, 8, 19, 7, 4, 13, 4, 2, 10]