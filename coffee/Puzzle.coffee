class Piece
	# Basic piece of a puzzle
	constructor: (@position) -> # [x, y]
	
	rotate: ->

	
class Block extends Piece
	# Stores entries in east, north, west, south order
	constructor: (position, @entries) -> super position 
	
	rotate: -> @entries.unshift @entries.pop()
	
	
class UnsignedBlock extends Block
    # Positive integer entries only!
	constructor: (position, entries) -> super position, entries
	
	reduce_signed: (u0, u1, u2, u3) ->
	    # Return the 4 signed blocks that can simulate this unsigned one
		return [new SignedBlock([0, 0], [u1, @entries[1], -@entries[2], -u2]), new SignedBlock([1, 0], [-u3, u2, @entries[2], -@entries[3]]),
				new SignedBlock([0, 1], [-@entries[0], -u0, u3, @entries[3]]), new SignedBlock([1, 1], [@entries[0], -@entries[1], -u1, u0])]
	
	
class SignedBlock extends Block
	# Positive and negative integer entries only!
	constructor: (position, entries) -> super position, entries
	
	
class Polyomino extends Piece
	# Stores entries as a list of offset positions
	constructor: (position, @entries) -> super position
	
	rotate ->
		for entry, i in entries
			entries[i] = [entry[1], -entry[0]]
		[min_x, min_y] = [Math.min(entry[0] for entry in entries), Math.min(entry[1] for entry in entries)]
		for entry in entries
			entry[0] -= min_x
			entry[1] -= min_y
	

block = new Block [0, 0], [1, 2, 3, 4]
block.rotate()

console.log ...block.position
str_ = ''
for num in block.entries
	str_ += "#{num.toString()} "
document.getElementById('result').innerHTML = "[#{str_}]"