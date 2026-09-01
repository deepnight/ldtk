package display;

typedef TilePreviewAnimation = {
	var frames : Array<Int>;
	var durationsMs : Array<Float>;
	var loop : Bool;
	var totalDurationMs : Float;
}

typedef TilePreviewAnimationCache = {
	var signature : String;
	var byTile : Map<Int,TilePreviewAnimation>;
	var animations : Array<TilePreviewAnimation>;
}

class LayerRender {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;

	public var root(default,null) : Null<h2d.Object>;
	var mask : Null<h2d.Mask>;
	var entityRenders : Array<EntityRender> = [];

	var lastLi : Null<data.inst.LayerInstance>;

	static var _animationCaches : Map<Int,TilePreviewAnimationCache> = new Map();
	static var _animationTimer : Null<haxe.Timer>;
	static var _animationLastStampMs = 0.;
	static var _animationElapsedMs = 0.;
	static var _animationNextRefreshStampMs = 0.;
	static var _animationLastLevelId : Null<Int>;


	public function new() {}


	public function dispose() {
		clear();

		if( mask!=null ) {
			mask.remove();
			mask = null;
		}

		root.remove();
		root = null;


		entityRenders = null;
	}

	public function onGlobalEvent(ev:GlobalEvent) {
		for(er in entityRenders)
			er.onGlobalEvent(ev);

		switch( ev ) {
			case ViewportChanged(zoomChanged):
				updateParallax();

			case LayerDefChanged(defUid, contentInvalidated):
				if( lastLi!=null && lastLi.layerDefUid==defUid )
					updateParallax();

			case TilesetMetaDataChanged(td), TilesetDefChanged(td), TilesetImageLoaded(td,_):
				_animationCaches.remove(td.uid);
				_animationNextRefreshStampMs = 0;

			case TilesetDefRemoved(td):
				_animationCaches.remove(td.uid);

			case _:
		}
	}


	function updateParallax() {
		if( lastLi==null )
			return;

		root.x = editor.camera.getParallaxOffsetX(lastLi);
		root.y = editor.camera.getParallaxOffsetY(lastLi);
		root.setScale( lastLi.def.getScale() );
	}


	static function _readFloat(obj:Dynamic, names:Array<String>) : Null<Float> {
		if( obj==null )
			return null;
		for(name in names) {
			var value = Reflect.field(obj, name);
			if( value==null )
				continue;
			var parsed = Std.parseFloat(Std.string(value));
			if( !Math.isNaN(parsed) )
				return parsed;
		}
		return null;
	}

	static function _readInt(obj:Dynamic, names:Array<String>) : Null<Int> {
		if( obj==null )
			return null;
		for(name in names) {
			var value = Reflect.field(obj, name);
			if( value==null )
				continue;
			var parsed = Std.parseInt(Std.string(value));
			if( parsed!=null )
				return parsed;
		}
		return null;
	}

	static function _readBool(obj:Dynamic, names:Array<String>, fallback:Bool) : Bool {
		if( obj==null )
			return fallback;
		for(name in names) {
			var value = Reflect.field(obj, name);
			if( value==null )
				continue;
			if( Std.isOfType(value, Bool) )
				return value;
			var str = Std.string(value).toLowerCase();
			if( str=="true" || str=="1" || str=="yes" )
				return true;
			if( str=="false" || str=="0" || str=="no" )
				return false;
		}
		return fallback;
	}

	static function _buildAnimationSignature(td:data.def.TilesetDef) : String {
		var buf = new StringBuf();
		buf.add(td.cWid);
		buf.add("x");
		buf.add(td.cHei);
		buf.add("|");
		for(tileId in 0...td.cWid*td.cHei) {
			var custom = td.getTileCustomData(tileId);
			if( custom!=null ) {
				buf.add(tileId);
				buf.add("=");
				buf.add(custom);
				buf.add(";");
			}
		}
		return buf.toString();
	}

