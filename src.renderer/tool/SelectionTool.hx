package tool;

class SelectionTool extends Tool< Array<GenericLevelElement> > {
	var selectionCursor : ui.Cursor;

	public function new() {
		super();

		selectionCursor = new ui.Cursor();
		selectionCursor.enablePermanentHighlights();
	}

	override function getDefaultValue():Array<GenericLevelElement> {
		return [];
	}


	override function selectValue(v:Array<GenericLevelElement>) {
		super.selectValue(v);

		// selectionCursor.set(switch selection {
		// 	case IntGrid(li, cx, cy): GridCell(li, cx,cy);
		// 	case Entity(li, ei): Entity(li, ei.def, ei, ei.x, ei.y);
		// 	case Tile(li,cx,cy): Tiles(li, [li.getGridTile(cx,cy)], cx,cy);
		// 	case PointField(li, ei, fi, arrayIdx):
		// 		var pt = fi.getPointGrid(arrayIdx);
		// 		GridCell(li, pt.cx, pt.cy);
		// });

		ui.EntityInstanceEditor.close();

		if( v.length==1 ) {
			switch v[0] {
			case null:
			case IntGrid(_):
			case Tile(_):

			case PointField(li, ei, fi, arrayIdx):
				new ui.EntityInstanceEditor(ei);

			case Entity(li, instance):
				new ui.EntityInstanceEditor(instance);
			}

		}
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		editor.cursor.set(None);
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		var ge = editor.getGenericLevelElementAt(m);
		if( ge!=null )
			selectValue([ge]);
		else
			selectValue([]);

		N.debug("select: START");
	}

	public inline function get() return getSelectedValue();
	public inline function clear() selectValue([]);
	public inline function any() return getSelectedValue().length>0;
	public inline function isSingle() return getSelectedValue().length==1;

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);
		N.debug("select: STOP");
	}



	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		// Preview picking
		if( !isRunning() ) {
			var ge = editor.getGenericLevelElementAt(m, App.ME.isShiftDown() ? null : curLayerInstance);
			switch ge {
			case null:
				editor.cursor.set(PickNothing);

			case IntGrid(li, cx, cy):
				var id = li.getIntGridIdentifierAt(cx,cy);
				editor.cursor.set(
					GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ),
					id==null ? "#"+li.getIntGrid(cx,cy) : id
				);

			case Entity(li, ei):
				editor.cursor.set(
					Entity(li, ei.def, ei, ei.x, ei.y),
					ei.def.identifier,
					true
				);

			case Tile(li, cx,cy):
				editor.cursor.set(
					Tiles(li, [li.getGridTile(cx,cy)], cx, cy),
					"Tile "+li.getGridTile(cx,cy)
				);

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				editor.cursor.set( GridCell(li, pt.cx, pt.cy, ei.getSmartColor(false)) );
			}

			if( ge!=null )
				editor.cursor.setSystemCursor(Button);
		}
	}

	override function useAt(m:MouseCoords):Bool {
		N.debug("using: "+m);
		return super.useAt(m);
	}

	override function update() {
		super.update();
		App.ME.debug("selection = "+getSelectedValue());
	}
}