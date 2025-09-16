extends Node2D
@export var tilemap: TileMapLayer
@export var player: CharacterBody2D
@export var inimigo0: CharacterBody2D
@export var inimigo1: CharacterBody2D
@export var inimigo2: CharacterBody2D

const alturaDungeon = 80
const larguraDungeon = 80

enum TileType { VAZIO, CHAO, PAREDE }

var dungeon_grid = []

func _ready() -> void:
	create_dungeon()

func generate():
	dungeon_grid = []
	
	for y in larguraDungeon:
		dungeon_grid.append( [] )
		for x in alturaDungeon:
			dungeon_grid[y].append( TileType.VAZIO )
	
	var rooms : Array[Rect2] = []
	var tentativasMaximas = 100
	var tentativas = 0
	
	while rooms.size() < 10 and tentativas < tentativasMaximas:
		var w = randi_range(8, 16)
		var h = randi_range(8, 16)
		var x = randi_range(1, alturaDungeon - w - 1)
		var y = randi_range(1, larguraDungeon - h - 1)
		var room = Rect2(x, y, w, h)
		
		var overlaps = false
		for other in rooms:
			if room.grow(1).intersects(other):
				overlaps = true
				break
		
		if !overlaps:
			rooms.append(room)
			for iy in range(y, y + h):
				for ix in range(x, x + w):
					dungeon_grid[iy][ix] = TileType.CHAO
			if rooms.size() > 1:
				var prev = rooms[rooms.size() - 2].get_center()
				var curr = room.get_center()
				corredor(prev, curr)
					
		tentativas += 1
	
	return rooms

func render():
	tilemap.clear()
	
	for y in range(alturaDungeon):
		for x in range(larguraDungeon):
			var tile = dungeon_grid[y][x]
			
			match tile:
				TileType.CHAO: tilemap.set_cell(Vector2i(x, y), 0, Vector2i(8, 1))
				TileType.PAREDE: tilemap.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

func corredor(from: Vector2, to: Vector2, largura: int = 2):
	var largura_minima = -largura / 2
	var largura_maxima = largura / 2
	
	if randf() < 0.5:
		for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
			for offset in range(largura_minima, largura_maxima + 1):
				var y = from.y + offset
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.CHAO
		for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
			for offset in range(largura_minima, largura_maxima + 1):
				var x = to.x + offset
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.CHAO
	else:
		for y in range(min(from.y, to.y), max(from.y, to.y) + 1):
			for offset in range(largura_minima, largura_maxima + 1):
				var x = from.x + offset
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.CHAO
		
		for x in range(min(from.x, to.x), max(from.x, to.x) + 1):
			for offset in range(largura_minima, largura_maxima + 1):
				var y = to.y + offset
				if is_in_bounds(x, y):
					dungeon_grid[y][x] = TileType.CHAO
					
	
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < larguraDungeon and y < alturaDungeon

func add_paredes():
	for y in range(alturaDungeon):
		for x in range(larguraDungeon):
			if dungeon_grid[y][x] == TileType.CHAO:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and ny >= 0 and nx < larguraDungeon and ny < alturaDungeon:
							if dungeon_grid[ny][nx] == TileType.VAZIO:
								dungeon_grid[ny][nx] = TileType.PAREDE

func place_player(rooms: Array[Rect2]):
	player.position = rooms.pick_random().get_center() * 16

func place_inimigo(rooms: Array[Rect2]):
	inimigo0.position = rooms.pick_random().get_center() * 16
	inimigo1.position = rooms.pick_random().get_center() * 16
	inimigo2.position = rooms.pick_random().get_center() * 16
	
func create_dungeon():
	var sala = generate()
	place_player(sala)
	place_inimigo(sala)
	add_paredes()
	render()
	
