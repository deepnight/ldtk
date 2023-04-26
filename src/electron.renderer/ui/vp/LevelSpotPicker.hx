package ui.vp;

private typedef LinearInsertPoint = {
	var levelIid : String;
	var idx : Int;
	var coord : Int;
}

class LevelSpotPicker extends ui.ValuePicker<Coords> {
	var initialWorldMode = false;
	var insertCursor : h2d.Graphics;

	public function new() {
		super();

		setInstructions("Pick a spot for a new level");

		initialWorldMode = editor.worldMode;
		if( !editor.worldMode ) {
			editor.setWorldMode(true);
			editor.camera.fit();
		}

		insertCursor = new h2d.Graphics();
		editor.worldRender.root.add(insertCursor, Const.DP_UI);
	}

	override function onDispose() {
		super.onDispose();

		insertCursor.remove();
		insertCursor = null;
	}

	override function onGlobalEvent(ev:GlobalEvent) {
		super.onGlobalEvent(ev);

		switch ev {
			case WorldMode(active):
				if( !active )
					cancel();

			case LevelSelected(_), WorldSelected(_):
				cancel();

			case _:
		}
	}


	public static function tryToCreateLevelAt(project:data.Project, world:data.World, m:Coords) {
		var b = getLevelInsertBounds(project, world, m);
		if( b!=null ) {
			var l : data.Level = switch world.worldLayout {
				case Free, GridVania:
					var l = world.createLevel();
					l.worldX = M.round(b.x);
					l.worldY = M.round(b.y);
					l.pxWid = b.wid;
					l.pxHei = b.hei;
					l.worldDepth = Editor.ME.curWorldDepth;
					l;

				case LinearHorizontal, LinearVertical:
					var i = getLinearInsertPoint(project, world, m);
					if( i!=null ) {
						var l = world.createLevel(i.idx);
						l;
					}
					else
						null;
			}
			if( l!=null ) {
				N.msg("New level created");
				world.reorganizeWorld();
				Editor.ME.ge.emit( LevelAdded(l) );
				Editor.ME.selectLevel(l);
				Editor.ME.camera.scrollToLevel(l);
			}
			return true;
		}
		else
			return false;
	}



	/**
		Get linear layout insert point from given Coords
	**/
	public static function getLinearInsertPoint(project:data.Project, world:data.World, m:Coords, ?movedLevel:data.Level, ?movedLevelInitialCoord:Int) : Null<LinearInsertPoint> {
		if( world.levels.length<=1 && movedLevel!=null )
			return null;

		// Init possible insert points in linear modes
		var pts : Array<LinearInsertPoint> =
			switch world.worldLayout {
				case Free, GridVania: null;

				case LinearHorizontal:
					var idx = 0;
					var all : Array<LinearInsertPoint> = world.levels.map( (l)->{ levelIid:l.iid, coord:l==movedLevel ? movedLevelInitialCoord : l.worldX, idx:idx++ } );
					var last = world.levels[world.levels.length-1];
					if( movedLevel==null || last!=movedLevel)
						all.push({ levelIid:last.iid, coord:last.worldX+last.pxWid, idx:idx });
					all;

				case LinearVertical:
					var idx = 0;
					var all : Array<LinearInsertPoint> = world.levels.map( (l)->{ levelIid:l.iid, coord:l==movedLevel ? movedLevelInitialCoord : l.worldY, idx:idx++ } );
					var last = world.levels[world.levels.length-1];
					if( movedLevel==null || last!=movedLevel)
						all.push({ levelIid:last.iid, coord:last.worldY+last.pxHei, idx:idx });
					all;
			}

		var dh = new dn.DecisionHelper(pts);
		switch world.worldLayout {
			case Free, GridVania:
				// N/A

			case LinearHorizontal:
				dh.score( (i)->return -M.fabs(m.worldX-i.coord) );

			case LinearVertical:
				dh.score( (i)->return -M.fabs(m.worldY-i.coord) );
		}
		return dh.getBest();
	}


	static inline function boundsOverlaps(l:data.Level, x,y,w,h) {
		return dn.Lib.rectangleOverlaps( x, y, w, h, l.worldX, l.worldY, l.pxWid, l.pxHei );
	}


