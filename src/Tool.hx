import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTED_VALUES : Map<Int, Dynamic> = new Map();

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayerInstance(get,never) : LayerInstance; inline function get_curLayerInstance() return Client.ME.curLayerInstance;

	var jPalette(get,never) : J; inline function get_jPalette() return client.jPalette;

	var curMode : Null<ToolEditMode> = null;
	var origin : MouseCoords;
	var lastMouse : Null<MouseCoords>;
	var button = -1;
	var rectangle = false;
	var moveStarted = false;

	private function new() {
		super(Client.ME);
		updatePalette();
	}

	override function toString():String {
		return Type.getClassName(Type.getClass(this))
			+ "[" + ( curMode==null ? "--" : curMode.getName() ) + "]";
	}

	public function updatePalette() {
		jPalette.empty();
	}



	public function selectValue(v:T) {
		if( curLayerInstance!=null )
			SELECTED_VALUES.set(curLayerInstance.layerDefId, v);
		updatePalette();
	}
	public function getSelectedValue() : T {
		return
			curLayerInstance==null
			? getDefaultValue()
			: SELECTED_VALUES.exists(curLayerInstance.layerDefId)
				? SELECTED_VALUES.get(curLayerInstance.layerDefId)
				: getDefaultValue();
	}
	function getDefaultValue() : T {
		return null;
	}

	public static function clearSelectionMemory() {
		SELECTED_VALUES = new Map();
	}


	function snapToGrid() return !client.isCtrlDown() || cd.has("requireCtrlRelease");


	public function as<E:Tool<X>,X>(c:Class<E>) : E return cast this;

	public function canEdit() return getSelectedValue()!=null;
	public function isRunning() return curMode!=null;

	public function startUsing(m:MouseCoords, buttonId:Int) {
		curMode = null;
		client.clearSelection();
		moveStarted = false;
		cd.unset("requireCtrlRelease");

		// Picking an existing element
		if( client.isAltDown() && buttonId==0 ) {
			var ge = getGenericLevelElementAt(m);

			if( ge==null )
				return;

			client.pickGenericLevelElement(ge);
			client.setSelection(ge);

			// If layer changed, client curTool was re-created
			if( client.curTool!=this ) {
				client.curTool.startUsing(m,buttonId);
				return;
			}
		}

		// Start tool
		button = buttonId;
		switch button {
			case 0:
				if( client.isKeyDown(K.SPACE) )
					curMode = PanView;
				else if( client.isAltDown() )
					curMode = Move;
				else
					curMode = Add;

			case 1:
				curMode = Remove;

			case 2:
				curMode = PanView;
		}

		if( !canEdit() && ( curMode==Add || curMode==Remove ) ) {
			curMode = null;
			return;
		}

		rectangle = client.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !rectangle )
			useAt(m);
	}


	function duplicateElement(ge:GenericLevelElement) : GenericLevelElement {
		switch ge {
			case IntGrid(li, cx, cy):
				throw "Unsupported";

			case Entity(instance):
				var ei = curLayerInstance.duplicateEntityInstance( instance );
				return GenericLevelElement.Entity(ei);
		}
	}

	function getGenericLevelElementAt(m:MouseCoords, ?limitToLayerInstance:LayerInstance) : Null<GenericLevelElement> {
		var ge : GenericLevelElement = null;

		function getElement(li:LayerInstance) {
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

	function useAt(m:MouseCoords) {
		if( curMode==PanView ) {
			client.levelRender.focusLevelX -= m.levelX-lastMouse.levelX;
			client.levelRender.focusLevelY -= m.levelY-lastMouse.levelY;
		}
	}

	function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {}

	public function stopUsing(m:MouseCoords) {
		if( isRunning() ) {
			if( !rectangle )
				useAt(m);
			else {
				useOnRectangle(
					M.imin(origin.cx, m.cx),
					M.imax(origin.cx, m.cx),
					M.imin(origin.cy, m.cy),
					M.imax(origin.cy, m.cy)
				);
			}
		}

		curMode = null;
	}

	public function onMouseMove(m:MouseCoords) {
		// Start moving elements only after a small elapsed mouse distance
		if( curMode==Move && !moveStarted && M.dist(origin.gx,origin.gy, m.gx,m.gy)>=10*Const.SCALE ) {
			moveStarted = true;
			if( client.isCtrlDown() ) {
				var copy = duplicateElement(client.selection);
				client.setSelection(copy);
				cd.setS("requireCtrlRelease", Const.INFINITE);
			}
		}

		// Execute the tool
		if( isRunning() && !rectangle )
			useAt(m);

		// Render cursor
		if( !isRunning() && client.isAltDown() ) {
			// Preview picking
			var ge = getGenericLevelElementAt(m);
			switch ge {
				case null: client.cursor.set(None);
				case IntGrid(li, cx, cy): client.cursor.set( GridCell( li, cx, cy, li.getIntGridColorAt(cx,cy) ) );
				case Entity(instance): client.cursor.set( Entity(instance.def, instance.x, instance.y) );
			}
		}
		else if( client.isKeyDown(K.SPACE) )
			client.cursor.set(Move);
		else switch curMode {
			case PanView, Move:
				client.cursor.set(Move);

			case null, Add, Remove:
				updateCursor(m);
		}

		lastMouse = m;
	}


	override function update() {
		super.update();

		if( !client.isCtrlDown() && cd.has("requireCtrlRelease") )
			cd.unset("requireCtrlRelease");
	}

}