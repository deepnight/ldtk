import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTED_VALUES : Map<Int, Dynamic> = new Map();

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayerContent(get,never) : LayerContent; inline function get_curLayerContent() return Client.ME.curLayerContent;

	var jPalette(get,never) : J; inline function get_jPalette() return client.jPalette;

	var curMode : Null<ToolEditMode> = null;
	var origin : MouseCoords;
	var lastMouse : Null<MouseCoords>;
	var button = -1;
	var rectangle = false;
	var pickedElement : Null<GenericLevelElement>;

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
	function getSelectedValue() : T {
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
		pickedElement = null;
		cd.unset("requireCtrlRelease");

		// Picking an existing element
		if( client.isAltDown() && buttonId==0 ) {
			var ge = getGenericLevelElementAt(m);

			if( ge==null )
				return;

			client.pickGenericLevelElement(ge);
			if( client.isCtrlDown() ) {
				ge = duplicateElement(ge);
				cd.setS("requireCtrlRelease", Const.INFINITE);
			}
			pickedElement = ge;

			// If layer changed, client curTool was re-created
			if( client.curTool!=this) {
				client.curTool.startUsing(m,buttonId);
				return;
			}
		}


		// Start tool
		button = buttonId;
		curMode = button==0 ? ( client.isAltDown() ? Move : Add ) : button==1 ? Remove : PanView;
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

	function getGenericLevelElementAt(m:MouseCoords, ?limitToLayerContent:LayerContent) : Null<GenericLevelElement> {
		var ge : GenericLevelElement = null;

		function getElement(lc:LayerContent) {
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

	function useAt(m:MouseCoords) {}

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
		// Use the tool
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