import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTED_VALUES : Map<Int, Dynamic> = new Map();

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayerContent(get,never) : LayerInstance; inline function get_curLayerContent() return Client.ME.curLayerContent;

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
		SELECTED_VALUES.set(curLayerContent.layerDefId, v);
		updatePalette();
	}
	public function getSelectedValue() : T {
		return SELECTED_VALUES.exists(curLayerContent.layerDefId)
			? SELECTED_VALUES.get(curLayerContent.layerDefId)
			: getDefaultValue();
	}
	function getDefaultValue() : T {
		return null;
	}


	function snapToGrid() return !client.isCtrlDown() || cd.has("requireCtrlRelease");


	public function as<E:Tool<X>,X>(c:Class<E>) : E return cast this;

	public function canBeUsed() return getSelectedValue()!=null;
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
			if( client.curTool!=this) {
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
		rectangle = client.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !rectangle )
			useAt(m);
	}


	function duplicateElement(ge:GenericLevelElement) : GenericLevelElement {
		switch ge {
			case IntGrid(lc, cx, cy):
				throw "Unsupported";

			case Entity(instance):
				var ei = curLayerContent.createEntityInstance(instance.def); // HACK TODO use clone
				ei.x = instance.x;
				ei.y = instance.y;
				return GenericLevelElement.Entity(ei);
		}
	}

	function getGenericLevelElementAt(m:MouseCoords, ?limitToLayerContent:LayerInstance) : Null<GenericLevelElement> {
		var ge : GenericLevelElement = null;

		function getElement(lc:LayerInstance) {
			var cx = m.getLayerCx(lc.def);
			var cy = m.getLayerCy(lc.def);
			switch lc.def.type {
				case IntGrid:
					if( lc.getIntGrid(cx,cy)>=0 )
						ge = GenericLevelElement.IntGrid( lc, cx, cy );

				case Entities:
					for(ei in lc.entityInstances)
						if( ei.isOver(m.levelX, m.levelY) )
							ge = GenericLevelElement.Entity(ei);
			}
		}

		if( limitToLayerContent==null ) {
			var all = curLevel.layerContents.copy();
			all.reverse();
			for(lc in all)
				getElement(lc);
		}
		else
			getElement(limitToLayerContent);

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
				case IntGrid(lc, cx, cy): client.cursor.set( GridCell( lc, cx, cy, lc.getIntGridColorAt(cx,cy) ) );
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