	static function _parseAnimation(td:data.def.TilesetDef, baseTileId:Int, raw:String) : Null<TilePreviewAnimation> {
		var root : Dynamic = null;
		try root = haxe.Json.parse(raw) catch(_:Dynamic) return null;
		if( root==null )
			return null;

		var nested = Reflect.field(root, "animation");
		var anim : Dynamic = nested;
		if( anim==null || Std.isOfType(anim, Bool) )
			anim = root;

		var rawFrames = Reflect.field(anim, "frames");
		if( rawFrames==null ) rawFrames = Reflect.field(anim, "tileIds");
		if( rawFrames==null ) rawFrames = Reflect.field(anim, "animationFrames");
		var frameCount = _readInt(anim, ["frameCount", "count"]);
		var hasAnimationConfig = nested!=null
			|| _readBool(root, ["animated"], false)
			|| rawFrames!=null
			|| frameCount!=null;
		if( !hasAnimationConfig )
			return null;

		var frames : Array<Int> = [];
		var durations : Array<Float> = [];
		var relativeFrames = _readBool(anim, ["relativeFrames", "relative"], false);

		if( rawFrames!=null && Std.isOfType(rawFrames, Array) ) {
			for(frameValue in (cast rawFrames:Array<Dynamic>)) {
				var tileId = Std.parseInt(Std.string(frameValue));
				var duration : Null<Float> = null;
				if( tileId==null ) {
					tileId = _readInt(frameValue, ["tileId", "id", "tid"]);
					duration = _readFloat(frameValue, ["durationMs", "frameDurationMs", "duration"]);
				}
				if( tileId==null )
					continue;
				if( relativeFrames )
					tileId += baseTileId;
				if( tileId<0 || tileId>=td.cWid*td.cHei )
					continue;
				frames.push(tileId);
				durations.push(duration==null ? 0 : duration);
			}
		}
		else if( frameCount!=null && frameCount>1 ) {
			var startTileId = _readInt(anim, ["startTileId", "start"]);
			if( startTileId==null )
				startTileId = baseTileId;
			var stride = _readInt(anim, ["frameStride", "stride"]);
			if( stride==null || stride==0 )
				stride = 1;
			for(i in 0...frameCount) {
				var tileId = startTileId + i*stride;
				if( tileId>=0 && tileId<td.cWid*td.cHei ) {
					frames.push(tileId);
					durations.push(0);
				}
			}
		}

		if( frames.length<2 )
			return null;

		var rawDurations = Reflect.field(anim, "frameDurationsMs");
		if( rawDurations==null ) rawDurations = Reflect.field(anim, "durationsMs");
		if( rawDurations!=null && Std.isOfType(rawDurations, Array) ) {
			var arr : Array<Dynamic> = cast rawDurations;
			for(i in 0...durations.length)
				if( i<arr.length ) {
					var parsed = Std.parseFloat(Std.string(arr[i]));
					if( !Math.isNaN(parsed) && parsed>0 )
						durations[i] = parsed;
				}
		}

		var defaultDuration = _readFloat(anim, ["frameDurationMs", "durationMs", "frameMs"]);
		var fps = _readFloat(anim, ["fps"]);
		if( (defaultDuration==null || defaultDuration<=0) && fps!=null && fps>0 )
			defaultDuration = 1000/fps;
		if( defaultDuration==null || defaultDuration<=0 )
			defaultDuration = 100;
		for(i in 0...durations.length)
			if( durations[i]<=0 )
				durations[i] = defaultDuration;

		var modeValue = Reflect.field(anim, "mode");
		var mode = modeValue==null ? "" : Std.string(modeValue).toLowerCase();
		if( (mode=="pingpong" || mode=="ping-pong") && frames.length>2 ) {
			var i = frames.length-2;
			while( i>0 ) {
				frames.push(frames[i]);
				durations.push(durations[i]);
				i--;
			}
		}

		var total = 0.;
		for(duration in durations)
			total += duration;
		if( total<=0 )
			return null;

		return {
			frames: frames,
			durationsMs: durations,
			loop: _readBool(anim, ["loop"], true),
			totalDurationMs: total,
		};
	}

