package ui;

class Cursor extends dn.Process {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : led.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : led.Level; inline function get_curLevel() return Editor.ME.curLevel;

	var type : CursorType = null;

	var wrapper : h2d.Object;
	var graphics : h2d.Graphics;

	var labelWrapper : h2d.Flow;
	var curLabel : Null<String>;
	public var canChangeSystemCursors = false;
	var permanentHighlight = false;

	public function new() {
		super(Editor.ME);
		createRootInLayers(Editor.ME.root, Const.DP_UI);

		graphics = new h2d.Graphics(root);

		wrapper = new h2d.Object(root);
		wrapper.alpha = 0.4;

		labelWrapper = new h2d.Flow(root);
		labelWrapper.backgroundTile = h2d.Tile.fromColor(0x0, 1,1, 0.7);
		labelWrapper.paddingHorizontal = 4;
		labelWrapper.paddingVertical = 2;
	}

	public function setLabel(?str:String) {
		labelWrapper.removeChildren();
		if( str!=null ) {
			var tf = new h2d.Text(Assets.fontPixelOutline, labelWrapper);
			tf.text = str;
		}
		curLabel = str;
	}

	public function setSystemCursor(c:hxd.Cursor) {
		if( canChangeSystemCursors )
			hxd.System.setCursor(c);
	}

	function render(softHighlight:Bool) {
		if( permanentHighlight )
			softHighlight = true;

		wrapper.removeChildren();
		wrapper.filter = null;
		graphics.clear();
		graphics.lineStyle(0);
		graphics.endFill();

		wrapper.visible = type!=None && !Modal.hasAnyOpen() && editor.isCurrentLayerVisible();
		graphics.visible = wrapper.visible;
		labelWrapper.visible = curLabel!=null;

		setSystemCursor(Default);

		var pad = 2;

		switch type {
			case None:

			case Resize(pos):
				#if js
				setSystemCursor( hxd.Cursor.CustomCursor.getNativeCursor(switch pos {
					case Top: "n-resize";
					case Bottom: "s-resize";
					case Left: "w-resize";
					case Right: "e-resize";
					case TopLeft: "nw-resize";
					case TopRight: "ne-resize";
					case BottomLeft: "sw-resize";
					case BottomRight: "se-resize";
				}) );
				#end

			case PickNothing:
				setSystemCursor( hxd.Cursor.CustomCursor.getNativeCursor("help") );

			case Forbidden:
				setSystemCursor( hxd.Cursor.CustomCursor.getNativeCursor("not-allowed") );

			case Move:
				setSystemCursor(Move);

			case Eraser(x, y):
				graphics.lineStyle(1, 0xff0000, 1);
				graphics.drawCircle(0,0, 6);
				graphics.lineStyle(1, 0x880000, 1);
				graphics.drawCircle(0,0, 8);

			case Link(fx, fy, tx, ty, c):
				graphics.lineStyle(1, c);
				graphics.moveTo(0,0);
				graphics.lineTo(tx-fx, ty-fy);

			case GridCell(li, cx, cy, col):
				if( col==null )
					col = 0xffcc00;
				graphics.lineStyle(1, softHighlight ? 0xffffff : getOpposite(col), 0.8);
				graphics.drawRect(-pad, -pad, li.def.gridSize+pad*2, li.def.gridSize+pad*2);

				graphics.lineStyle(1, col);
				graphics.drawRect(0, 0, li.def.gridSize, li.def.gridSize);

			case GridRect(li, cx, cy, wid, hei, col):
				if( col==null )
					col = 0xffcc00;
				graphics.lineStyle(1, softHighlight ? 0xffffff : getOpposite(col), 0.8);
				graphics.drawRect(-2, -2, li.def.gridSize*wid+4, li.def.gridSize*hei+4);

				graphics.lineStyle(1, col);
				graphics.drawRect(0, 0, li.def.gridSize*wid, li.def.gridSize*hei);

			case Entity(li, def, ei, x, y):
				if( softHighlight )
					graphics.lineStyle(2, 0xffffff, 1);
				else
					graphics.lineStyle(1, getOpposite(def.color), 0.8);
				graphics.drawRect(
					-pad -def.width*def.pivotX,
					-pad -def.height*def.pivotY,
					def.width + pad*2,
					def.height + pad*2
				);

				var o = display.LevelRender.createEntityRender(ei, def, wrapper);

			case Tiles(li, tileIds, cx, cy):
				var td = project.defs.getTilesetDef( li.def.tilesetDefUid );
				if( td!=null ) {
					var left = Const.INFINITE;
					var top = Const.INFINITE;
					for(tid in tileIds) {
						left = M.imin( left, td.getTileCx(tid) );
						top = M.imin( top, td.getTileCy(tid) );
					}

					var gridDiffScale = M.imax(1, M.round( td.tileGridSize / li.def.gridSize ) );
					for(tid in tileIds) {
						var cx = td.getTileCx(tid);
						var cy = td.getTileCy(tid);
						var bmp = new h2d.Bitmap( td.getTile(tid), wrapper );
						bmp.tile.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
						bmp.x = (cx-left) * li.def.gridSize * gridDiffScale;
						bmp.y = (cy-top) * li.def.gridSize * gridDiffScale;
					}
					wrapper.filter = new h2d.filter.Glow(0xffffff, 1, 2);
				}
		}

		graphics.endFill();
		customRender();
		updatePosition();
	}

