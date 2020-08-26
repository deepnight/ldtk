import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTION_MEMORY : Map<Int, Dynamic> = new Map();

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : led.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : led.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var curLayerInstance(get,never) : led.inst.LayerInstance; inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	var jPalette(get,never) : J; inline function get_jPalette() return editor.jPalette;

	var clickingOutsideBounds = false;
	var curMode : Null<ToolEditMode> = null;
	var origin : MouseCoords;
	var lastMouse : Null<MouseCoords>;
	var button = -1;
	var rectangle = false;
	var moveStarted = false;
	var startTime = 0.;

	private function new() {
		super(Editor.ME);

		jPalette.off().find("*").off();
		updatePalette();
		editor.ge.addSpecificListener(ToolOptionChanged, onToolOptionChanged);
	}

	function onToolOptionChanged() {
		updatePalette();
	}

	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onToolOptionChanged);
	}

	function enablePalettePopOut() {
		jPalette
			.off()
			.mouseover( function(_) {
				popOutPalette();
			});
	}

	override function toString():String {
		return Type.getClassName(Type.getClass(this))
			+ "[" + ( curMode==null ? "--" : curMode.getName() ) + "]";
	}


	public function selectValue(v:T) {
		if( curLayerInstance!=null )
			SELECTION_MEMORY.set(curLayerInstance.layerDefUid, v);
		updatePalette();
	}
	public function getSelectedValue() : T {
		return
			curLayerInstance==null
			? getDefaultValue()
			: SELECTION_MEMORY.exists(curLayerInstance.layerDefUid)
				? SELECTION_MEMORY.get(curLayerInstance.layerDefUid)
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
		editor.clearSelection();
		moveStarted = false;
		clickingOutsideBounds = !curLevel.inBounds(m.levelX, m.levelY);

		// Picking an existing element
		if( editor.isAltDown() && buttonId==0 ) {
			if( !editor.isCurrentLayerVisible() )
				return;

			var ge = getGenericLevelElementAt(m);

			if( ge==null )
				return;

			editor.pickGenericLevelElement(ge);
			editor.setSelection(ge);

			// If layer changed, client curTool was re-created
			if( editor.curTool!=this ) {
				editor.curTool.startUsing(m,buttonId);
				return;
			}
		}

		// Start tool
		button = buttonId;
		switch button {
			case 0:
				if( editor.isKeyDown(K.SPACE) )
					curMode = PanView;
				else if( editor.isAltDown() )
					curMode = Move;
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
		rectangle = editor.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !clickingOutsideBounds && !rectangle && useAt(m) )
			onEditAnything();
	}


	function duplicateElement(ge:GenericLevelElement) : Null<GenericLevelElement> {
		switch ge {
			case IntGrid(li, cx, cy):
				return null;

			case Entity(instance):
				var ei = curLayerInstance.duplicateEntityInstance( instance );
				return GenericLevelElement.Entity(ei);

			case Tile(li, cx, cy):
				return null;
		}
	}

	function getGenericLevelElementAt(m:MouseCoords, ?limitToLayerInstance:led.inst.LayerInstance) : Null<GenericLevelElement> {
		var ge : GenericLevelElement = null;

		function getElement(li:led.inst.LayerInstance) {
			var cx = m.getLayerCx(li.def);
			var cy = m.getLayerCy(li.def);
			switch li.def.type {
				case IntGrid:
					if( li.getIntGrid(cx,cy)>=0 )
						ge = GenericLevelElement.IntGrid( li, cx, cy );

				case Entities:
					for(ei in li.entityInstances)
						if( ei.isOver(m.levelX, m.levelY) )
							ge = GenericLevelElement.Entity(ei);

				case Tiles:
					if( li.getGridTile(cx,cy)!=null )
						ge = GenericLevelElement.Tile(li, cx, cy);
			}
		}

		if( limitToLayerInstance==null ) {
			// Search in all layers
			var all = project.defs.layers.copy();
			all.reverse();
			for(ld in all)
				getElement( curLevel.getLayerInstance(ld) );
		}
		else
			getElement(limitToLayerInstance);

		return ge;
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

		while( pending.length>0 ) {
			var cur = pending.pop();

			check(cur.cx-1, cur.cy);
			check(cur.cx+1, cur.cy);
			check(cur.cx, cur.cy-1);
			check(cur.cx, cur.cy+1);

			setter( cur.cx, cur.cy, getSelectedValue() );
		}

		return true;
	}

	function useAt(m:MouseCoords) : Bool {
		if( curMode==PanView ) {
			editor.levelRender.focusLevelX -= m.levelX-lastMouse.levelX;
			editor.levelRender.focusLevelY -= m.levelY-lastMouse.levelY;
		}
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

			if( rectangle && m.cx==origin.cx && m.cy==origin.cy && clickTime<=0.22 )
				anyChange = useFloodfillAt(m);
			else {
				anyChange = rectangle
					? useOnRectangle(
						M.imin(origin.cx, m.cx),
						M.imax(origin.cx, m.cx),
						M.imin(origin.cy, m.cy),
						M.imax(origin.cy, m.cy)
					 )
					: useAt(m);
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
		if( isRunning() && clickingOutsideBounds && curLevel.inBounds(m.levelX,m.levelY) )
			clickingOutsideBounds = false;

		// Start moving elements only after a small elapsed mouse distance
		if( curMode==Move && !moveStarted && M.dist(origin.pageX, origin.pageY, m.pageX, m.pageY) >= 10*Const.SCALE ) {
			moveStarted = true;
			if( editor.isCtrlDown() && editor.selection!=null ) {
				var copy = duplicateElement(editor.selection);
				if( copy!=null )
					editor.setSelection(copy);
			}
		}

		// Execute the tool
		if( !clickingOutsideBounds && isRunning() && !rectangle && useAt(m) )
			onEditAnything();

		// Render cursor
		if( isRunning() && clickingOutsideBounds )
			editor.cursor.set(None);
		else if( !isRunning() && editor.isAltDown() ) {
			// Preview picking
			var ge = getGenericLevelElementAt(m);
			switch ge {
				case null: updateCursor(m);
				case IntGrid(li, cx, cy): editor.cursor.set( GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ) );
				case Entity(instance): editor.cursor.set( Entity(instance.def, instance.x, instance.y) );
				case Tile(li, cx,cy): editor.cursor.set( Tiles(li, [li.getGridTile(cx,cy)], cx, cy) );
			}
		}
		else if( editor.isKeyDown(K.SPACE) )
			editor.cursor.set(Move);
		else switch curMode {
			case PanView, Move:
				editor.cursor.set(Move);

			case null, Add, Remove:
				updateCursor(m);
		}

		lastMouse = m;
	}


	public function popOutPalette() {
		new ui.modal.ToolPalettePopOut(this);
	}

	public final function updatePalette() {
		jPalette.empty();
		jPalette.append( createPalette() );
	}

	public function createPalette() : js.jquery.JQuery {
		return new J('<div class="palette"/>');
	}


	override function update() {
		super.update();
	}

}