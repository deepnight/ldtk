package tool;

class PickPoint extends Tool<{ x:Int, y:Int }> {
	public var pickOrigin : Null<{ cx:Int, cy:Int, color:UInt }>;

	public function new() {
		super();
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);

		if( pickOrigin!=null ) {
			var grid = curLayerInstance.def.gridSize;
			editor.cursor.set( Link(
				curLayerInstance.pxTotalOffsetX + (pickOrigin.cx+0.5)*grid,
				curLayerInstance.pxTotalOffsetY + (pickOrigin.cy+0.5)*grid,
				curLayerInstance.pxTotalOffsetX + (m.cx+0.5)*grid,
				curLayerInstance.pxTotalOffsetY + (m.cy+0.5)*grid,
				pickOrigin.color
			));
		}
		else
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy) );

		ev.cancel = true;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);

		if( ev.button==1 )
			editor.clearSpecialTool();
		else if( ev.button==0 )
			curMode = Add;
	}

	override function stopUsing(m:Coords) {
		super.stopUsing(m);

		var li = editor.curLayerInstance;
		if( button==0 && m.cx>=0 && m.cx<li.cWid && m.cy>=0 && m.cy<li.cHei ) {
			editor.levelRender.bleepRectCase(m.cx,m.cy, 1,1, 0xffcc00);
			onPick(m);
		}
	}

	public dynamic function onPick(m:Coords) {}
}