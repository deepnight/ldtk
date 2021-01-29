import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTION_MEMORY : Map<String, Dynamic> = new Map();

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	@:allow(ui.ToolPalette)
	var curLayerInstance(get,never) : data.inst.LayerInstance; inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	var jPalette(get,never) : J; inline function get_jPalette() return editor.jPalette;
	var jOptions(get,never) : J; inline function get_jOptions() return editor.jMainPanel.find("#toolOptions");

	var clickingOutsideBounds = false;
	var curMode : Null<ToolEditMode> = null;
	var origin : Coords;
	var lastMouse : Null<Coords>;
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
			+ "[" + ( curMode==null ? "--" : curMode.getName() ) + "]"
			+ ( isRunning() ? " (RUNNING)" : "" );

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


	function snapToGrid() return editor.isSnappingToGrid();


	public function as<E:Tool<X>,X>(c:Class<E>) : E return cast this;

	public function canEdit() return getSelectedValue()!=null && editor.isCurrentLayerVisible();
	public function isRunning() return curMode!=null;

	public function startUsing(ev:hxd.Event, m:Coords) {
		curMode = null;
		startTime = haxe.Timer.stamp();
		clickingOutsideBounds = !curLevel.inBounds(m.levelX, m.levelY);

		// Start tool
		button = ev.button;
		switch button {
			case 0:
				curMode = Add;

			case 1:
				curMode = Remove;
		}

		if( !canEdit() && ( curMode==Add || curMode==Remove ) ) {
			curMode = null;
			return;
		}

		editor.curLevelHistory.initChangeMarks();
		rectangle = App.ME.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !clickingOutsideBounds && !rectangle && useAt(m,false) )
			onEditAnything();
	}


	function updateCursor(m:Coords) {}

	function useFloodfillAt(m:Coords) {
		return false;
	}

	function _floodFillImpl(
		m:Coords,
		isBlocking:(cx:Int,cy:Int)->Bool,
		setter:(cx:Int,cy:Int,v:T)->Void,
		?onFill:(left:Int, right:Int, top:Int, bottom:Int, affectedPoints:Array<{ cx:Int, cy:Int }>)->Void
	) {
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
		var affectedPoints = [];

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
			affectedPoints.push(cur);

			// Update bounds
			left = M.imin( left, cur.cx );
			right = M.imax( right, cur.cx );
			top = M.imin( top, cur.cy );
			bottom = M.imax( bottom, cur.cy );
		}

		editor.levelRender.invalidateLayerArea(curLayerInstance, left, right, top, bottom);

		if( onFill!=null )
			onFill(left,right,top,bottom, affectedPoints);

		return true;
	}

	function useAt(m:Coords, isOnStop:Bool) : Bool {
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

	function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) : Bool {
		return false;
	}


	public inline function getRunningRectCWid(m:Coords) : Int {
		return isRunning() && rectangle ? M.iabs(m.cx-origin.cx)+1 : 0;
	}

	public inline function getRunningRectCHei(m:Coords) : Int {
		return isRunning() && rectangle ? M.iabs(m.cy-origin.cy)+1 : 0;
	}

	public function stopUsing(m:Coords) {
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
					anyChange = useOnRectangle(m, left, right, top, bottom);
					if( anyChange )
						editor.levelRender.invalidateLayerArea(curLayerInstance, left, right, top, bottom);
				}
				else {
					anyChange = useAt(m,true);
					if( anyChange )
						editor.levelRender.invalidateLayer(curLayerInstance);
				}
			}


			if( anyChange )
				onEditAnything();
		}

		if( needHistorySaving ) {
			saveToHistory();
			needHistorySaving = false;
		}
		curMode = null;
	}


	function saveToHistory() {
		editor.curLevelHistory.saveLayerState( curLayerInstance );
		editor.curLevelHistory.flushChangeMarks();
		needHistorySaving = false;
	}


	var needHistorySaving = false;
	final function onEditAnything() {
		editor.ge.emit(LayerInstanceChanged);
		needHistorySaving = true;
	}

	public function onKeyPress(keyId:Int) {}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		editor.cursor.setLabel();

		if( isRunning() && clickingOutsideBounds && curLevel.inBounds(m.levelX,m.levelY) )
			clickingOutsideBounds = false;

		// Execute the tool
		if( !clickingOutsideBounds && isRunning() && !rectangle && useAt(m, false) )
			onEditAnything();

		// Render cursor
		if( isRunning() && clickingOutsideBounds )
			editor.cursor.set(None);
		else switch curMode {
			case null, Add, Remove:
				if( editor.isCurrentLayerVisible() )
					updateCursor(m);
				else
					editor.cursor.set(Forbidden);
		}

		lastMouse = m;
	}

	function onBeforeToolActivation() {}

	public final function onToolActivation() {
		onBeforeToolActivation();

		resume();

		jPalette.empty();
		if( palette!=null ) {
			// Show palette
			palette.jContent.appendTo( jPalette );
			palette.render();
		}
		initOptionForm();
	}

	function createToolPalette() {
		return new ui.ToolPalette(this); // <-- should be overridden in extended classes
	}

	public function onValuePicking() {
		palette.render();
		palette.focusOnSelection();
	}

	public function palettePoppedOut() {
		return palette!=null && palette.isPoppedOut && ui.modal.ToolPalettePopOut.ME!=null;
	}

	public function popInPalette() {
		if( palettePoppedOut() )
			ui.modal.ToolPalettePopOut.ME.close();
	}

	public function initPalette() {
		palette = createToolPalette();
		palette.render();
		initOptionForm();
	}

	function initOptionForm() {
		jOptions.empty();
	}


	override function update() {
		super.update();
		if( palette!=null )
			palette.update();
	}

}