	/**
		Return a valid level insertion spot near Coords, or null if none.
	**/
	public static function getLevelInsertBounds(project:data.Project, world:data.World, m:Coords) {
		var wid = world.defaultLevelWidth;
		var hei = world.defaultLevelHeight;

		var b = {
			x : m.worldX-wid*0.5,
			y : m.worldY-hei*0.5,
			wid: wid,
			hei: hei,
			overlaps: false,
		}

		// Find a spot in world space
		switch world.worldLayout {
			case Free, GridVania:

				if( world.getLevelAt(m.worldX, m.worldY)!=null )
					b.overlaps = true;
				else {
					// Deinterlace with existing levels
					for(l in world.levels)
						if( boundsOverlaps( l, b.x, b.y, b.wid, b.hei ) ) {
							// Source: https://stackoverflow.com/questions/1585525/how-to-find-the-intersection-point-between-a-line-and-a-rectangle
							var slope = ( (b.y+b.hei*0.5)-l.worldCenterY )  /  ( (b.x+b.wid*0.5)-l.worldCenterX );
							if( slope*l.pxWid*0.5 >= -l.pxHei*0.5  &&  slope*l.pxWid*0.5 <= l.pxHei*0.5 )
								if( b.x < l.worldCenterX )
									b.x = l.worldX-b.wid;
								else
									b.x = l.worldX+l.pxWid;
							else {
								if( b.y < l.worldCenterY )
									b.y = l.worldY-b.hei;
								else
									b.y = l.worldY+l.pxHei;
							}
						}

					// Deinterlace failed
					for(l in world.levels)
						if( boundsOverlaps(l, b.x, b.y, b.wid, b.hei) ) {
							b.overlaps = true;
							break;
						}
				}


				// Grid snapping
				if( world.worldLayout==GridVania ) {
					b.x = dn.M.round( b.x/world.worldGridWidth ) * world.worldGridWidth;
					b.y = dn.M.round( b.y/world.worldGridHeight ) * world.worldGridHeight;
				}
				else if( App.ME.settings.v.grid ) {
					b.x = dn.M.round( b.x/project.defaultGridSize ) * project.defaultGridSize;
					b.y = dn.M.round( b.y/project.defaultGridSize ) * project.defaultGridSize;
				}

			case LinearHorizontal:
				var i = getLinearInsertPoint(project, world, m);
				if( i!=null) {
					b.x = i.coord-b.wid*0.5;
					b.y = -b.hei*0.1;
					b.hei += Std.int(b.hei*0.2);
				}
				else
					return null;

			case LinearVertical:
				var i = getLinearInsertPoint(project, world, m);
				if( i!=null) {
					b.x = -b.wid*0.1;
					b.y = i.coord -b.hei*0.5;
					b.wid += Std.int(b.wid*0.2);
				}
				else
					return null;

		}


		return b;
	}



	override function shouldCancelLeftClickEventAt(m:Coords):Bool {
		return true;
	}

	override function onMouseMoveCursor(ev:hxd.Event, m:Coords) {
		super.onMouseMoveCursor(ev, m);
		ev.cancel = true;
		editor.cursor.set(Add);


		// Preview "add level" location
		var bounds = getLevelInsertBounds(project, curWorld, m);
		insertCursor.visible = bounds!=null;
		if( bounds!=null ) {
			var c = bounds.overlaps ? 0xff4400 : 0x8dcbfb;
			insertCursor.clear();
			insertCursor.lineStyle(2*editor.camera.pixelRatio, c, 0.7);
			insertCursor.beginFill(c, 0.3);
			insertCursor.drawRect(bounds.x, bounds.y, bounds.wid, bounds.hei);

			var radius = M.fmin(bounds.wid,bounds.hei) * 0.2;
			insertCursor.lineStyle(10*editor.camera.pixelRatio, c, 1);
			insertCursor.moveTo(bounds.x+bounds.wid*0.5, bounds.y+bounds.hei*0.5-radius); // vertical
			insertCursor.lineTo(bounds.x+bounds.wid*0.5, bounds.y+bounds.hei*0.5+radius);

			insertCursor.moveTo(bounds.x+bounds.wid*0.5-radius, bounds.y+bounds.hei*0.5); // horizontal
			insertCursor.lineTo(bounds.x+bounds.wid*0.5+radius, bounds.y+bounds.hei*0.5);
			editor.cursor.set(Add);
		}
		else
			editor.cursor.set(Forbidden);
		ev.cancel = true;
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);
		ev.cancel = true;
	}

	function goBackToSource() {
		if( editor.worldMode!=initialWorldMode )
			editor.setWorldMode( initialWorldMode );
	}

	override function onPick(m:Coords) {
		super.onPick(m);
		tryToCreateLevelAt(project, curWorld, m);
	}

	override function pickAt(m:Coords) {
		var ip = getLevelInsertBounds(project, curWorld, m);
		if( ip==null || ip.overlaps )
			return null;
		else
			return m;
	}


	override function isValidPick(c:Coords):Bool {
		return getLevelInsertBounds(project, curWorld, c) != null;
	}
}