package data.inst;

class EntityInstance {
	public var _project : Project;
	public var _li(default,null) : LayerInstance;
	public var def(get,never) : data.def.EntityDef; inline function get_def() return _project.defs.getEntityDef(defUid);

	public var iid : String;
	public var defUid(default,null) : Int;
	public var x : Int;
	public var y : Int;
	public var centerX(get,never) : Int;
	public var centerY(get,never) : Int;
	public var worldX(get,never) : Int;
	public var worldY(get,never) : Int;
	public var customWidth : Null<Int>;
	public var customHeight: Null<Int>;

	public var width(get,never) : Int;
		inline function get_width() return customWidth!=null ? customWidth : def.width;

	public var height(get,never) : Int;
		inline function get_height() return customHeight!=null ? customHeight : def.height;

	public var fieldInstances : Map<Int, data.inst.FieldInstance> = new Map();

	public var left(get,never) : Int; inline function get_left() return M.round( x - width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + width;
	public var top(get,never) : Int; inline function get_top() return M.round( y - height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + height;


	public function new(p:Project, li:LayerInstance, entityDefUid:Int, iid:String) {
		_project = p;
		_li = li;
		defUid = entityDefUid;
		this.iid = iid;
	}

	@:keep public function toString() {
		return 'Instance<${def.identifier}>@$x,$y';
	}

	inline function get_centerX() return M.round( x + (0.5-def.pivotX)*width );
	inline function get_centerY() return M.round( y + (0.5-def.pivotY)*height );

	inline function get_worldX() return Std.int( x + _li.level.worldX );
	inline function get_worldY() return Std.int( y + _li.level.worldY );

	public function toJson(li:data.inst.LayerInstance) : ldtk.Json.EntityInstanceJson {
		if( customWidth==def.width )
			customWidth = null;

		if( customHeight==def.height )
			customHeight = null;

		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__grid: [ getCx(li.def), getCy(li.def) ],
			__pivot: [ JsonTools.writeFloat(def.pivotX), JsonTools.writeFloat(def.pivotY) ],
			__tags: def.tags.toArray(),
			__tile: {
				var t = getSmartTile();
				if( t!=null ) {
					var td = _project.defs.getTilesetDef(t.tilesetUid);
					{
						tilesetUid: t.tilesetUid,
						srcRect: [ td.getTileSourceX(t.tileId), td.getTileSourceY(t.tileId), td.tileGridSize, td.tileGridSize ],
					}
				}
				else
					null;
			},

			iid: iid,
			width: width,
			height: height,
			defUid: defUid,
			px: [x,y],
			fieldInstances: {
				var all = [];
				for(fi in fieldInstances)
					all.push( fi.toJson() );
				all;
			}
		}
	}

	public static function fromJson(project:Project, li:LayerInstance, json:ldtk.Json.EntityInstanceJson) {
		if( (cast json).x!=null ) // Convert old coordinates
			json.px = [ JsonTools.readInt( (cast json).x, 0 ), JsonTools.readInt((cast json).y,0) ];

		if( (cast json).defId!=null ) // Convert renamed defId
			json.defUid = (cast json).defId;

		if( json.iid==null ) // Init IID
			json.iid = project.generateUniqueId_UUID();

		var ei = new EntityInstance(project, li, JsonTools.readInt(json.defUid), json.iid);
		ei.x = JsonTools.readInt( json.px[0], 0 );
		ei.y = JsonTools.readInt( json.px[1], 0 );

		ei.customWidth = JsonTools.readNullableInt( json.width );
		if( ei.customWidth==ei.def.width )
			ei.customWidth = null;

		ei.customHeight = JsonTools.readNullableInt( json.height );
		if( ei.customHeight==ei.def.height )
			ei.customHeight = null;

		for( fieldJson in JsonTools.readArray(json.fieldInstances) ) {
			var fi = FieldInstance.fromJson(project, fieldJson);
			ei.fieldInstances.set(fi.defUid, fi);
		}

		return ei;
	}

	public function getCx(ld:data.def.LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:data.def.LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getPointOriginX(ld:data.def.LayerDef) {
		return def.resizableX ? centerX : ( getCx(ld)+0.5 ) * ld.gridSize;
	}

	public function getPointOriginY(ld:data.def.LayerDef) {
		return def.resizableY ? centerY : ( getCy(ld)+0.5 ) * ld.gridSize;
	}

	final overEdgePad = 4;
	final overShapePad = 1;
	public inline function isOver(layerX:Int, layerY:Int) {
		if( M.fabs(layerX-x)>width || M.fabs(layerY-y)>height ) // Fast check
			return false;
		else if( def.renderMode==Ellipse ) {
			if( def.hollow ) {
				final rxIn2 = M.pow(width*0.5-overEdgePad, 2);
				final rxOut2 = M.pow(width*0.5+overEdgePad, 2);
				final ryIn2 = M.pow(height*0.5-overEdgePad, 2);
				final ryOut2 = M.pow(height*0.5+overEdgePad, 2);
				return
					M.pow(layerX-centerX, 2) * ryIn2 + M.pow(layerY-centerY, 2) * rxIn2 > rxIn2*ryIn2
					&& M.pow(layerX-centerX, 2) * ryOut2 + M.pow(layerY-centerY, 2) * rxOut2 <= rxOut2*ryOut2;
			}
			else {
				final rx2 = M.pow(width*0.5+overShapePad, 2);
				final ry2 = M.pow(height*0.5+overShapePad, 2);
				return M.pow(layerX-centerX, 2) * ry2 + M.pow(layerY-centerY, 2) * rx2 <= rx2*ry2;
			}
		}
		else if( def.hollow ) {
			return layerX >= left-overEdgePad && layerX<=right+overEdgePad && layerY>=top-overEdgePad && layerY<=bottom+overEdgePad
				&& !( layerX >= left+overEdgePad && layerX<=right-overEdgePad && layerY>=top+overEdgePad && layerY<=bottom-overEdgePad );
		}
		else
			return layerX>=left-overShapePad && layerX<=right+overShapePad && layerY>=top-overShapePad && layerY<=bottom+overShapePad;
	}

	public function getSmartColor(bright:Bool) {
		var c : Null<Int> = null;
		for(fd in def.fieldDefs) {
			c = getFieldInstance(fd).getSmartColor();
			if( c!=null )
				return c;
		}
		return bright ? dn.Color.toWhite(def.color, 0.5) : def.color;
	}

	public function getSmartTile() : Null<{ tilesetUid:Int, tileId:Int }> {
		for(fi in fieldInstances)
			switch fi.def.type {
				case F_Enum(enumDefUid):
					if( fi.def.editorDisplayMode==EntityTile && !fi.valueIsNull(0) ) {
						var ed = _project.defs.getEnumDef(enumDefUid);
						if( ed.iconTilesetUid!=null )
							return {
								tilesetUid: ed.iconTilesetUid,
								tileId: ed.getValue( fi.getEnumValue(0) ).tileId,
							}
					}
				case _:
			}

		if( def.isTileDefined() )
			return {
				tilesetUid: def.tilesetId,
				tileId: def.tileId,
			}
		else
			return null;
	}


	public function isUsingTileset(td:data.def.TilesetDef) {
		if( def.tilesetId==td.uid )
			return true;

		// TODO check future tile fields

		return false;
	}


	public function isOutOfLayerBounds() {
		return x<_li.pxTotalOffsetX || x>_li.pxTotalOffsetX+_li.cWid*_li.def.scaledGridSize
			|| y<_li.pxTotalOffsetY || y>_li.pxTotalOffsetY+_li.cHei*_li.def.scaledGridSize;
	}

	public function tidy(p:data.Project, li:LayerInstance) {
		_project = p;
		_li = li;
		var anyChange = false;

		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null ) {
				App.LOG.add("tidy", 'Removed lost fieldInstance in $this');
				fieldInstances.remove(e.key);
			}

		// Create missing field instances
		for(fd in def.fieldDefs)
			getFieldInstance(fd);

		for(fi in fieldInstances)
			fi.tidy(_project, li);

		return anyChange;
	}



	// ** FIELDS **********************************

	public function hasAnyFieldError() {
		for(fi in fieldInstances)
			if( fi.hasAnyErrorInValues(this) )
				return true;
		return false;
	}

	public function hasField(fieldDef:data.def.FieldDef) {
		return fieldInstances.exists(fieldDef.uid);
	}

	public function getFieldInstance(fieldDef:data.def.FieldDef) {
		if( !fieldInstances.exists(fieldDef.uid) )
			fieldInstances.set(fieldDef.uid, new data.inst.FieldInstance(_project, fieldDef.uid));
		return fieldInstances.get( fieldDef.uid );
	}

	public function getFieldInstancesOfType(type:ldtk.Json.FieldType) {
		var all = [];
		for(fi in fieldInstances)
			if( fi.def.type.getIndex() == type.getIndex() )
				all.push(fi);
		return all;
	}


	/**
		Return TRUE if target EntityInstance has a reference to This in given field.
	**/
	public function hasEntityRefTo(targetEi:EntityInstance, ?fd:data.def.FieldDef) {
		if( fd==null ) {
			// In any field
			for(fi in fieldInstances)
			for(i in 0...fi.getArrayLength())
				if( fi.getEntityRefIID(i)==targetEi.iid )
					return true;
		}
		else {
			// In specified field
			if( fd.type!=F_EntityRef )
				return false;

			var fi = getFieldInstance(fd);
			if( fi==null )
				return false;

			for(i in 0...fi.getArrayLength())
				if( fi.getEntityRefIID(i)==targetEi.iid )
					return true;
		}
		return false;
	}



	/**
		Clear invalid asymmetrical refs between this EntityInstance and other ones
	**/
	public function tidyLostSymmetricalEntityRefs(fd:data.def.FieldDef, allowDeepSearch=true) {
		if( fd.type!=F_EntityRef || !fd.symmetricalRef )
			return;

		var fi = getFieldInstance(fd);
		if( fi==null )
			return;

		// Check own fields for lost symmetricals
		var i = 0;
		while( i<fi.getArrayLength() ) {
			if( fi.valueIsNull(i) )
				i++;
			else {
				var targetEi = fi.getEntityRefInstance(i);
				if( !targetEi.hasEntityRefTo(this, fd) ) {
					_project.unregisterReverseIidRef(this, targetEi);
					fi.removeArrayValue(i);
				}
				else
					i++;
			}
		}

		// Check entities pointing at me
		if( allowDeepSearch ) {
			var reverseReferers = _project.getEntityInstancesReferingTo(this);
			for( ei in reverseReferers )
				ei.tidyLostSymmetricalEntityRefs(fd, false);
		}
	}


}