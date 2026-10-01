extends SceneTree
func _initialize():
	var img = Image.load_from_file('res://assets/buildings-q.png')
	var cuts = [0.0,0.237,0.450,0.718,1.0]
	for row in range(2):
		for col in range(4):
			var r = Rect2i(int(img.get_width()*cuts[col]),int(img.get_height()*row/2.0),int(img.get_width()*cuts[col+1])-int(img.get_width()*cuts[col]),int(img.get_height()/2.0))
			var piece = img.get_region(r)
			var lo = Vector2i(piece.get_width(),piece.get_height())
			var hi = Vector2i.ZERO
			for y in range(piece.get_height()):
				for x in range(piece.get_width()):
					if piece.get_pixel(x,y).a > 0.5:
						lo = Vector2i(mini(lo.x,x),mini(lo.y,y))
						hi = Vector2i(maxi(hi.x,x),maxi(hi.y,y))
			print(row,'/',col,' used=',piece.get_used_rect(),' opaque=',Rect2i(lo,hi-lo+Vector2i.ONE))
	quit()
