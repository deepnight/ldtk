import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTION_MEMORY : Map<String, Dynamic> = new Map();

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : led.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : led.Level; inline function get_curLevel() return Editor.ME.curLevel;

	@:allow(ui.ToolPalette)
	var curLayerInstance(get,never) : led.inst.LayerInstance; inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	var jPalette(get,never) : J; inline function get_jPalette() return editor.jPalette;

	var clickingOutsideBounds = false;
	var curMode : Null<ToolEditMode> = null;
	var origin : MouseCoords;
	var lastMouse : Null<MouseCoords>;
	var button = -1;
	var rectangle = false;
	var startTime = 0.;
	var palette : ui.ToolPalette;

	private function new() {
		super(Editor.ME);
	}

	override function onDispose() {
		super.onDispose();
	}

	override function toString():String {
		return Type.getClassName(Type.getClass(this))
			+ "[" + ( curMode==null ? "--" : curMode.getName() ) + "]";
	}

	function getSelectionMemoryKey() {
		return curLayerInstance!=null ? Std.string(curLayerInstance.layerDefUid) : null;
	}

	public function selectValue(v:T) {
		if( curLayerInstance!=null )
			SELECTION_MEMORY.set(getSelectionMemoryKey(), v);
	}
	public function getSelectedValue() : T {
		return
			curLayerInstance==null
			? getDefaultValue()
			: SELECTION_MEMORY.exists( getSelectionMemoryKey() )
				? SELECTION_MEMORY.get( getSelectionMemoryKey() )
				: getDefaultValue();
	}
	function getDefaultValue() : T {
		return null;
	}

	public static function clearSelectionMemory() {
		SELECTION_MEMORY = new Map();
	}


	function snapToGrid() return editor.getGridSnapping();


	public function as<E:Tool<X>,X>(c:Class<E>) : E return cast this;

	public function canEdit() return getSelectedValue()!=null && editor.isCurrentLayerVisible();
	public function isRunning() return curMode!=null;

	public function startUsing(m:MouseCoords, buttonId:Int) {
		curMode = null;
		startTime = haxe.Timer.stamp();
		clickingOutsideBounds = !curLevel.inBounds(m.levelX, m.levelY);

		// Start tool
		button = buttonId;
		switch button {
			case 0:
				if( App.ME.isKeyDown(K.SPACE) )
					curMode = PanView;
				else
					curMode = Add;

			case 1:
				curMode = Remove;

			case 2:
				curMode = PanView;
		}

		if( curMode==PanView )
			clickingOutsideBounds = false;

		if( !canEdit() && ( curMode==Add || curMode==Remove ) ) {
			curMode = null;
			return;
		}

		editor.curLevelHistory.initChangeMarks();
		rectangle = App.ME.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !clickingOutsideBounds && !rectangle && useAt(m) )
			onEditAnything();
	}


	function updateCursor(m:MouseCoords) {}

	function useFloodfillAt(m:MouseCoords) {
		return false;
	}

	function _floodFillImpl(m:MouseCoords, isBlocking:(cx:Int,cy:Int)->Bool, setter:(cx:Int,cy:Int,v:T)->Void) {
		var li = curLayerInstance;

		if( isBlocking(m.cx,m.cy) )
			return false;

		var pending = [{ cx:m.cx, cy:m.cy }];
		var dones = new Map();
		function check(cx:Int,cy:Int) {
			if( li.isValid(cx,cy) && !dones.exists(cx+cy*li.cWid) && !isBlocking(cx,cy) ) {
				dones.set(cx+cy*li.cWid, true);
				pending.push({ cx:cx, cy:cy });
			}
		}

		// Fill bounds
		var left = m.cx;
		var right = left;
		var top = m.cy;
		var bottom = top;

		while( pending.length>0 ) {
			var cur = pending.pop();

			// Add nearby "empty" cells
			check(cur.cx-1, cur.cy);
			check(cur.cx+1, cur.cy);
			check(cur.cx, cur.cy-1);
			check(cur.cx, cur.cy+1);

			// Apply
			editor.curLevelHistory.markChange(cur.cx, cur.cy);
			setter( cur.cx, cur.cy, getSelectedValue() );

			// Update bounds
			left = M.imin( left, cur.cx );
			right = M.imax( right, cur.cx );
			top = M.imin( top, cur.cy );
			bottom = M.imax( bottom, cur.cy );
		}

		editor.levelRender.invalidateLayerArea(curLayerInstance, left, right, top, bottom);

		return true;
	}

	function useAt(m:MouseCoords) : Bool {
		if( curMode==PanView ) {
			editor.levelRender.focusLevelX -= m.levelX-lastMouse.levelX;
			editor.levelRender.focusLevelY -= m.levelY-lastMouse.levelY;
		}

		var anyChange = false;
		dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
			anyChange = useAtInterpolatedGrid(cx,cy) || anyChange;
			if( anyChange )
				editor.levelRender.invalidateLayerArea(curLayerInstance, cx,cx, cy,cy);
		});
		return anyChange;
	}

	function useAtInterpolatedGrid(cx:Int, cy:Int) {
		return false;
	}

	function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) : Bool {
		return false;
	}

	function onHistorySaving() {
	}

	public function stopUsing(m:MouseCoords) {
		var clickTime = haxe.Timer.stamp() - startTime;

		if( isRunning() && !clickingOutsideBounds ) {
			var anyChange = false;

			if( rectangle && m.cx==origin.cx && m.cy==origin.cy && clickTime<=0.22 && !App.ME.isAltDown() ) {
				anyChange = useFloodfillAt(m);
			}
			else {
				if( rectangle ) {
					var left = M.imin(origin.cx, m.cx);
					var right = M.imax(origin.cx, m.cx);
					var top = M.imin(origin.cy, m.cy);
					var bottom = M.imax(origin.cy, m.cy);
					anyChange = useOnRectangle(left, right, top, bottom);
					if( anyChange )
						editor.levelRender.invalidateLayerArea(curLayerInstance, left, right, top, bottom);
				}
				else {
					anyChange = useAt(m);
				}
			}


			if( anyChange )
				onEditAnything();
		}

		if( needHistorySaving ) {
			editor.curLevelHistory.saveLayerState( curLayerInstance );
			editor.curLevelHistory.flushChangeMarks();
			// editor.curLevelHistory.setLastStateBounds(
			// 	M.imin(origin.cx, m.cx) * curLayerInstance.def.gridSize,
			// 	M.imin(origin.cy, m.cy) * curLayerInstance.def.gridSize,
			// 	( M.iabs(origin.cx-m.cx) + 1 ) * curLayerInstance.def.gridSize,
			// 	( M.iabs(origin.cy-m.cy) + 1 ) * curLayerInstance.def.gridSize
			// );
			needHistorySaving = false;
			onHistorySaving();
		}
		curMode = null;
	}

	var needHistorySaving = false;
	inline function onEditAnything() {
		editor.ge.emit(LayerInstanceChanged);
		needHistorySaving = true;
	}

	public function onKeyPress(keyId:Int) {}

	public function onMouseMove(m:MouseCoords) {
		editor.cursor.setLabel();
		if( isRunning() && clickingOutsideBounds && curLevel.inBounds(m.levelX,m.levelY) )
			clickingOutsideBounds = false;

		// Execute the tool
		if( !clickingOutsideBounds && isRunning() && !rectangle && useAt(m) )
			onEditAnything();

		// Render cursor
		if( isRunning() && clickingOutsideBounds )
			editor.cursor.set(None);
		// else if( !isRunning() && isPicking(m) ) {
		// 	// Preview picking
		// 	var ge = editor.getGenericLevelElementAt(m, App.ME.isShiftDown() ? null : curLayerInstance);
		// 	switch ge {
		// 		case null:
		// 			editor.cursor.set(PickNothing);

		// 		case IntGrid(li, cx, cy):
		// 			var id = li.getIntGridIdentifierAt(cx,cy);
		// 			editor.cursor.set(
		// 				GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ),
		// 				id==null ? "#"+li.getIntGrid(cx,cy) : id
		// 			);

		// 		case Entity(li, ei):
		// 			editor.cursor.set(
		// 				Entity(li, ei.def, ei, ei.x, ei.y),
		// 				ei.def.identifier,
		// 				true
		// 			);

		// 		case Tile(li, cx,cy):
		// 			editor.cursor.set(
		// 				Tiles(li, [li.getGridTile(cx,cy)], cx, cy),
		// 				"Tile "+li.getGridTile(cx,cy)
		// 			);

		// 		case PointField(li, ei, fi, arrayIdx):
		// 			var pt = fi.getPointGrid(arrayIdx);
		// 			editor.cursor.set( GridCell(li, pt.cx, pt.cy, ei.getSmartColor(false)) );
		// 	}
		// 	if( ge!=null )
		// 		editor.cursor.setSystemCursor(Button);
		// }
		else if( App.ME.isKeyDown(K.SPACE) )
			editor.cursor.set(Move);
		else switch curMode {
			case PanView:
				editor.cursor.set(Move);

			case null, Add, Remove:
				if( editor.isCurrentLayerVisible() )
					updateCursor(m);
				else
					editor.cursor.set(Forbidden);
		}

		lastMouse = m;
	}

	public final function onToolActivation() {
		resume();

		if( palette!=null ) {
			// Show palette
			jPalette.empty();
			palette.jContent.appendTo( jPalette );
			palette.render();
		}
	}

	function createToolPalette() {
		return new ui.ToolPalette(this); // <-- should be overridden in extended classes
	}

	public function onValuePicking() {
		palette.render();
		palette.focusOnSelection();
	}

	public function initPalette() {
		palette = createToolPalette();
		palette.render();
	}


	override function update() {
		super.update();
		if( palette!=null )
			palette.update();
	}

}