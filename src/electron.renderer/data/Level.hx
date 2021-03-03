package data;

class Level {
	var _project : Project;

	@:allow(data.Project)
	public var uid(default,null) : Int;
	public var identifier(default,set): String;
	public var worldX : Int;
	public var worldY : Int;
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Array<data.inst.LayerInstance> = [];
	public var fieldInstances : Map<Int, data.inst.FieldInstance> = new Map();

	public var externalRelPath: Null<String>;

	public var bgRelPath: Null<String>;
	public var bgPos: Null<ldtk.Json.BgImagePos>;
	public var bgPivotX: Float;
	public var bgPivotY: Float;

	@:allow(ui.modal.panel.LevelInstancePanel)
	var bgColor : Null<UInt>;

	public var worldCenterX(get,never) : Int;
		inline function get_worldCenterX() return dn.M.round( worldX + pxWid*0.5 );

	public var worldCenterY(get,never) : Int;
		inline function get_worldCenterY() return dn.M.round( worldY + pxHei*0.5 );


	@:allow(data.Project)
	private function new(project:Project, wid:Int, hei:Int, uid:Int) {
		this.uid = uid;
		worldX = worldY = 0;
		pxWid = wid;
		pxHei = hei;
		bgPivotX = 0.5;
		bgPivotY = 0.5;
		this._project = project;
		this.identifier = "Level"+uid;
		this.bgColor = null;

		for(ld in _project.defs.layers)
			layerInstances.push( new data.inst.LayerInstance(_project, uid, ld.uid) );
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	@:keep public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '.$identifier(#$uid)';
	}

	public function toJson() : ldtk.Json.LevelJson {
		// List nearby levels
		var neighbours = switch _project.worldLayout {
			case Free, GridVania:
				var nears = _project.levels.filter( (ol)->
					ol!=this && getBoundsDist(ol)==0
					&& !( ( ol.worldX>=worldX+pxWid || ol.worldX+ol.pxWid<=worldX )
						&& ( ol.worldY>=worldY+pxHei || ol.worldY+ol.pxHei<=worldY )
					)
				);
				nears.map( (l)->{
					var dir = l.worldX>=worldX+pxWid ? "e"
						: l.worldX+l.pxWid<=worldX ? "w"
						: l.worldY+l.pxHei<=worldY ? "n"
						: "s";
					return {
						levelUid: l.uid,
						dir: dir,
					}
				});

			case LinearHorizontal, LinearVertical:
				var idx = dn.Lib.getArrayIndex(this, _project.levels);
				var nears = [];
				if( idx<_project.levels.length-1 )
					nears.push({
						levelUid: _project.levels[idx+1].uid,
						dir: _project.worldLayout==LinearHorizontal?"e":"s",
					});
				if( idx>0 )
					nears.push({
						levelUid: _project.levels[idx-1].uid,
						dir: _project.worldLayout==LinearHorizontal?"w":"n",
					});
				nears;
		}

		// Json
		return {
			identifier: identifier,
			uid: uid,
			worldX: worldX,
			worldY: worldY,
			pxWid: pxWid,
			pxHei: pxHei,
			__bgColor: JsonTools.writeColor( getBgColor() ),
			bgColor: JsonTools.writeColor(bgColor, true),

			bgRelPath: bgRelPath,
			bgPos: JsonTools.writeEnum(bgPos, true),
			bgPivotX: JsonTools.writeFloat(bgPivotX),
			bgPivotY: JsonTools.writeFloat(bgPivotY),

			__bgPos: {
				var bg = getBgTileInfos();
				if( bg==null )
					null;
				else {
					topLeftPx: [ bg.dispX, bg.dispY ],
					scale: [ bg.sx, bg.sy ],
					cropRect: [
						bg.tx, bg.ty,
						bg.tw, bg.th,
					],
				}
			},

			externalRelPath: null, // is only set upon actual saving, if project uses externalLevels option
			fieldInstances: {
				var all = [];
				for(fi in fieldInstances)
					all.push( fi.toJson() );
				all;
			},
			layerInstances: layerInstances.map( li->li.toJson() ),
			__neighbours: neighbours,
		}
	}

