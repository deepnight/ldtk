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
	var above: h2d.Flow;
	var center: h2d.Flow;
	var beneath: h2d.Flow;
	var fieldGraphics : h2d.Graphics;

	var layoutInvalidated = true;


	public function new(inst:data.inst.EntityInstance, layerDef:data.def.LayerDef, p:h2d.Object) {
		super(Editor.ME);

		createRoot(p);
		ei = inst;
		ld = layerDef;

		fieldGraphics = new h2d.Graphics(root);
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
			case ViewportChanged, WorldLevelMoved(_), WorldSettingsChanged:
				layoutInvalidated = true;

			case LayerInstanceSelected:
				layoutInvalidated = true;

			case _:
		}
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

		// Render a tile
		function renderTile(tilesetId:Null<Int>, tileId:Null<Int>, mode:ldtk.Json.EntityTileRenderMode) {
			if( tileId==null || tilesetId==null ) {
				// Missing tile
				var p = 2;
				g.lineStyle(3, 0xff0000);
				g.moveTo(p,p);
				g.lineTo(w-p, h-p);
				g.moveTo(w-p, p);
				g.lineTo(p, h-p);
			}
			else {
				g.beginFill(color, 0.2*ed.fillOpacity);
				g.drawRect(0, 0, w, h);

				var td = Editor.ME.project.defs.getTilesetDef(tilesetId);
				var t = td.getTile(tileId);
				var alpha = ed.fillOpacity * (ed.hollow ? 0.15 : 1);
				switch mode {
					case Stretch:
						var bmp = new h2d.Bitmap(t, wrapper);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

						bmp.scaleX = w / bmp.tile.width;
						bmp.scaleY = h / bmp.tile.height;

					case FitInside:
						var bmp = new h2d.Bitmap(t, wrapper);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
						bmp.alpha = alpha;

						var s = M.fmin(w / bmp.tile.width, h / bmp.tile.height);
						bmp.setScale(s);

					case Repeat:
						var tt = new dn.heaps.TiledTexture(t, w,h, wrapper);
						tt.alpha = alpha;
						tt.x = -w*ed.pivotX;
						tt.y = -h*ed.pivotY;

					case Cover:
						var bmp = new h2d.Bitmap(t, wrapper);
						bmp.alpha = alpha;

						var s = M.fmax(w / bmp.tile.width, h / bmp.tile.height);
						bmp.setScale(s);
						bmp.tile = bmp.tile.sub(
							0, 0,
							M.fmin( bmp.tile.width*s, w ) / s,
							M.fmin( bmp.tile.height*s, h ) / s
						);
						bmp.tile.setCenterRatio(ed.pivotX, ed.pivotY);
				}
			}
		}

		// Base render
		var custTile = ei==null ? null : ei.getSmartTile();
		if( custTile!=null )
			renderTile(custTile.tilesetUid, custTile.tileId, ed.tileRenderMode);
		else
			switch ed.renderMode {
			case Rectangle, Ellipse:
				if( !ed.hollow )
					g.beginFill(color, ed.fillOpacity);
				g.lineStyle(1, C.toWhite(color, 0.3), ed.lineOpacity);
				switch ed.renderMode {
					case Rectangle:
						g.drawRect(0, 0, w, h);

					case Ellipse:
						g.drawEllipse(w*0.5, h*0.5, w*0.5, h*0.5, 0, w<=16 || h<=16 ? 16 : 0);

					case _:
				}
				g.endFill();

			case Cross:
				g.lineStyle(5, color, ed.lineOpacity);
				g.moveTo(0,0);
				g.lineTo(w, h);
				g.moveTo(0,h);
				g.lineTo(w, 0);

			case Tile:
				renderTile(ed.tilesetId, ed.tileId, ed.tileRenderMode);
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
		core.removeChildren();
		_coreRender = renderCore(ei, ed, ld);
		core.addChild( _coreRender.wrapper );

		renderFields();
	}


	public function renderFields() {
		above.removeChildren();
		center.removeChildren();
		beneath.removeChildren();
		fieldGraphics.clear();

		// Attach fields
		var color = ei.getSmartColor(true);
		var ctx : display.FieldInstanceRender.FieldRenderContext = EntityCtx(fieldGraphics, ei, ld);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Above ).map( fd->ei.getFieldInstance(fd) ),
			color, ctx, above
		);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Center ).map( fd->ei.getFieldInstance(fd) ),
			color, ctx, center
		);
		FieldInstanceRender.renderFields(
			ei.def.fieldDefs.filter( fd->fd.editorDisplayPos==Beneath ).map( fd->ei.getFieldInstance(fd) ),
			color, ctx, beneath
		);

		for(refEi in ei._project.getEntityInstancesReferingTo(ei)) {
			if( refEi._li.level==ei._li.level )
				continue;

			var col = refEi.getSmartColor(true);
			var fx = ( refEi.getPointOriginX(ld) + refEi._li.level.worldX ) - ei.worldX;
			var fy = ( refEi.getPointOriginY(ld) + refEi._li.level.worldY ) - ei.worldY;
			var tx = ei.getPointOriginX(ld) - ei.x;
			var ty = ei.getPointOriginY(ld) - ei.y;
			FieldInstanceRender.renderRefLink(fieldGraphics, col, fx,fy, tx,ty);
		}

		// Identifier label
		if( ei.def.showName ) {
			var f = new h2d.Flow(above);
			f.minWidth = above.innerWidth;
			f.horizontalAlign = Middle;
			f.padding = 2;
			var tf = new h2d.Text(Assets.getRegularFont(), f);
			tf.smooth = true;
			tf.scale(settings.v.editorUiScale);
			tf.textColor = ei.getSmartColor(true);
			tf.text = ed.identifier.substr(0,16);
			tf.x = Std.int( ei.width*0.5 - tf.textWidth*tf.scaleX*0.5 );
			tf.y = 0;
			FieldInstanceRender.addBg(f, ei.getSmartColor(true), 0.95);
		}

		updateLayout();
	}

	public inline function updateLayout() {
		layoutInvalidated = false;
		var cam = Editor.ME.camera;
		var downScale = M.fclamp( (3-cam.adjustedZoom)*0.3, 0, 0.8 );
		var scale = (1-downScale) / cam.adjustedZoom;
		final alpha = 1.0;
		final maxFieldsWid = ei.width*1.5;
		final maxFieldsHei = ei.height*1.5;

		root.x = ei.x;
		root.y = ei.y;

		final fullVis = ei._li==Editor.ME.curLayerInstance;

		// Base
		if( _coreRender!=null ) {
			_coreRender.wrapper.alpha = fullVis ? 1 : 0.8;
			_coreRender.g.alpha = fullVis ? 1 : 0.5;
		}

		// Graphics
		fieldGraphics.alpha = fullVis ? 1 : 0.2;


		// Update field wrappers
		above.visible = center.visible = beneath.visible = fullVis;
		if( above.visible ) {
			above.setScale( M.fmin(scale, maxFieldsWid/above.outerWidth) );
			above.x = Std.int( -ei.width*ed.pivotX - above.outerWidth*0.5*above.scaleX + ei.width*0.5 );
			above.y = Std.int( -above.outerHeight*above.scaleY - ei.height*ed.pivotY - 2 );
			above.alpha = alpha;

			center.setScale( M.fmin(scale, M.fmin(maxFieldsWid/center.outerWidth, maxFieldsHei/center.outerHeight)) );
			center.x = Std.int( -ei.width*ed.pivotX - center.outerWidth*0.5*center.scaleX + ei.width*0.5 );
			center.y = Std.int( -ei.height*ed.pivotY - center.outerHeight*0.5*center.scaleY + ei.height*0.5);
			center.alpha = alpha;

			beneath.setScale( M.fmin(scale, maxFieldsWid/beneath.outerWidth) );
			beneath.x = Std.int( -ei.width*ed.pivotX - beneath.outerWidth*0.5*beneath.scaleX + ei.width*0.5 );
			beneath.y = Std.int( ei.height*(1-ed.pivotY) + 1 );
			beneath.alpha = alpha;
		}
	}

	override function postUpdate() {
		super.postUpdate();
		if( layoutInvalidated )
			updateLayout();
	}
}