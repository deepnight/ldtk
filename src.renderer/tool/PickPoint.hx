package tool;

class PickPoint extends Tool<{ x:Int, y:Int }> {
	public var pickOrigin : Null<{ cx:Int, cy:Int, color:UInt }>;

	public function new() {
		super();
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
		if( pickOrigin!=null ) {
			var grid = curLayerInstance.def.gridSize;
			editor.cursor.set( Link(
				(pickOrigin.cx+0.5)*grid, (pickOrigin.cy+0.5)*grid,
				(m.cx+0.5)*grid, (m.cy+0.5)*grid,
				pickOrigin.color
			));
		}
		else
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy) );
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		if( buttonId==1 )
			editor.clearSpecialTool();
		else if( buttonId==0 )
			curMode = Add;
	}

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);

		if( button==0 ) {
			editor.levelRender.bleepRectCase(m.cx,m.cy, 1,1, 0xffcc00);
			onPick(m);
		}
	}

	public dynamic function onPick(m:MouseCoords) {}
}