	static function _getAnimationCache(td:data.def.TilesetDef, refreshSignature:Bool) : TilePreviewAnimationCache {
		_ensureAnimationTimer();
		var cache = _animationCaches.get(td.uid);
		var signature : Null<String> = null;
		if( refreshSignature || cache==null )
			signature = _buildAnimationSignature(td);

		if( cache==null || refreshSignature && cache.signature!=signature ) {
			var byTile : Map<Int,TilePreviewAnimation> = new Map();
			var animations : Array<TilePreviewAnimation> = [];
			for(tileId in 0...td.cWid*td.cHei) {
				var custom = td.getTileCustomData(tileId);
				if( custom==null )
					continue;
				var animation = _parseAnimation(td, tileId, custom);
				if( animation==null )
					continue;
				animations.push(animation);
				if( !byTile.exists(tileId) )
					byTile.set(tileId, animation);
				for(frameId in animation.frames)
					if( !byTile.exists(frameId) )
						byTile.set(frameId, animation);
			}
			cache = {
				signature: signature==null ? _buildAnimationSignature(td) : signature,
				byTile: byTile,
				animations: animations,
			};
			_animationCaches.set(td.uid, cache);
		}
		return cache;
	}

	static function _resolveAnimatedTileId(td:data.def.TilesetDef, tileId:Int) : Int {
		var cache = _getAnimationCache(td, false);
		var animation = cache.byTile.get(tileId);
		if( animation==null )
			return tileId;

		var localTime = _animationElapsedMs;
		if( animation.loop )
			localTime = localTime % animation.totalDurationMs;
		else if( localTime>=animation.totalDurationMs )
			return animation.frames[animation.frames.length-1];

		var boundary = 0.;
		for(i in 0...animation.frames.length) {
			boundary += animation.durationsMs[i];
			if( localTime<boundary )
				return animation.frames[i];
		}
		return animation.frames[animation.frames.length-1];
	}

	static function _getNextAnimationDelay(cache:TilePreviewAnimationCache) : Float {
		var best = 1000.;
		var found = false;
		for(animation in cache.animations) {
			var localTime = _animationElapsedMs;
			if( animation.loop )
				localTime = localTime % animation.totalDurationMs;
			else if( localTime>=animation.totalDurationMs )
				continue;

			var boundary = 0.;
			for(duration in animation.durationsMs) {
				boundary += duration;
				if( localTime<boundary ) {
					best = M.fmin(best, boundary-localTime);
					found = true;
					break;
				}
			}
		}
		return found ? best : 250;
	}

	static function _ensureAnimationTimer() {
		if( _animationTimer!=null )
			return;
		_animationLastStampMs = haxe.Timer.stamp()*1000;
		_animationTimer = new haxe.Timer(16);
		_animationTimer.run = _onAnimationTimer;
	}

	static function _onAnimationTimer() {
		var now = haxe.Timer.stamp()*1000;
		var dt = now-_animationLastStampMs;
		_animationLastStampMs = now;

		if( !page.Editor.exists() )
			return;
		var ed = page.Editor.ME;
		if( ed.worldMode || ed.curLevel==null )
			return;

		if( _animationLastLevelId!=ed.curLevelId ) {
			_animationLastLevelId = ed.curLevelId;
			_animationElapsedMs = 0;
			_animationNextRefreshStampMs = 0;
		}
		else
			_animationElapsedMs += M.fclamp(dt, 0, 250);

		if( now<_animationNextRefreshStampMs )
			return;

		var anyAnimated = false;
		var nextDelay = 1000.;
		var checkedTilesets : Map<Int,Bool> = new Map();
		for(li in ed.curLevel.layerInstances) {
			if( !ed.levelRender.isLayerVisible(li) )
				continue;
			if( li.def.type!=Tiles && !li.def.isAutoLayer() )
				continue;
			var td = li.getTilesetDef();
			if( td==null || !td.isAtlasLoaded() )
				continue;
			var cache = _getAnimationCache(td, true);
			if( cache.animations.length==0 )
				continue;

			anyAnimated = true;
			ed.levelRender.invalidateLayer(li, null, false);
			if( !checkedTilesets.exists(td.uid) ) {
				checkedTilesets.set(td.uid, true);
				nextDelay = M.fmin(nextDelay, _getNextAnimationDelay(cache));
			}
		}

		_animationNextRefreshStampMs = now + ( anyAnimated ? M.fclamp(nextDelay,16,1000) : 250 );
	}

