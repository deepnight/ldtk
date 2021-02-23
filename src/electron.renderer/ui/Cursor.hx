package ui;

class Cursor {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curLevel(get,never) : data.Level; inline function get_curLevel() return Editor.ME.curLevel;
	var cam(get,never) : display.Camera; inline function get_cam() return Editor.ME.camera;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var type : CursorType = None;
	public var root : h2d.Object;
	var g : h2d.Graphics;
	var wrapper : h2d.Object;
	var invalidatedRender = true;

	var label : { f:h2d.Flow, tf:h2d.Text };

	public function new() {
		root = new h2d.Object();

		wrapper = new h2d.Object(root);
		g = new h2d.Graphics(root);

		// Init label
		var f = new h2d.Flow(root);
		f.paddingHorizontal = 3;
		f.paddingVertical = 1;
		var tf = new h2d.Text(Assets.fontLight_small, f);
		label = { f:f, tf:tf }

		editor.ge.addSpecificListener(ViewportChanged, onViewportChange);
		onViewportChange();
	}

	public function dispose() {
		root.remove();
		type = null;
		editor.ge.removeListener(onViewportChange);
	}

	/** Set current cursor **/
	public inline function set(c:CursorType, ?labelStr:String) {
		// Check if actual re-render is needed
		var needRender : Bool = switch c {
			case None,Forbidden,Pan,Move,Moving,PickNothing,Pointer,Add: c!=type;
			case Resize(p):
				switch type {
					case Resize(p2): p!=p2;
					case _: true;
				}

			case Eraser(x,y):
				switch type {
					case Eraser(_): false;
					case _: true;
				}

			case GridCell(li, cx, cy, col):
				switch type {
					case GridCell(li2, cx2, cy2, col2): li2!=li || col2!=col;
					case _: true;
				}


			case GridRect(li, cx, cy, wid, hei, col):
				switch type {
					case GridRect(li2, cx2, cy2, wid2, hei2, col2): li2!=li || wid2!=wid || hei2!=hei || col2!=col;
					case _: true;
				}

			case Entity(li, def, ei, x, y):
				switch type {
					case Entity(li2, def2, ei2, _): li2!=li || def.uid!=def2.uid || ei2!=ei;
					case _: true;
				}

			case Tiles(li, tileIds, cx, cy, flips):
				switch type {
					case Tiles(li2, tileIds2, cx2, cy2, flips2):
						if( tileIds.length!=tileIds2.length || li!=li2 || flips!=flips2 )
							true;
						else {
							var same = true;
							for(i in 0...tileIds.length)
								if( tileIds[i]!=tileIds2[i] ) {
									same = false;
									break;
								}
							!same;
						}
					case _: true;
				}

			case Link(fx, fy, tx, ty, color):
				switch type {
					case Link(fx2,fy2, tx2,ty2, color2): tx!=tx2 || ty!=ty2 || color!=color2;
					case _: true;
				}
		}

		if( needRender ) {
			N.debug("[!] render needed: old="+type+" new="+c);
			invalidateRender();
		}
		type = c;


		if( labelStr!=null && labelStr!=label.tf.text ) {
			// Render label
			label.f.visible = true;
			label.f.setPosition(0,0);
			label.tf.text = labelStr;
			var c = switch type {
				case Eraser(x, y): 0xff0000;
				case GridCell(li, cx, cy, col): col;
				case GridRect(li, cx, cy, wid, hei, col): col;
				case Entity(li, def, ei, x, y): ei==null ? def.color : ei.getSmartColor(false);
				case Tiles(li, tileIds, cx, cy, flips): 0xffffff;
				case Link(fx, fy, tx, ty, color): color;
				case _: 0xffcc00;
			};
			label.f.backgroundTile = h2d.Tile.fromColor( C.toBlack(c, 0.5) );
			label.tf.textColor = C.toWhite(c, 0.5);
		}

		if( labelStr==null && hasLabel() ) {
			// Hide label
			label.f.visible = false;
			label.tf.text = "";
		}
	}

	inline function hasLabel() return label.f.visible;

	inline function centerLabelAbove(x:Float, y:Float) {
		if( hasLabel() ) {
			label.f.x = Std.int( x - label.f.outerWidth*0.5*label.f.scaleX );
			label.f.y = Std.int( y - label.f.outerHeight*label.f.scaleY );
		}
	}


