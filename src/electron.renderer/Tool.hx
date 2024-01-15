import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTION_MEMORY : Map<String, Dynamic> = new Map();

	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	@:allow(ui.ToolPalette)
	var curLayerInstance(get,never) : data.inst.LayerInstance; inline function get_curLayerInstance() return Editor.ME.curLayerInstance;

	var jPalette(get,never) : J; inline function get_jPalette() return editor.jPalette;
	public var jOptions(get,never) : J; inline function get_jOptions() return editor.jMainPanel.find("#toolOptions");

	var clickingOutsideBounds = false;
	var canUseOutOfBounds = false;
	var curMode : Null<ToolEditMode> = null;
	var origin : Coords;
	var lastMouse : Null<Coords>;
	var button = -1;
	var rectangle = false;
	var startTime = 0.;
	var palette : Null<ui.ToolPalette>;

	private function new() {
		super(Editor.ME);
	}

	override function onDispose() {
		super.onDispose();
	}


	function checkOutOfBounds() {
		return !clickingOutsideBounds || canUseOutOfBounds;
	}


	public function getShortName() {
		var raw = Type.getClassName( Type.getClass(this) );
		return raw.substr( raw.lastIndexOf(".")+1 );
	}

	@:keep
	override function toString():String {
		return super.toString()
			+ "[" + ( curMode==null ? "--" : curMode.getName() ) + "]"
			+ ( isRunning() ? " [RUNNING]" : "" );

	}

	public function onGlobalEvent(ev:GlobalEvent) {}

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

	public function canEdit() return getSelectedValue()!=null && editor.isCurrentLayerVisible() && App.ME.hasGlContext;
	public function isRunning() return curMode!=null;

	public function startUsing(ev:hxd.Event, m:Coords, ?extraParam:String) {
		App.ME.requestCpu();
		curMode = null;
		startTime = haxe.Timer.stamp();
		clickingOutsideBounds = !curLevel.inBounds(m.levelX, m.levelY);

		// Start tool
		button = ev.button;
		switch button {
			case 0:
				curMode = Add;
				if( App.ME.isMacCtrlDown() )
					curMode = Remove;

			case 1:
				curMode = Remove;
		}

		if( !canEdit() && ( curMode==Add || curMode==Remove ) ) {
			curMode = null;
			return;
		}

		rectangle = App.ME.isShiftDown();
		origin = m;
		lastMouse = m;
		if( checkOutOfBounds() && !rectangle && useAt(m,false) ) {
			ev.cancel = true;
			onEditAnything();
		}
	}


	function customCursor(ev:hxd.Event, m:Coords) {}

	function useFloodfillAt(m:Coords) {
		LOG.userAction(getShortName()+": Flood fill, mode="+curMode+", in "+curLayerInstance);
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
			editor.curLevelTimeline.markGridChange(curLayerInstance, cur.cx, cur.cy);
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
		editor.cancelSpaceKey();
		App.ME.requestCpu();
		return anyChange;
	}

	function useAtInterpolatedGrid(cx:Int, cy:Int) {
		return false;
	}

	function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) : Bool {
		LOG.userAction(getShortName()+": Rectangle, mode="+curMode+", in "+curLayerInstance);
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

		if( isRunning() && checkOutOfBounds() ) {
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
						editor.levelRender.invalidateLayerArea(curLayerInstance, m.cx, m.cx, m.cy, m.cy);
				}
			}


			if( anyChange )
				onEditAnything();
		}

		if( needHistorySaving ) {
			LOG.userAction(getShortName()+": mode="+curMode+", in "+curLayerInstance);
			saveToHistory();
			needHistorySaving = false;
		}
		curMode = null;
	}


	function saveToHistory() {
		editor.curLevelTimeline.saveLayerState(curLayerInstance);
		needHistorySaving = false;
	}


	var needHistorySaving = false;
	final function onEditAnything() {
		editor.ge.emit( LayerInstanceEditedByTool(curLayerInstance) );
		needHistorySaving = true;
	}

	public function onKeyPress(keyId:Int) {}
	public function onAppCommand(cmd:AppCommand) {}

	public function onMouseMove(ev:hxd.Event, m:Coords) {
		if( isRunning() && clickingOutsideBounds && curLevel.inBounds(m.levelX,m.levelY) )
			clickingOutsideBounds = false;

		// Execute the tool
		if( checkOutOfBounds() && isRunning() && !rectangle && useAt(m, false) )
			onEditAnything();

		if( isRunning() )
			editor.levelRender.suspendAsyncRender();

		lastMouse = m;
	}

	public function onMouseMoveCursor(ev:hxd.Event, m:Coords) {
		if( ev.cancel )
			return;

		if( isRunning() && !checkOutOfBounds() )
			editor.cursor.set(None);
		else switch curMode {
			case null, Add, Remove:
				if( editor.isCurrentLayerVisible() )
					customCursor(ev,m);
				else if( editor.curLevel.inBounds(m.levelX,m.levelY) ) {
					ev.cancel = true;
					editor.cursor.set(Forbidden);
				}
		}
	}

	function onBeforeToolActivation() {}

	override function pause() {
		super.pause();
		onToolDeactivation();
	}

	public final function onToolDeactivation() {
		if( palette!=null )
			palette.onHide();
	}

	public final function onToolActivation() {
		onBeforeToolActivation();

		resume();
		initToolOptions();

		jPalette.empty();
		if( palette!=null ) {
			// Show palette
			palette.jContent.appendTo( jPalette );
			palette.render();
			palette.onShow();
		}
	}

	function createToolPalette() : Null<ui.ToolPalette> {
		return null; // <-- should be overridden in extended classes
	}

	public function onValuePicking() {
		if( palette!=null ) {
			palette.render();
			palette.focusOnSelection();
		}
	}

	/** Called when a WASD key is pressed. Should return TRUE to cancel event bubbling. **/
	public function onNavigateSelection(dx:Int, dy:Int, pressed:Bool) {
		return palette!=null && palette.onNavigateSelection(dx,dy,pressed);
	}

	public function palettePoppedOut() {
		return palette!=null && palette.isPoppedOut && ui.modal.ToolPalettePopOut.ME!=null;
	}

	public function popInPalette() {
		if( palettePoppedOut() )
			ui.modal.ToolPalettePopOut.ME.close();
	}

	public function initPalette() {
		initToolOptions();
		palette = createToolPalette();
		if( palette!=null )
			palette.render();
	}

	function initToolOptions() {
		jOptions.empty();
		editor.jMainPanel.find("#paletteOptions").empty();
	}


	override function update() {
		super.update();
		if( palette!=null )
			palette.update();
	}

}