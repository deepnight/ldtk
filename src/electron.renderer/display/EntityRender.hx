package display;

typedef CoreRender = {
	var wrapper : h2d.Object;
	var g : h2d.Graphics;
}

class EntityRender extends dn.Process {
	var ei : data.inst.EntityInstance;
	var ed(get,never) : data.def.EntityDef; inline function get_ed() return ei.def;
	var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;

	var ld : data.def.LayerDef;

	var core: h2d.Object;
	var _coreRender : Null<CoreRender>;

	// Field wrappers
	var identifier: Null<h2d.Text>;
	var above: h2d.Flow;
	var center: h2d.Flow;
	var beneath: h2d.Flow;
	var fieldGraphics : h2d.Graphics;

	var coreInvalidated = true;
	var layoutInvalidated = true;
	var fieldsRenderInvalidated = true;


	public function new(inst:data.inst.EntityInstance, layerDef:data.def.LayerDef, parent:h2d.Object) {
		super(Editor.ME);

		createRoot(parent);
		ei = inst;
		ld = layerDef;

		core = new h2d.Object(root);

		above = new h2d.Flow(root);
		above.layout = Vertical;
		above.horizontalAlign = Middle;

		center = new h2d.Flow(root);
		center.layout = Vertical;
		center.horizontalAlign = Middle;

		beneath = new h2d.Flow(root);
		beneath.layout = Vertical;
		beneath.horizontalAlign = Middle;

		fieldGraphics = new h2d.Graphics(root);

		renderAll();
	}

	override function onDispose() {
		super.onDispose();
		ei = null;
		ld = null;
		above = null;
		beneath = null;
		center = null;
		fieldGraphics = null;
		core = null;
	}


	public function onGlobalEvent(ev:GlobalEvent) {
		switch( ev ) {
			case WorldMode(false):
				renderAll();

			case LayerDefRemoved(defUid):
				if( ld.uid==defUid )
					destroy();

			case WorldLevelMoved(_), WorldSettingsChanged, LayerInstanceSelected(_), LevelSelected(_):
				renderAll();

			case EntityDefChanged:
				coreInvalidated = true;
				fieldsRenderInvalidated = true;
				layoutInvalidated = true;

			case ViewportChanged(zoomChanged):
				if( zoomChanged ) {
					coreInvalidated = true;
					fieldsRenderInvalidated = true;
				}
				layoutInvalidated = true;

			case _:
		}
	}


	function updateCore() {
		core.removeChildren();
		_coreRender = renderCore(ei, ed, ld);
		core.addChild( _coreRender.wrapper );
	}