	public function makeExternalRelPath(idx:Int) {
		return
			_project.getRelExternalFilesDir() + "/"
			+ (dn.Lib.leadingZeros(idx,Const.LEVEL_FILE_LEADER_ZEROS)+"-")
			+ identifier
			+ "." + Const.LEVEL_EXTENSION;
	}

	public static function fromJson(p:Project, json:ldtk.Json.LevelJson) {
		var wid = JsonTools.readInt( json.pxWid, p.defaultLevelWidth );
		var hei = JsonTools.readInt( json.pxHei, p.defaultLevelHeight );
		var l = new Level( p, wid, hei, JsonTools.readInt(json.uid) );
		l.worldX = JsonTools.readInt( json.worldX, 0 );
		l.worldY = JsonTools.readInt( json.worldY, 0 );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);
		l.bgColor = JsonTools.readColor(json.bgColor, true);
		l.externalRelPath = json.externalRelPath;

		l.bgRelPath = json.bgRelPath;
		l.bgPos = JsonTools.readEnum(ldtk.Json.BgImagePos, json.bgPos, true);
		l.bgPivotX = JsonTools.readFloat(json.bgPivotX, 0.5);
		l.bgPivotY = JsonTools.readFloat(json.bgPivotY, 0.5);

		l.layerInstances = [];
		if( json.layerInstances!=null ) // external levels
			for( layerJson in JsonTools.readArray(json.layerInstances) ) {
				var li = data.inst.LayerInstance.fromJson(p, layerJson);
				l.layerInstances.push(li);
			}

		if( json.fieldInstances!=null )
			for( fieldJson in JsonTools.readArray(json.fieldInstances)) {
				var fi = data.inst.FieldInstance.fromJson(p,fieldJson);
				l.fieldInstances.set(fi.defUid, fi);
			}