	static inline function _isActiveLevelPreview(li:data.inst.LayerInstance) : Bool {
		return page.Editor.exists()
			&& !page.Editor.ME.worldMode
			&& page.Editor.ME.curLevel!=null
			&& page.Editor.ME.curLevel.getLayerInstance(li.def)==li;
	}

	static inline function _getPreviewTileById(td:data.def.TilesetDef, tileId:Int, enabled:Bool) : h2d.Tile {
		return td.getTileById( enabled ? _resolveAnimatedTileId(td, tileId) : tileId );
	}

	static inline function _getPreviewTileAtSource(td:data.def.TilesetDef, pxX:Int, pxY:Int, enabled:Bool) : h2d.Tile {
		if( !enabled )
			return td.getOptimizedTileAt(pxX, pxY);
		var tileId = td.getTileId(td.xToCx(pxX), td.yToCy(pxY));
		return td.getTileById(_resolveAnimatedTileId(td, tileId));
	}


	static var _cachedIdentityVector = new h3d.Vector4(1,1,1,1);
	public static inline function renderAutoTileInfos(li:data.inst.LayerInstance, td:data.def.TilesetDef, tileInfos, tg:h2d.TileGroup, previewAnimatedTiles=false) {
		_cachedIdentityVector.a = tileInfos.a;
		@:privateAccess tg.content.addTransform(
			tileInfos.x + ( ( dn.M.hasBit(tileInfos.flips,0)?1:0 ) + li.def.tilePivotX ) * li.def.gridSize + li.pxTotalOffsetX,
			tileInfos.y + ( ( dn.M.hasBit(tileInfos.flips,1)?1:0 ) + li.def.tilePivotY ) * li.def.gridSize + li.pxTotalOffsetY,
			dn.M.hasBit(tileInfos.flips,0)?-1:1,
			dn.M.hasBit(tileInfos.flips,1)?-1:1,
			0,
			_cachedIdentityVector,
			_getPreviewTileAtSource(td, tileInfos.srcX, tileInfos.srcY, previewAnimatedTiles)
		);
	}


	public static inline function renderGridTile(li:data.inst.LayerInstance, td:data.def.TilesetDef, tileInf:data.DataTypes.GridTileInfos, cx:Int, cy:Int, tg:h2d.TileGroup, previewAnimatedTiles=false) {
		var t = _getPreviewTileById(td, tileInf.tileId, previewAnimatedTiles);
		t.setCenterRatio(li.def.tilePivotX, li.def.tilePivotY);
		var sx = M.hasBit(tileInf.flips, 0) ? -1 : 1;
		var sy = M.hasBit(tileInf.flips, 1) ? -1 : 1;
		var tx = (cx + li.def.tilePivotX + (sx<0?1:0)) * li.def.gridSize + li.pxTotalOffsetX;
		var ty = (cy + li.def.tilePivotX + (sy<0?1:0)) * li.def.gridSize + li.pxTotalOffsetY;
		tg.addTransform(tx, ty, sx, sy, 0, t);
	}

