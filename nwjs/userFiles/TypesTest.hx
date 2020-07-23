enum Mixed {
	Foo;
	Bar(s:String);
	Pouet;
	Some(n:Int);
}

enum CommentTest{
	None; // multi // comment
	Foo; // multi // comment  / rezoizeo
	Move; Test; // Pouet;
	//Bar;
	Eraser(x:Int,y:Int);/*
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:led.def.EntityDef, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
	Resize(p:RulerPos);*/
	End;
}

enum OnlyParams {
	IntGrid(li:led.inst.LayerInstance, cx:Int, cy:Int);
	Entity(instance:led.inst.EntityInstance);
	Tile(li:led.inst.LayerInstance, cx:Int, cy:Int);
}

enum GoodBoy {
	PanView;
	Add;
	Remove;
	Move;
}
