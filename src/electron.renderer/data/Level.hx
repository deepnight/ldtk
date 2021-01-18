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

	public var externalRelPath: Null<String>;

	public var bgRelPath: Null<String>;
	public var bgPos: Null<ldtk.Json.BgImagePos>;

	@:allow(ui.modal.panel.WorldPanel)
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
			__bgPos: null, // JSON export bgPos helper

			externalRelPath: null, // is only set upon actual saving, if project uses externalLevels option
			layerInstances: layerInstances.map( function(li) return li.toJson() ),
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
		var wid = JsonTools.readInt( json.pxWid, Project.DEFAULT_LEVEL_SIZE*p.defaultGridSize );
		var hei = JsonTools.readInt( json.pxHei, Project.DEFAULT_LEVEL_SIZE*p.defaultGridSize );
		var l = new Level( p, wid, hei, JsonTools.readInt(json.uid) );
		l.worldX = JsonTools.readInt( json.worldX, 0 );
		l.worldY = JsonTools.readInt( json.worldY, 0 );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);
		l.bgColor = JsonTools.readColor(json.bgColor, true);
		l.externalRelPath = json.externalRelPath;

		l.bgRelPath = json.bgRelPath;
		l.bgPos = JsonTools.readEnum(ldtk.Json.BgImagePos, json.bgPos, true);

		l.layerInstances = [];
		if( json.layerInstances!=null ) // external levels
			for( layerJson in JsonTools.readArray(json.layerInstances) ) {
				var li = data.inst.LayerInstance.fromJson(p, layerJson);
				l.layerInstances.push(li);
			}

		return l;
	}

	public inline function hasBgImage() {
		return bgRelPath!=null;
	}

	public function getBgImage() : Null<{ t:h2d.Tile, sx:Float, sy:Float }> {
		if( !hasBgImage() )
			return null;

		var data = _project.getImage(bgRelPath);
		if( data==null )
			return null;

		var t = h2d.Tile.fromTexture( data.tex );
		var sx = 1.0;
		var sy = 1.0;
		switch bgPos {
			case null:

			case Unscaled:

			case Contain:
				sx = sy = M.fmin( pxWid/t.width, pxHei/t.height );

			case Cover:
				sx = sy = M.fmax( pxWid/t.width, pxHei/t.height );

			case CoverDirty:
				sx = pxWid / t.width;
				sy = pxHei/ t.height;
		}
		// Crop
		t = t.sub(
			0, 0,
			M.fmin(t.width, pxWid/sx),
			M.fmin(t.height, pxHei/sy)
		);
		return {
			t: t,
			sx: sx,
			sy: sy,
		}
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

	public function isWorldOver(wx:Int, wy:Int) {
		return wx>=worldX && wx<worldX+pxWid && wy>=worldY && wy<worldY+pxHei;
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
	}


	public function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		for(li in layerInstances)
			li.applyNewBounds(newPxLeft, newPxTop, newPxWid, newPxHei);
		pxWid = newPxWid;
		pxHei = newPxHei;
		_project.tidy();
	}


	public function hasAnyError() {
		for(li in layerInstances)
			switch li.def.type {
				case IntGrid:
				case Entities:
					for(ei in li.entityInstances)
						if( ei.hasAnyFieldError() )
							return true;

				case Tiles:
				case AutoLayer:
			}

		return false;
	}



	/** RENDERING *******************/

	public function iterateLayerInstancesInRenderOrder( eachLayer:data.inst.LayerInstance->Void ) {
		var i = _project.defs.layers.length-1;
		while( i>=0 ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i--;
		}
	}
}
