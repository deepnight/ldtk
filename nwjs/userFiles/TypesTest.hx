enum Mixed {
	Foo;
	Bar(s:String);
	Pouet;
	Some(n:Int);
}

enum CommentTest {
	Value1; // multi // comment
	Value2; // multi // comment  / rezoizeo
	Value3; Value4; // Pouet;
	//Bar;
	/*
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:led.def.EntityDef, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
	Resize(p:RulerPos);*/
	Value5;
}

enum OnlyParams {
	IntGrid(li:led.inst.LayerInstance, cx:Int, cy:Int);
	Entity(instance:led.inst.EntityInstance);
	Tile(li:led.inst.LayerInstance, cx:Int, cy:Int);
}

enum ItemType {
	Food;
	Gold;
	Ammo;
	Key;
}

enum MobType {
	Crawler;
	Shooter;
	Behemoth;
	Hunter;
}
