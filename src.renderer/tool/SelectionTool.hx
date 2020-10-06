package tool;

class SelectionTool extends Tool< Array<GenericLevelElement> > {
	var selectionCursor : ui.Cursor;
	var moveStarted = false;

	public function new() {
		super();

		selectionCursor = new ui.Cursor();
		selectionCursor.set(None);
		selectionCursor.enablePermanentHighlights();
	}

	override function getDefaultValue():Array<GenericLevelElement> {
		return [];
	}

	override function getSelectionMemoryKey():Null<String> {
		return "selection";
	}


	override function selectValue(v:Array<GenericLevelElement>) {
		super.selectValue(v);

		trace(v);

		if( isEmpty() )
			selectionCursor.set(None);
		else
			selectionCursor.set(switch getSelectedValue()[0] {
				case IntGrid(li, cx, cy): GridCell(li, cx,cy);
				case Entity(li, ei): Entity(li, ei.def, ei, ei.x, ei.y);
				case Tile(li,cx,cy): Tiles(li, [li.getGridTile(cx,cy)], cx,cy);
				case PointField(li, ei, fi, arrayIdx):
					var pt = fi.getPointGrid(arrayIdx);
					GridCell(li, pt.cx, pt.cy);
			});

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

		moveStarted = false;

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
	public inline function isEmpty() return getSelectedValue().length==0;
	public inline function isSingle() return getSelectedValue().length==1;

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);
		N.debug("select: STOP");
	}




function duplicateSelection() : Null< Array<GenericLevelElement> > {
	switch getSelectedValue()[0] { // TODO support groups
		case IntGrid(li, cx, cy):
			return null;

		case Entity(li, instance):
			var ei = li.duplicateEntityInstance( instance );
			return [ GenericLevelElement.Entity(li, ei) ];

		case Tile(li, cx, cy):
			return null; // TODO support copy?

		case PointField(li, ei, fi, arrayIdx):
			return null; // TODO support copy?
	}
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);

		// Start moving elements only after a small elapsed mouse distance
		if( isRunning() && !moveStarted && M.dist(origin.pageX, origin.pageY, m.pageX, m.pageY) >= 10*Const.SCALE ) {
			moveStarted = true;
			if( App.ME.isCtrlDown() && any() ) {
				var copy = duplicateSelection();
				N.success("copy: "+copy);
				if( copy!=null )
					selectValue(copy);
			}
		}

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


	public function getSelectedEntityInstance() : Null<led.inst.EntityInstance> {
		if( isEmpty() )
			return null;

		switch getSelectedValue()[0] {
			case null, IntGrid(_), Tile(_):
				return null;

			case PointField(li, ei, fi, arrayIdx):
				return ei;

			case Entity(curLayerInstance, instance):
				return instance;
		}
	}


	override function onHistorySaving() {
		super.onHistorySaving();

		var ei = getSelectedEntityInstance();
		if( ei!=null )
			editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
	}


	override function useAt(m:MouseCoords):Bool {
		if( any() && moveStarted ) {
			switch getSelectedValue()[0] {
				case Entity(li, instance):
					var ei = getSelectedEntityInstance();
					var oldX = ei.x;
					var oldY = ei.y;
					ei.x = snapToGrid()
						? M.round( ( m.cx + ei.def.pivotX ) * curLayerInstance.def.gridSize )
						: m.levelX;
					ei.y = snapToGrid()
						? M.round( ( m.cy + ei.def.pivotY ) * curLayerInstance.def.gridSize )
						: m.levelY;
					var changed = oldX!=ei.x || oldY!=ei.y;
					if( changed ) {
						editor.selectionTool.selectValue([ Entity(curLayerInstance, ei) ]);
						editor.ge.emit( EntityInstanceChanged(ei) );
					}

					return changed;

				case PointField(li, ei, fi, arrayIdx):
					var old = fi.getPointStr(arrayIdx);
					fi.parseValue(arrayIdx, m.cx+Const.POINT_SEPARATOR+m.cy);

					var changed = old!=fi.getPointStr(arrayIdx);
					if( changed ) {
						editor.selectionTool.selectValue([ PointField(li,ei,fi,arrayIdx) ]);
						editor.ge.emit( EntityInstanceChanged(ei) );
					}
					return changed;

				case _:
			}
		}
		return super.useAt(m);
	}

	override function update() {
		super.update();
		// App.ME.debug("selection = "+getSelectedValue());
	}
}