	public dynamic function customRender() {}

	function getOpposite(c:UInt) { // black or white
		return C.interpolateInt(c, C.getPerceivedLuminosityInt(c)>=0.7 ? 0x0 : 0xffffff, 0.5);
	}

	public function set(t:CursorType, ?label:String, softHighlight=false) {
		var changed = type==null || curLabel!=label || type.getIndex()!=t.getIndex();
		if( !changed )
			changed = switch t {
				case None, Move, PickNothing, Forbidden: type!=t;
				case Eraser(x, y): false;
				case GridCell(li, cx, cy, col): !type.equals(t);
				case GridRect(li, cx, cy, wid, hei, col): !type.equals(t);
				case Entity(li, def, ei, x, y): !type.equals(t);
				case Tiles(li, tileIds, cx, cy): !type.equals(t);
				case Resize(p): !type.equals(t);
				case Link(fx, fy, tx, ty, c): !type.equals(t);
			}

		type = t;
		setLabel(label);
		if( changed )
			render(softHighlight);
	}

	public function updatePosition() {
		if( type==None )
			return;

		switch type {
			case None, Move, Resize(_), PickNothing, Forbidden:
				var m = editor.getMouse();
				labelWrapper.setPosition(m.levelX, m.levelY);

			case Eraser(x, y):
				wrapper.setPosition(x,y);

			case Link(fx, fy, tx, ty, c):
				wrapper.setPosition(fx,fy);

			case GridCell(li, cx, cy), GridRect(li, cx,cy, _):
				wrapper.setPosition( cx*li.def.gridSize + li.pxOffsetX, cy*li.def.gridSize + li.pxOffsetY );
				labelWrapper.setPosition(wrapper.x + li.def.gridSize, wrapper.y);

			case Entity(li, def, ei, x,y):
				wrapper.setPosition( x+li.pxOffsetX, y+li.pxOffsetY );
				labelWrapper.setPosition(
					( Std.int(x/li.def.gridSize) + 1 ) * li.def.gridSize,
					Std.int(y/li.def.gridSize) * li.def.gridSize
				);

			case Tiles(li, tileIds, cx, cy):
				wrapper.setPosition(
					(cx+li.def.tilePivotX)*li.def.gridSize + li.pxOffsetX,
					(cy+li.def.tilePivotY)*li.def.gridSize + li.pxOffsetY
				);
				labelWrapper.setPosition( (cx+1)*li.def.gridSize + li.pxOffsetX, cy*li.def.gridSize + li.pxOffsetY );
		}

		graphics.setPosition(wrapper.x, wrapper.y);

		labelWrapper.setScale(1/editor.levelRender.zoom * js.Browser.window.devicePixelRatio*2);
	}

	public function enablePermanentHighlights() {
		permanentHighlight = true;
		root.filter = new h2d.filter.Group([
			new h2d.filter.Glow(0xffcc00,1, 16, 1.4, 2, true),
		]);
	}

	override function postUpdate() {
		super.postUpdate();

		root.x = editor.levelRender.root.x;
		root.y = editor.levelRender.root.y;
		root.setScale(editor.levelRender.zoom);

		updatePosition();
	}

	override function update() {
		super.update();
	}
}