	public function render(li:data.inst.LayerInstance, renderAutoLayers=true, ?target:h2d.Object, previewAnimatedTiles=true) {
		previewAnimatedTiles = previewAnimatedTiles && _isActiveLevelPreview(li);

		// Cleanup
		if( root!=null )
			clear();
		lastLi = li;

		// Init root
		if( root==null )
			root = new h2d.Object(target);
		else if( target!=null && root.parent!=target )
			target.addChild(root);


		// Init mask
		switch li.def.type {
			case IntGrid, Tiles, AutoLayer:
				if( mask==null )
					mask = new h2d.Mask(li.pxWid, li.pxHei, root);

			case Entities:
				if( mask!=null ) {
					mask.remove();
					mask = null;
				}
		}
		if( mask!=null ) {
			mask.width = li.pxWid;
			mask.height = li.pxHei;
		}

		var renderTarget = mask!=null ? mask : root;

		switch li.def.type {
		case IntGrid, AutoLayer:
			var td = li.getTilesetDef();

			if( li.def.isAutoLayer() && renderAutoLayers && td!=null && td.isAtlasLoaded() ) {
				var ed = td.getTagsEnumDef();

				// Auto-layer tiles
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, renderTarget);
				pixelGrid.x = li.pxTotalOffsetX;
				pixelGrid.y = li.pxTotalOffsetY;

				var tg = new h2d.TileGroup( td.getAtlasTile(), renderTarget);
				var gr = App.ME.settings.v.tileEnumOverlays ? new h2d.Graphics(renderTarget) : null;

				// If we're showing enums, dim the tileset slightly so the overlays stand out.
				if( App.ME.settings.v.tileEnumOverlays )
					tg.setDefaultColor(0xcccccc, .5);

				if( li.autoTilesCache==null )
					li.applyAllRules();

				li.def.iterateActiveRulesInDisplayOrder( li, (r)-> {
					if( li.autoTilesCache.exists( r.uid ) ) {
						var grid = li.def.gridSize;
						for(tilesArray in li.autoTilesCache.get( r.uid ))
						for(tileInfos in tilesArray) {
							// Tile
							renderAutoTileInfos(li, td, tileInfos, tg, previewAnimatedTiles);

							if( App.ME.settings.v.tileEnumOverlays && ed!=null ) {
								var n = 0;
								for( ev in ed.values) {
									if( td.hasTag(ev.id, tileInfos.tid)) {
										gr.lineStyle(1, ev.color, 1);
										gr.drawRect(
											tileInfos.x + li.def.tilePivotX*li.def.gridSize + li.pxTotalOffsetX,
											tileInfos.y + li.def.tilePivotY*li.def.gridSize + li.pxTotalOffsetY,
											li.def.gridSize - 1 - n * 2,
											li.def.gridSize - 1 - n * 2
										);
										n++;
									}
								}
							}
						}
					}
				});
			}
			else if( li.def.type==IntGrid ) {
				// Normal intGrid
				var pixelGrid = new dn.heaps.PixelGrid(li.def.gridSize, li.cWid, li.cHei, renderTarget);
				pixelGrid.x = li.pxTotalOffsetX;
				pixelGrid.y = li.pxTotalOffsetY;

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.hasIntGrid(cx,cy) )
						pixelGrid.setPixel( cx, cy, li.getIntGridColorAt(cx,cy) );
			}


		case Entities:
			// Entity layer
			for(ei in li.entityInstances)
				entityRenders.push( new EntityRender(ei, li.def, renderTarget) );