	public static function renderCore(?ei:data.inst.EntityInstance, ?ed:data.def.EntityDef, ?ld:data.def.LayerDef) : CoreRender {
		if( ei==null && ed==null )
			throw "Need at least 1 parameter";

		if( ei!=null && ed!=null )
			ed = null;

		if( ed==null )
			ed = ei.def;


		var w = ei!=null ? ei.width : ed.width;
		var h = ei!=null ? ei.height : ed.height;
		var color = ei!=null ? ei.getSmartColor(false) : ed.color;

		var wrapper = new h2d.Object();

		var g = new h2d.Graphics(wrapper);
		g.x = Std.int( -w*ed.pivotX + (ld!=null ? ld.pxOffsetX : 0) );
		g.y = Std.int( -h*ed.pivotY + (ld!=null ? ld.pxOffsetY : 0) );

		var zoomScale = 1 / Editor.ME.camera.adjustedZoom;

		// Render a tile
		function _renderTile(rect:ldtk.Json.TilesetRect, mode:ldtk.Json.EntityTileRenderMode) {
			if( rect==null || Editor.ME.project.defs.getTilesetDef(rect.tilesetUid)==null ) {
				// Missing tile
				var p = 2;
				g.lineStyle(3*zoomScale, 0xff0000);
				g.moveTo(p,p);
				g.lineTo(w-p, h-p);
				g.moveTo(w-p, p);
				g.lineTo(p, h-p);
			}
			else {
				// Bounding box
				if( !ed.hollow )
					g.beginFill(color, ed.fillOpacity);
				g.lineStyle(1*zoomScale, C.toWhite(color, 0.3), ed.lineOpacity);
				g.drawRect(0, 0, w, h);

				// Texture
				var td = Editor.ME.project.defs.getTilesetDef(rect.tilesetUid);
				var t = td.getTileRect(rect);
				var alpha = ed.tileOpacity;
				switch mode {
					case Stretch:
						var bmp = new h2d.Bitmap(t, wrapper);
						if( ld!=null )
							bmp.setPosition(ld.pxOffsetX, ld.pxOffsetY);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

						bmp.scaleX = w / bmp.tile.width;
						bmp.scaleY = h / bmp.tile.height;

					case FitInside:
						var bmp = new h2d.Bitmap(t, wrapper);
						if( ld!=null )
							bmp.setPosition(ld.pxOffsetX, ld.pxOffsetY);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

						var s = M.fmin(w / bmp.tile.width, h / bmp.tile.height);
						bmp.setScale(s);

					case Repeat:
						var tt = new dn.heaps.TiledTexture(w,h, t, wrapper);
						tt.alpha = alpha;
						tt.x = -w*ed.pivotX + (ld==null ? 0 : ld.pxOffsetX);
						tt.y = -h*ed.pivotY + (ld==null ? 0 : ld.pxOffsetY);

					case Cover:
						var bmp = new h2d.Bitmap(wrapper);
						bmp.alpha = alpha;
						if( ld!=null )
							bmp.setPosition(ld.pxOffsetX, ld.pxOffsetY);

						var s = M.fmax(w / t.width, h / t.height);
						final fw = M.fmin(w, t.width*s) / s;
						final fh = M.fmin(h, t.height*s) / s;
						bmp.tile = t.sub(
							t.width*ed.pivotX - fw*ed.pivotX,
							t.height*ed.pivotY - fh*ed.pivotY,
							fw,fh
						);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.setScale(s);

					case FullSizeCropped:
						var bmp = new h2d.Bitmap(wrapper);
						if( ld!=null )
							bmp.setPosition(ld.pxOffsetX, ld.pxOffsetY);
						final fw = M.fmin(w, t.width);
						final fh = M.fmin(h, t.height);
						bmp.tile = t.sub(
							t.width*ed.pivotX - fw*ed.pivotX,
							t.height*ed.pivotY - fh*ed.pivotY,
							fw, fh
						);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

					case FullSizeUncropped:
						var bmp = new h2d.Bitmap(t, wrapper);
						if( ld!=null )
							bmp.setPosition(ld.pxOffsetX, ld.pxOffsetY);

						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

					case NineSlice:
						var sg = new h2d.ScaleGrid(
							t,
							ed.nineSliceBorders[3], ed.nineSliceBorders[0], ed.nineSliceBorders[1], ed.nineSliceBorders[2],
							wrapper
						);
						sg.alpha = ed.tileOpacity;
						sg.tileBorders = true;
						sg.tileCenter = true;
						sg.width = w;
						sg.height = h;
						sg.x = -w*ed.pivotX + (ld==null ? 0 : ld.pxOffsetX);
						sg.y = -h*ed.pivotY + (ld==null ? 0 : ld.pxOffsetY);

				}
			}
		}

		// Base render
		var smartTile = ei==null ? ed.getDefaultTile() : ei.getSmartTile();
		if( smartTile!=null ) {
			// Tile (from either Def or a field)
			_renderTile(smartTile, ed.tileRenderMode);
		}
		else
			switch ed.renderMode {
			case Rectangle, Ellipse:
				if( !ed.hollow )
					g.beginFill(color, ed.fillOpacity);
				g.lineStyle(1*zoomScale, C.toWhite(color, 0.3), ed.lineOpacity);
				switch ed.renderMode {
					case Rectangle:
						g.drawRect(0, 0, w, h);

					case Ellipse:
						g.drawEllipse(w*0.5, h*0.5, w*0.5, h*0.5, 0, w<=16 || h<=16 ? 16 : 0);

					case _:
				}
				g.endFill();

			case Cross:
				g.lineStyle(5*zoomScale, color, ed.lineOpacity);
				g.moveTo(0,0);
				g.lineTo(w, h);
				g.moveTo(0,h);
				g.lineTo(w, 0);

			case Tile:
				// Render should be done through getSmartTile() method above, but if tile is invalid, we land here
				_renderTile(null, FitInside);
			}

		// Pivot
		g.lineStyle(0);
		g.beginFill(0x0, 0.4);
		g.drawRect(w*ed.pivotX-1, h*ed.pivotY-1, 3,3);
		g.beginFill(color, 1);
		g.drawRect(w*ed.pivotX, h*ed.pivotY, 1,1);

		return {
			wrapper: wrapper,
			g: g,
		}
	}


	public function renderAll() {
		coreInvalidated = false;
		layoutInvalidated = false;
		fieldsRenderInvalidated = false;
		updateCore();
		renderFields();
	}


