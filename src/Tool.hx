import dn.Bresenham;

class Tool<T> extends dn.Process {
	static var SELECTED_VALUES : Map<Int, Dynamic> = new Map();

	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayerContent;

	var jPalette(get,never) : J; inline function get_jPalette() return client.jPalette;

	var running = false;
	var origin : MouseCoords;
	var lastMouse : Null<MouseCoords>;
	var button = 0;
	var rectangle = false;

	private function new() {
		super(Client.ME);
		updatePalette();
	}

	function selectValue(v:T) {
		SELECTED_VALUES.set(curLayer.layerDefId, v);
		updatePalette();
	}
	function getSelectedValue() : T {
		return SELECTED_VALUES.exists(curLayer.layerDefId)
			? SELECTED_VALUES.get(curLayer.layerDefId)
			: getDefaultValue();
	}
	function getDefaultValue() : T {
		return null;
	}

	public function updatePalette() {
		jPalette.empty();
	}

	public function canBeUsed() return getSelectedValue()!=null;
	public function isRunning() return running;

	inline function isAdding() return isRunning() && button==0;
	inline function isRemoving() return isRunning() && button==1;

	public function startUsing(m:MouseCoords, buttonId:Int) {
		if( client.isAltDown() ) {
			var ge = getGenericLevelElementAt(m);
			N.debug(ge);
			return;
		}
		running = true;
		button = buttonId;
		rectangle = client.isShiftDown();
		origin = m;
		lastMouse = m;
		if( !rectangle )
			useAt(m);
	}

	function getGenericLevelElementAt(m:MouseCoords, ?limitToLayer:LayerContent) : Null<GenericLevelElement> {
		var ge : GenericLevelElement = null;

		function getElement(layer:LayerContent) {
			switch layer.def.type {
				case IntGrid:
					if( layer.getIntGrid(m.cx,m.cy)>=0 )
						ge = GenericLevelElement.IntGrid( layer, m.cx, m.cy );

				case Entities:
					for(ei in layer.entities)
						if( ei.isOver(m.levelX, m.levelY) )
							ge = GenericLevelElement.Entity(ei);
			}
		}

		if( limitToLayer==null ) {
			var all = curLevel.layerContents.copy();
			all.reverse();
			for(lc in all)
				getElement(lc);
		}
		else
			getElement(limitToLayer);

		return ge;
	}

	function updateCursor(m:MouseCoords) {}

	function useAt(m:MouseCoords) {}

	function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {}

	public function stopUsing(m:MouseCoords) {
		if( isRunning() )
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

		running = false;
	}

	public function onMouseMove(m:MouseCoords) {
		// Drawing
		if( isRunning() && !rectangle )
			useAt(m);

		// Cursor
		if( !isRunning() && client.isAltDown() ) {
			var ge = getGenericLevelElementAt(m);
			switch ge {
				case null: client.cursor.set(None);
				case IntGrid(lc, cx, cy): client.cursor.set( GridCell( cx, cy, lc.getIntGridColor(cx,cy) ) );
				case Entity(instance): client.cursor.set( Entity(instance.def, instance.x, instance.y) );
			}
		}
		else
			updateCursor(m);

		lastMouse = m;
	}

}