		return l;
	}

	public inline function hasBgImage() {
		return bgRelPath!=null;
	}

	public function getBgTileInfos() : Null<{ imgData:data.DataTypes.CachedImage, tx:Float, ty:Float, tw:Float, th:Float, dispX:Int, dispY:Int, sx:Float, sy:Float }> {
		if( !hasBgImage() )
			return null;

		var data = _project.getOrLoadImage(bgRelPath);
		if( data==null )
			return null;

		var baseTileWid = data.pixels.width;
		var baseTileHei = data.pixels.height;
		var sx = 1.0;
		var sy = 1.0;
		switch bgPos {
			case null:
				throw "bgPos should not be null";

			case Unscaled:

			case Contain:
				sx = sy = M.fmin( pxWid/baseTileWid, pxHei/baseTileHei );

			case Cover:
				sx = sy = M.fmax( pxWid/baseTileWid, pxHei/baseTileHei );

			case CoverDirty:
				sx = pxWid / baseTileWid;
				sy = pxHei/ baseTileHei;
		}

		// Crop tile
		var subTileWid = M.fmin(baseTileWid, pxWid/sx);
		var subTileHei = M.fmin(baseTileHei, pxHei/sy);

		return {
			imgData: data,
			tx: bgPivotX * (baseTileWid-subTileWid),
			ty: bgPivotY * (baseTileHei-subTileHei),
			tw: subTileWid,
			th: subTileHei,
			dispX: Std.int( bgPivotX * (pxWid - subTileWid*sx) ),
			dispY: Std.int( bgPivotY * (pxHei - subTileHei*sy) ),
			sx: sx,
			sy: sy,
		}
	}


	public function createBgBitmap(?p:h2d.Object) : Null<h2d.Bitmap> {
		var bgInf = getBgTileInfos();
		if( bgInf==null )
			return null;

		var t = h2d.Tile.fromTexture( bgInf.imgData.tex );
		t = t.sub(bgInf.tx, bgInf.ty, bgInf.tw, bgInf.th);

		var bmp = new h2d.Bitmap(t,p);
		bmp.x = bgInf.dispX;
		bmp.y = bgInf.dispY;
		bmp.scaleX = bgInf.sx;
		bmp.scaleY = bgInf.sy;

		return bmp;
	}


	public inline function getBgColor() : UInt {
		return bgColor!=null ? bgColor : _project.defaultLevelBgColor;
	}

	public inline function inBounds(levelX:Int, levelY:Int) {
		return levelX>=0 && levelX<pxWid && levelY>=0 && levelY<pxHei;
	}

	public inline function inBoundsWorld(worldX:Float, worldY:Float) {
		return worldX>=this.worldX
			&& worldX<this.worldX+pxWid
			&& worldY>=this.worldY
			&& worldY<this.worldY+pxHei;
	}

	public function isWorldOver(wx:Int, wy:Int, padding=0) {
		return
			wx>=worldX-padding && wx<worldX+pxWid+padding
			&& wy>=worldY-padding && wy<worldY+pxHei+padding;
	}

	public function getDist(wx:Int, wy:Int) : Float {
		if( isWorldOver(wx,wy) )
			return 0;
		else {
			if( wy>=worldY && wy<worldY+pxHei ) // Distance to left or right sides
				return M.imin( M.iabs(worldX-wx), M.iabs(wx-(worldX+pxWid)) );
			else if( wx>=worldX && wx<worldX+pxWid ) // Distance to top or bottom sides
				return M.imin( M.iabs(worldY-wy), M.iabs(wy-(worldY+pxHei)) );
			else // Distances to corners
				return M.fmin(
					M.fmin( M.dist(wx,wy,worldX,worldY), M.dist(wx,wy,worldX+pxWid-1,worldY) ),
					M.fmin( M.dist(wx,wy,worldX,worldY+pxHei-1), M.dist(wx,wy,worldX+pxWid-1,worldY+pxHei-1) )
				);
		}
	}

	public function getBoundsDist(l:Level) : Int {
		return dn.M.imax(
			dn.M.imax(0, worldX - (l.worldX+l.pxWid)) + dn.M.imax( 0, l.worldX - (worldX+pxWid) ),
			dn.M.imax(0, worldY - (l.worldY+l.pxHei)) + dn.M.imax( 0, l.worldY - (worldY+pxHei) )
		);
	}

	public inline function touches(l:Level) {
		return l!=null
			&& l!=this
			&& dn.Lib.rectangleTouches(worldX, worldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei);
	}

	public inline function overlaps(l:Level) {
		return l!=null
			&& l!=this
			&& dn.Lib.rectangleOverlaps(worldX, worldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei);
	}

	public function overlapsAnyLevel() {
		for(l in _project.levels)
			if( overlaps(l) )
				return true;

		return false;
	}

	public function willOverlapAnyLevel(newWorldX:Int, newWorldY:Int) {
		for(l in _project.levels)
			if( l!=this && dn.Lib.rectangleOverlaps(newWorldX, newWorldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei) )
				return true;

		return false;
	}

	public function getLayerInstance(?layerDefUid:Int, ?layerDef:data.def.LayerDef) : data.inst.LayerInstance {
		if( layerDefUid==null && layerDef==null )
			throw "Need 1 parameter";

		if( layerDefUid==null )
			layerDefUid = layerDef.uid;

		for(li in layerInstances)
			if( li.layerDefUid==layerDefUid )
				return li;

		throw "Missing layer instance for "+layerDefUid;
	}

	public function getLayerInstanceFromRule(r:data.def.AutoLayerRuleDef) {
		var ld = _project.defs.getLayerDefFromRule(r);
		return ld!=null ? getLayerInstance(ld) : null;
	}

	public function getLayerInstanceFromEntity(?ei:data.inst.EntityInstance, ?ed:data.def.EntityDef) : Null<data.inst.LayerInstance> {
		if( ei==null && ed==null )
			return null;

		for(li in layerInstances)
		for(e in li.entityInstances)
			if( ei!=null && e==ei || ed!=null && e.defUid==ed.uid )
				return li;

		return null;
	}

	public function tidy(p:Project) {
		_project = p;

		// Remove layerInstances without layerDefs
		var i = 0;
		while( i<layerInstances.length )
			if( layerInstances[i].def==null ) {
				App.LOG.add("tidy", 'Removed lost layer instance in $this');
				layerInstances.splice(i,1);
			}
			else
				i++;

		// Create missing layerInstances & check if they're sorted in the same order as defs
		for(i in 0..._project.defs.layers.length)
			if( i>=layerInstances.length || layerInstances[i].layerDefUid!=_project.defs.layers[i].uid ) {
				var existing = new Map();
				for(li in layerInstances)
					existing.set(li.layerDefUid, li);
				layerInstances = [];
				for(ld in _project.defs.layers)
					if( existing.exists(ld.uid) )
						layerInstances.push( existing.get(ld.uid) );
					else {
						App.LOG.add("tidy", 'Added missing layer instance ${ld.identifier} in $this');
						layerInstances.push( new data.inst.LayerInstance(_project, uid, ld.uid) );
					}
				break;
			}

		// Tidy layer instances
		for(li in layerInstances)
			li.tidy(_project);


		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null ) {
				App.LOG.add("tidy", 'Removed lost fieldInstance in $this');
				fieldInstances.remove(e.key);
			}

		// Create missing field instances
		for(fd in p.defs.levelFields)
			getFieldInstance(fd);

		for(fi in fieldInstances)
			fi.tidy(_project);
	}


	public function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		for(li in layerInstances)
			li.applyNewBounds(newPxLeft, newPxTop, newPxWid, newPxHei);
		pxWid = newPxWid;
		pxHei = newPxHei;

		// Remove entities out of bounds
		var n = 0;
		for(li in layerInstances) {
			var i = 0;
			var ei = null;
			while( i<li.entityInstances.length ) {
				ei = li.entityInstances[i];
				if( !inBounds(ei.x, ei.y) ) {
					App.LOG.general('Removed out-of-bounds entity ${ei.def.identifier} in $li');
					li.entityInstances.splice(i,1);
					n++;
				}
				else
					i++;
			}
		}
		if( n>0 )
			N.warning( L.t._("::n:: entity(ies) deleted during resizing!", { n:n }) );

		_project.tidy();
	}


	public inline function hasAnyError() {
		return getFirstError()==null;
	}

	public function getFirstError() : Null<LevelError> {
		for(li in layerInstances)
			switch li.def.type {
				case IntGrid:
				case Entities:
					for(ei in li.entityInstances)
						if( ei.hasAnyFieldError() )
							return InvalidEntityField(ei);

				case Tiles:
				case AutoLayer:
			}

		if( bgRelPath!=null && !_project.isImageLoaded(bgRelPath) )
			return InvalidBgImage;

		return null;
	}



	/* CUSTOM FIELDS *******************/

	/** Get (and automatically creates) a field instance **/
	public function getFieldInstance(fd:data.def.FieldDef) : data.inst.FieldInstance{
		if( !fieldInstances.exists(fd.uid) )
			fieldInstances.set( fd.uid, new data.inst.FieldInstance(_project, fd.uid) );
		return fieldInstances.get(fd.uid);
	}


	public function getSmartColor(bright:Bool) {
		for(fi in fieldInstances) {
			if( fi.def.type==F_Color )
				for(i in 0...fi.getArrayLength())
					if( !fi.valueIsNull(i) )
						return bright ? dn.Color.toWhite(fi.getColorAsInt(i), 0.5) : fi.getColorAsInt(i);
		}
		return bright ? dn.Color.toWhite(getBgColor(), 0.5) : getBgColor();
	}

	public function hasAnyFieldDisplayedAt(pos:ldtk.Json.FieldDisplayPosition) {
		for(fi in fieldInstances)
			if( fi.def.editorAlwaysShow || !fi.isUsingDefault(0) ) {
				switch fi.def.editorDisplayMode {
					case ValueOnly, NameAndValue:
						if( fi.def.editorDisplayPos==pos )
							return true;

					case Hidden:
					case EntityTile:
					case Points:
					case PointStar:
					case PointPath, PointPathLoop:
					case RadiusPx:
					case RadiusGrid:
				}
			}
		return false;
	}


	/* RENDERING *******************/

	public function iterateLayerInstancesInRenderOrder( eachLayer:data.inst.LayerInstance->Void ) {
		var i = _project.defs.layers.length-1;
		while( i>=0 ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i--;
		}
	}
}