	/** Render current cursor **/
	function render() {
		switch type {
			case None: hideRender(); setSystemCursor();
			case Forbidden: hideRender(); setNativeCursor("not-allowed");
			case Pan: hideRender(); setNativeCursor("all-scroll");
			case Move: hideRender(); setNativeCursor("grab");
			case Moving: hideRender(); setNativeCursor("grabbing");
			case PickNothing: hideRender(); setNativeCursor("help");
			case Pointer: hideRender(); setSystemCursor(hxd.Cursor.Button);
			case Add: hideRender(); setNativeCursor("cell");
			case Resize(p): hideRender(); setResizeCursor(p);

			case Eraser(x, y):
				initRender();

			case GridCell(li, cx, cy, col):
				initRender();

				final p = 2;
				g.lineStyle(2, 0x0);
				g.drawRect(p,p, li.def.gridSize-p*2, li.def.gridSize-p*2);

				g.lineStyle(2, col);
				g.drawRect(0,0, li.def.gridSize, li.def.gridSize);

			case GridRect(li, cx, cy, wid, hei, col):
				initRender();

				final p = 2;
				g.lineStyle(2, 0x0);
				g.drawRect(p,p, li.def.gridSize*wid-p*2, li.def.gridSize*hei-p*2);

				g.lineStyle(2, col);
				g.beginFill(col,0.35);
				g.drawRect(0,0, li.def.gridSize*wid, li.def.gridSize*hei);

			case Entity(li, def, ei, x, y):
				initRender();
				var o = display.EntityRender.renderCore(ei,def);
				wrapper.addChild(o);
				o.alpha = 0.33;

			case Tiles(li, tileIds, cx, cy, flips):
				initRender();
				var td = li.getTiledsetDef();
				if( td!=null ) {
					var left = Const.INFINITE;
					var right = 0;
					var top = Const.INFINITE;
					var bottom = 0;
					for(tid in tileIds) {
						left = M.imin( left, td.getTileCx(tid) );
						right = M.imax( right, td.getTileCx(tid) );
						top = M.imin( top, td.getTileCy(tid) );
						bottom = M.imax( bottom, td.getTileCy(tid) );
					}

					var gridDiffScale = M.imax(1, M.round( td.tileGridSize / li.def.gridSize ) );
					var flipX = M.hasBit(flips,0);
					var flipY = M.hasBit(flips,1);
					for(tid in tileIds) {
						var cx = td.getTileCx(tid);
						var cy = td.getTileCy(tid);
						var bmp = new h2d.Bitmap( td.getTile(tid), wrapper );
						bmp.tile.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
						bmp.x = (flipX ? right-cx+1 : cx-left) * li.def.gridSize * gridDiffScale;
						bmp.y = (flipY ? bottom-cy+1 : cy-top) * li.def.gridSize * gridDiffScale;
						bmp.scaleX = flipX ? -1 : 1;
						bmp.scaleY = flipY ? -1 : 1;
					}
				}

			case Link(fx, fy, tx, ty, color):
				initRender();

				g.lineStyle(1, color);
				g.moveTo(0,0);
				g.lineTo(tx-fx, ty-fy);

		}

		g.endFill();
	}


	inline function hideRender() {
		g.visible = wrapper.visible = false;
	}

	inline function initRender() {
		setSystemCursor();
		g.clear();
		g.visible = true;
		wrapper.removeChildren();
		wrapper.visible = true;
	}



	/** Request a render **/
	public inline function invalidateRender() invalidatedRender = true;


	/** Viewport changed **/
	function onViewportChange() {
		root.setScale( cam.adjustedZoom );
		label.f.setScale( 1/cam.adjustedZoom * settings.v.editorUiScale );
	}

	/** Mouse moved **/
	public inline function onMouseMove(m:Coords) {
		if( type!=None ) {
			root.x = M.round( cam.width*0.5 - cam.levelX * cam.adjustedZoom );
			root.y = M.round( cam.height*0.5 - cam.levelY * cam.adjustedZoom );

			switch type {
				case None,Forbidden,Pan,Move,Moving,PickNothing,Pointer,Add,Resize(_):
					centerLabelAbove(0,0);

				case Eraser(x, y):
					root.x += x*cam.adjustedZoom;
					root.y += y*cam.adjustedZoom;

				case GridCell(li, cx, cy, _), GridRect(li, cx, cy, _):
					root.x += ( li.pxTotalOffsetX + cx*li.def.gridSize ) * cam.adjustedZoom;
					root.y += ( li.pxTotalOffsetY + cy*li.def.gridSize ) * cam.adjustedZoom;
					centerLabelAbove(li.def.gridSize*0.5, 0);

				case Entity(li, def, ei, x, y):
					root.x += x*cam.adjustedZoom;
					root.y += y*cam.adjustedZoom;
					var w = ei==null ? def.width : ei.width;
					var h = ei==null ? def.height : ei.height;
					centerLabelAbove( ( 0.5-def.pivotX )*w, (0-def.pivotY)*h );

				case Tiles(li, tileIds, cx, cy, flips):
					root.x += ( li.pxTotalOffsetX + cx*li.def.gridSize ) * cam.adjustedZoom;
					root.y += ( li.pxTotalOffsetY + cy*li.def.gridSize ) * cam.adjustedZoom;
					centerLabelAbove(li.def.gridSize*0.5, 0);

				case Link(fx, fy, tx, ty, color):
					root.x += fx*cam.adjustedZoom;
					root.y += fy*cam.adjustedZoom;

			}
			// root.x += m.levelX*cam.adjustedZoom;
			// root.y += m.levelY*cam.adjustedZoom;
			App.ME.debug("moved "+m,true);
		}
	}


	inline function setSystemCursor( c:hxd.Cursor = Default ) {
		hxd.System.setCursor(c);
	}


	inline function setNativeCursor(id:String) {
		setSystemCursor( hxd.Cursor.CustomCursor.getNativeCursor(id) );
	}

	public inline function overrideNativeCursor(id:String) {
		setNativeCursor(id);
	}

	inline function setResizeCursor(p:RectHandlePos) {
		setNativeCursor(switch p {
			case Top: "n-resize";
			case Bottom: "s-resize";
			case Left: "w-resize";
			case Right: "e-resize";
			case TopLeft: "nw-resize";
			case TopRight: "ne-resize";
			case BottomLeft: "sw-resize";
			case BottomRight: "se-resize";
		});
	}

	public inline function update() {
		if( invalidatedRender ) {
			invalidatedRender = false;
			render();
		}
	}
}