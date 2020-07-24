enum MixedWithParameters { // parametered enums can't be imported
	Foo;
	Bar(s:String);
	Pouet;
	Some(n:Int);
}

enum AnImportedEnum {
	Value1;
	Value2;
	//DiscardedValue1;
	Value3; Value4; // 2 on the same line
	/*
	DiscardedValue2;
	DiscardedValue3;
	*/
	Value5;
}

enum ItemType {
	Food;
	Gold;
	Ammo;
	Key;
}

enum EnemyType {
	Crawler;
	Shooter;
	Behemoth;
	Hunter;
}