	public function renderFields() {

		fieldGraphics.clear();

		// Attach fields
		var color = ei.getSmartColor(false);
		var ctx : display.FieldInstanceRender.FieldRenderContext = EntityCtx(fieldGraphics, ei, ld);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Above ).map( fd->ei.getFieldInstance(fd,true) ),
			color, ctx, above
		);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Center ).map( fd->ei.getFieldInstance(fd,true) ),
			color, ctx, center
		);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Beneath ).map( fd->ei.getFieldInstance(fd,true) ),
			color, ctx, beneath
		);


		// Render ref links from entities in different levels
		for(refEi in ei._project.getEntityInstancesReferingTo(ei)) {
			if( refEi._li.level==ei._li.level )
				continue;

			var fi = refEi.getEntityRefFieldTo(ei,true);
			if( fi==null || !fi.def.refLinkIsDisplayed() )
				continue;

			var col = refEi.getSmartColor(false);
			var refX = refEi.getWorldRefAttachX(fi.def) - ei.worldX + refEi._li.pxTotalOffsetX;
			var refY = refEi.getWorldRefAttachY(fi.def) - ei.worldY + refEi._li.pxTotalOffsetY;
			var thisX = ei.getRefAttachX(fi.def) - ei.x + ei._li.pxTotalOffsetX;
			var thisY = ei.getRefAttachY(fi.def) - ei.y + ei._li.pxTotalOffsetY;
			FieldInstanceRender.renderRefLink(
				fieldGraphics, col, refX, refY, thisX, thisY, 1,
				fi.def.editorLinkStyle,
				ei.isInSameSpaceAs(refEi) ? Full : CutAtTarget
			);
		}

		// Identifier label
		if( ei.def.showName && identifier==null )
			identifier = new h2d.Text(Assets.getRegularFont(), root);
		else if( !ei.def.showName && identifier!=null ) {
			identifier.remove();
			identifier = null;
		}
		if( ei.def.showName ) {
			var col = ei.getSmartColor(true);
			identifier.filter = FieldInstanceRender.createFilter(col);
			identifier.textColor = col;
			identifier.text = ed.identifier.substr(0,16);
		}

		updateLayout();
	}

	public function updateLayout() {
		var zoomScale = 1 / Editor.ME.camera.adjustedZoom;
		final maxFieldsWid = ei.width*1.5 * settings.v.editorUiScale;
		final maxFieldsHei = ei.height*1.5 * settings.v.editorUiScale;

		root.x = ei.x;
		root.y = ei.y;

		final fullVis = ei._li==Editor.ME.curLayerInstance;
		core.alpha = fullVis ? 1 : ei._li.def.inactiveOpacity;

		// Graphics
		if( !fullVis && ei._li.def.hideFieldsWhenInactive )
			fieldGraphics.visible = false;
		else {
			fieldGraphics.visible = true;
			fieldGraphics.alpha = fullVis ? 1 : ei._li.def.inactiveOpacity;
		}


		// Identifier
		if( identifier!=null ) {
			identifier.visible = fullVis || !ei._li.def.hideFieldsWhenInactive;
			identifier.setScale(zoomScale);
			identifier.x = Std.int( -ei.width*ed.pivotX - identifier.textWidth*0.5*identifier.scaleX + ei.width*0.5 );
			identifier.y = Std.int( -identifier.textHeight*identifier.scaleY - ei.height*ed.pivotY );
		}

		// Update field wrappers
		var showFields = fullVis || !ei._li.def.hideFieldsWhenInactive;
		above.visible = showFields && above.numChildren>0;
		if( above.visible ) {
			above.setScale(zoomScale);
			above.x = M.round( -ei.width*ed.pivotX - above.outerWidth*0.5*above.scaleX + ei.width*0.5 );
			above.y = Std.int( -above.outerHeight*above.scaleY - ei.height*ed.pivotY );
			if( identifier!=null )
				above.y -= identifier.textHeight*identifier.scaleY;
			above.alpha = 1;
		}

		center.visible = showFields && center.numChildren>0;
		if( center.visible ) {
			center.setScale(zoomScale);
			center.x = Std.int( -ei.width*ed.pivotX - center.outerWidth*0.5*center.scaleX + ei.width*0.5 );
			center.y = Std.int( -ei.height*ed.pivotY - center.outerHeight*0.5*center.scaleY + ei.height*0.5);
			center.alpha = 1;
		}

		beneath.visible = showFields && beneath.numChildren>0;
		if( beneath.visible ) {
			beneath.setScale(zoomScale);
			beneath.x = Std.int( -ei.width*ed.pivotX - beneath.outerWidth*0.5*beneath.scaleX + ei.width*0.5 );
			beneath.y = Std.int( ei.height*(1-ed.pivotY) );
			beneath.alpha = 1;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( fieldsRenderInvalidated && !cd.has("fieldsRenderLimit") ) {
			cd.setS("fieldsRenderLimit", 0.20);
			renderFields();
			fieldsRenderInvalidated = false;
		}

		if( layoutInvalidated && !cd.has("layoutLimit") ) {
			cd.setS("layoutLimit", 0.03);
			updateLayout();
			layoutInvalidated = false;
		}

		if( coreInvalidated && !cd.has("coreLimit") ) {
			cd.setS("coreLimit", 0.15);
			updateCore();
			updateLayout(); // for core alpha
			coreInvalidated = false;
			layoutInvalidated = false;
		}

	}
}