		case Tiles:
			// Classic tiles layer
			var offX = 2;
			var offY = 2;
			var td = li.getTilesetDef();
			if( td!=null && td.isAtlasLoaded() ) {
				var ed = td.getTagsEnumDef();
				var tg = new h2d.TileGroup( td.getAtlasTile(), renderTarget );
				var gr = App.ME.settings.v.tileEnumOverlays ? new h2d.Graphics(renderTarget) : null;

				// If we're showing enums, dim the tileset slightly so the overlays stand out.
				if( App.ME.settings.v.tileEnumOverlays )
					tg.setDefaultColor(0xcccccc, .5);

				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid) {
					if( !li.hasAnyGridTile(cx,cy) )
						continue;

					for( tileInf in li.getGridTileStack(cx,cy) ) {
						// Tile
						renderGridTile(li, td, tileInf, cx,cy, tg, previewAnimatedTiles);

						if( App.ME.settings.v.tileEnumOverlays && ed!=null ) {
							var n = 0;
							for( ev in ed.values) {
								if( td.hasTag(ev.id, tileInf.tileId)) {
									gr.lineStyle(1, ev.color, 1);
									gr.drawRect(
										(cx + li.def.tilePivotX)*li.def.gridSize + li.pxTotalOffsetX  +  n + .5,
										(cy + li.def.tilePivotY)*li.def.gridSize + li.pxTotalOffsetY  +  n + .5,
										li.def.gridSize - 1 - n * 2,
										li.def.gridSize - 1 - n * 2
									);
									n++;
								}
							}
						}
					}
				}
			}
			else {
				// Missing tileset
				var tileError = data.def.TilesetDef.makeErrorTile(li.def.gridSize);
				var tg = new h2d.TileGroup( tileError, renderTarget );
				for(cy in 0...li.cHei)
				for(cx in 0...li.cWid)
					if( li.hasAnyGridTile(cx,cy) )
						tg.add(
							(cx + li.def.tilePivotX) * li.def.gridSize,
							(cy + li.def.tilePivotX) * li.def.gridSize,
							tileError
						);
			}
		}
	}



	public function renderBgToTexture(l:data.Level, tex:h3d.mat.Texture) {
		tex.clear( l.getBgColor() );

		if( l.bgRelPath!=null ) {
			var bmp = l.createBgTiledTexture();
			if( bmp!=null )
				bmp.drawTo(tex);
		}
	}

	public function createBgPng(p:data.Project, l:data.Level) : Null<haxe.io.Bytes> {
		var tex = new h3d.mat.Texture(l.pxWid, l.pxHei, [Target]);
		renderBgToTexture(l, tex);
		return try tex.capturePixels().toPNG() catch(_) null;
	}


	/**
		Generate all PNGs for a single layer instance (auto-layer IntGrids generate both tiles & pixel images)
		Note: if `secondarySuffix` is null, then the output image is the "main" render of this layer.
	**/
	public function createPngs(p:data.Project, l:data.Level, li:data.inst.LayerInstance) : Array<{ secondarySuffix:Null<String>, bytes:haxe.io.Bytes, tex:Null<h3d.mat.Texture> }> {
		var out = [];
		switch li.def.type {
			case IntGrid, Tiles, AutoLayer:
				// Tiles
				if( li.def.isAutoLayer() || li.def.type==Tiles ) {
					render(li, true, null, false);
					var tex = new h3d.mat.Texture(l.pxWid, l.pxHei, [Target]);
					var wrapper = new h2d.Object();
					wrapper.addChild(root);
					root.alpha = li.def.displayOpacity; // apply layer alpha
					wrapper.drawTo(tex);
					var pixels = try tex.capturePixels() catch(_) null;
					out.push({
						secondarySuffix: null,
						bytes: pixels==null ? null : pixels.toPNG(),
						tex: tex,
					});
				}

				// Export IntGrid as pixel tiny image
				if( li.def.type==IntGrid ) {
					var pixels = hxd.Pixels.alloc(li.cWid, li.cHei, RGBA);
					for(cy in 0...li.cHei)
					for(cx in 0...li.cWid) {
						if( li.hasIntGrid(cx,cy) )
							pixels.setPixel( cx, cy, C.addAlphaF(li.getIntGridColorAt(cx,cy)) );
					}
					out.push({
						secondarySuffix: "int",
						bytes: pixels.toPNG(),
						tex: null,
					});
				}

			case Entities:
		}
		return out;
	}


	public function drawToTexture(tex:h3d.mat.Texture, p:data.Project, l:data.Level, li:data.inst.LayerInstance) : Bool {
		switch li.def.type {
		case IntGrid, Tiles, AutoLayer:
			if( li.def.isAutoLayer() || li.def.type==Tiles ) {
				// Tiles
				render(li, true, null, false);
				var wrapper = new h2d.Object();
				wrapper.addChild(root);
				root.alpha = li.def.displayOpacity; // apply layer alpha
				wrapper.drawTo(tex);
				return true;
			}
			else
				return false;

		case Entities:
			return false;
		}
	}


	public function clear() {
		for(er in entityRenders)
			er.destroy();
		entityRenders = [];

		root.removeChildren();
		mask = null;
	}

}
