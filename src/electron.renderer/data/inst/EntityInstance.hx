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
		return 'EntityInst "${def.identifier}" @$x,$y';
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

		var json : ldtk.Json.EntityInstanceJson = {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__grid: [ getCx(li.def), getCy(li.def) ],
			__pivot: [ JsonTools.writeFloat(def.pivotX), JsonTools.writeFloat(def.pivotY) ],
			__tags: def.tags.toArray(),
			__tile: getSmartTile(),
			__smartColor: C.intToHex( getSmartColor(false) ),

			iid: iid,
			width: width,
			height: height,
			defUid: defUid,
			px: [x,y],
			fieldInstances: {
				var all = [];
				for(fd in def.fieldDefs)
					all.push( getFieldInstance(fd,true).toJson() );
				all;
			}
		}

		// World coords
		switch _li.level._world.worldLayout {
			case Free, GridVania:
				json.__worldX = x + li.level.worldX;
				json.__worldY = y + li.level.worldY;

			case LinearHorizontal, LinearVertical:
		}

		return json;
	}

	public function toSimplifiedJson() : Dynamic {
		var customFields = {};
		for( fi in fieldInstances )
			Reflect.setField(customFields, fi.def.identifier, fi.toJson().__value);

		return {
			id: def.identifier,
			iid: iid,
			layer: _li.def.identifier,
			x : x,
			y : y,
			width: width,
			height: height,
			color: getSmartColor(false),
			customFields: customFields,
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

	public inline function getCx(ld:data.def.LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public inline function getCy(ld:data.def.LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public inline function getPointOriginX(ld:data.def.LayerDef) {
		return def.resizableX ? centerX : ( getCx(ld)+0.5 ) * ld.gridSize;
	}

	public inline function getPointOriginY(ld:data.def.LayerDef) {
		return def.resizableY ? centerY : ( getCy(ld)+0.5 ) * ld.gridSize;
	}

	public inline function getRefAttachX(fd:data.def.FieldDef) {
		return fd.editorDisplayMode==RefLinkBetweenCenters ? centerX : x;
	}
	public inline function getRefAttachY(fd:data.def.FieldDef) {
		return fd.editorDisplayMode==RefLinkBetweenCenters ? centerY : y;
	}

	public inline function getWorldRefAttachX(fd:data.def.FieldDef) {
		return _li.level.worldX + ( fd.editorDisplayMode==RefLinkBetweenCenters ? centerX : x );
	}
	public inline function getWorldRefAttachY(fd:data.def.FieldDef) {
		return _li.level.worldY + ( fd.editorDisplayMode==RefLinkBetweenCenters ? centerY : y );
	}

	final overShapePad = 3;
	final overEdgePad = 4;
	public inline function isOver(layerX:Int, layerY:Int) {
		if( M.fabs(layerX-x) > width+overEdgePad*2 || M.fabs(layerY-y) > height+overEdgePad*2 ) // Fast check
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

	public function getSmartColor(bright:Bool) : dn.Col {
		var c : Null<Int> = null;
		for(fd in def.fieldDefs) {
			c = getFieldInstance(fd,true).getSmartColor();
			if( c!=null )
				return c;
		}
		return bright ? dn.legacy.Color.toWhite(def.color, 0.5) : def.color;
	}

	public function getSmartTile() : Null<ldtk.Json.TilesetRect> {
		// Check for a tile provided by a field instance
		for(fd in def.fieldDefs) {
			var t = getFieldInstance(fd,true).getSmartTile();
			if( t!=null )
				return t;
		}

		return def.getDefaultTile();
	}


	public function isUsingTileset(td:data.def.TilesetDef) {
		if( def.tilesetId==td.uid )
			return true;

		for(fi in fieldInstances)
			if( fi.def.type==F_Tile && fi.def.tilesetUid==td.uid )
				return true;

		return false;
	}

	public inline function isInSameSpaceAs(ei:EntityInstance) {
		return ei!=null
			&& _li.level.worldDepth == ei._li.level.worldDepth
			&& _li.level.isInWorld(ei._li.level._world);
	}

	public function isOutOfLayerBounds() {
		return x<_li.pxTotalOffsetX || x>_li.pxTotalOffsetX+_li.cWid*_li.def.scaledGridSize
			|| y<_li.pxTotalOffsetY || y>_li.pxTotalOffsetY+_li.cHei*_li.def.scaledGridSize;
	}

	public function tidy(p:data.Project, li:LayerInstance) {
		_project = p;
		_li = li;
		_project.markIidAsUsed(iid);
		var anyChange = false;

		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null ) {
				App.LOG.add("tidy", 'Removed lost fieldInstance in $this');
				fieldInstances.remove(e.key);
			}

		// Create missing field instances
		for(fd in def.fieldDefs)
			getFieldInstance(fd,true);

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

	public function getFieldInstance(fieldDef:data.def.FieldDef, createIfMissing:Bool) {
		if( createIfMissing && !fieldInstances.exists(fieldDef.uid) )
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
	public inline function hasEntityRefTo(targetEi:EntityInstance, ?fd:data.def.FieldDef, onlyIfLinkIsDisplayed=false) {
		return getEntityRefFieldTo(targetEi, fd, onlyIfLinkIsDisplayed) != null;
	}


	/**
		Return TRUE if target EntityInstance has a reference to This in given field.
	**/
	public function getEntityRefFieldTo(targetEi:EntityInstance, ?onlyFd:data.def.FieldDef, onlyIfLinkIsDisplayed=false) : Null<FieldInstance> {
		if( onlyFd==null ) {
			// In any field
			for(fi in fieldInstances)
			for(i in 0...fi.getArrayLength())
				if( fi.getEntityRefIid(i)==targetEi.iid )
					return fi;
		}
		else {
			// In specified field
			if( onlyFd.type!=F_EntityRef )
				return null;

			var fi = getFieldInstance(onlyFd,false);
			if( fi==null )
				return null;

			for(i in 0...fi.getArrayLength())
				if( fi.getEntityRefIid(i)==targetEi.iid && ( !onlyIfLinkIsDisplayed || fi.def.refLinkIsDisplayed() ) )
					return fi;
		}
		return null;
	}



	/**
		Clear invalid asymmetrical refs between this EntityInstance and other ones
	**/
	public function tidyLostSymmetricalEntityRefs(fd:data.def.FieldDef, allowDeepSearch=true) {
		if( fd.type!=F_EntityRef || !fd.symmetricalRef )
			return;

		var fi = getFieldInstance(fd, false);
		if( fi==null )
			return;

		// Check own fields for lost symmetricals
		var i = 0;
		var needFieldsTidy = false;
		while( i<fi.getArrayLength() ) {
			if( fi.valueIsNull(i) )
				i++;
			else {
				var targetEi = fi.getEntityRefInstance(i);
				if( targetEi==null || !targetEi.hasEntityRefTo(this, fd) ) {
					fi.removeArrayValue(i);
					if( targetEi==null )
						_project.unregisterReverseIidRef(this, targetEi);
					else
						needFieldsTidy = true;
				}
				else
					i++;
			}
		}

		if( needFieldsTidy )
			_project.tidyFields();

		// Check entities pointing at me
		if( allowDeepSearch ) {
			var reverseReferers = _project.getEntityInstancesReferingTo(this);
			for( ei in reverseReferers )
				ei.tidyLostSymmetricalEntityRefs(fd, false);
		}
	}


}