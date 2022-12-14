package ui.modal.dialog;

enum WallFragment {
	Full;
	Wall_N;
	Wall_S;
	Wall_W;
	Wall_E;
	ExtCorner_NW;
	ExtCorner_NE;
	ExtCorner_SW;
	ExtCorner_SE;
	InCorner_NW;
	InCorner_NE;
	InCorner_SW;
	InCorner_SE;
}

class RulesWizard extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var td : data.def.TilesetDef;
	var tileset : ui.Tileset;
	var jGrids : js.jquery.JQuery;
	var currentFragment : Null<WallFragment>;
	var fragments : Map<WallFragment, Array<Int>> = new Map();
	var intGridValue : Int = -1;

	public function new(ld:data.def.LayerDef, onConfirm:data.DataTypes.AutoLayerRuleGroup->Void) {
		super();

		loadTemplate("rulesWizard.html");

		this.ld = ld;
		td = project.defs.getTilesetDef(ld.tilesetDefUid);

		// Tile picker
		tileset = new ui.Tileset(jContent.find(".tileset"), td, Free);
		tileset.onSelectAnything = ()->{
			onSelectTiles( tileset.getSelectedTileIds() );
		}

		jGrids = jContent.find(".grids");

		var jGrid9 = jGrids.find(".grid9");
		createCell(ExtCorner_NW).appendTo(jGrid9);
		createCell(Wall_N).appendTo(jGrid9);
		createCell(ExtCorner_NE).appendTo(jGrid9);
		createCell(Wall_W).appendTo(jGrid9);
		createCell(Full).appendTo(jGrid9);
		createCell(Wall_E).appendTo(jGrid9);
		createCell(ExtCorner_SW).appendTo(jGrid9);
		createCell(Wall_S).appendTo(jGrid9);
		createCell(ExtCorner_SE).appendTo(jGrid9);

		var jGrid4 = jGrids.find(".grid4");
		createCell(InCorner_NW).appendTo(jGrid4);
		createCell(InCorner_NE).appendTo(jGrid4);
		createCell(InCorner_SW).appendTo(jGrid4);
		createCell(InCorner_SE).appendTo(jGrid4);

		updatePalette();

		var jInt = jContent.find(".intGrid");
		jInt.click(_->{
			new ui.modal.dialog.IntGridValuePicker(ld, intGridValue, setIntGridValue);
		});

		// Confirm
		addConfirm(()->{
			onConfirm(null);
		});
		addCancel();
	}


	function setIntGridValue(v:Int) {
		var jInt = jContent.find(".intGrid");
		if( v>0 ) {
			var color = ld.getIntGridValueColor(v);
			jInt.css("background-color", color.toBlack(0.4).toHex());
			jInt.css("color", color.toWhite(0.6).toHex());
			jInt.removeClass("empty");
			jInt.find(".color").css("background-color", color.toHex());
			jInt.find(".id").html("#"+v);
			var vd = ld.getIntGridValueDef(v);
			jInt.find(".name").html(vd.identifier==null ? "Unnamed" : vd.identifier);
		}
	}


	function createCell(f:WallFragment) {
		var jCell = new J('<div class="cell"/>');
		jCell.attr("name", f.getName());
		jCell.click( _->{
			setCurrent(f);
			if( fragments.exists(f) )
				tileset.setSelectedTileIds(fragments.get(f));
			else
				tileset.setSelectedTileIds([]);
		});
		return jCell;
	}


	function onSelectTiles(tids:Array<Int>) {
		if( currentFragment!=null ) {
			if( tids.length==0 )
				fragments.remove(currentFragment);
			else
				fragments.set(currentFragment, tids);
			updatePalette();
		}
	}


	function updatePalette() {
		for(elem in jGrids.find(".cell")) {
			var jCell = new J(elem);
			jCell.empty();
			var f = WallFragment.createByName(jCell.attr("name"));
			if( fragments.exists(f) ) {
				// Defined cell
				var jImg = td.createTileHtmlImage(fragments.get(f)[0], 48);
				jCell.append(jImg);
			}
			else if( getSymetricalAlternative(f)!=null ) {
				// Cell is using symetrical alternative
				var alt = getSymetricalAlternative(f);
				var jImg = td.createTileHtmlImage(fragments.get(alt.f)[0], 48);
				if( alt.flipX && alt.flipY )
					jImg.css("transform", "scaleX(-1) scaleY(-1)");
				else if( alt.flipX )
					jImg.css("transform", "scaleX(-1)");
				else if( alt.flipY )
					jImg.css("transform", "scaleY(-1)");

				jImg.css("opacity", "0.4");
				jCell.append(jImg);
			}
			else {
				// Undefined cell
				var id = getIconId(f);
				var jImg = createHtmlImage(id, 48);
				jCell.append(jImg);
			}
		}
	}


	function getIconId(f:WallFragment) {
		return switch f {
			case Full: D.icons.full;
			case Wall_N: D.icons.wall_n;
			case Wall_S: D.icons.wall_s;
			case Wall_W: D.icons.wall_w;
			case Wall_E: D.icons.wall_e;
			case ExtCorner_NW: D.icons.extCorner_nw;
			case ExtCorner_NE: D.icons.extCorner_ne;
			case ExtCorner_SW: D.icons.extCorner_sw;
			case ExtCorner_SE: D.icons.extCorner_se;
			case InCorner_NW: D.icons.inCorner_nw;
			case InCorner_NE: D.icons.inCorner_ne;
			case InCorner_SW: D.icons.inCorner_sw;
			case InCorner_SE: D.icons.inCorner_se;
		}
	}

	function getSymetricalAlternative(f:WallFragment) {
		var flipX = false;
		var flipY = false;
		var alt : WallFragment = null;
		switch f {
			case Full: null;
			case Wall_W: if( fragments.exists(Wall_E) ) { alt=Wall_E; flipX=true; }
			case Wall_E: if( fragments.exists(Wall_W) ) { alt=Wall_W; flipX=true; }
			case Wall_N: if( fragments.exists(Wall_S) ) { alt=Wall_S; flipY=true; }
			case Wall_S: if( fragments.exists(Wall_N) ) { alt=Wall_N; flipY=true; }

			case ExtCorner_NW:
				if( fragments.exists(ExtCorner_NE) ) { alt=ExtCorner_NE; flipX=true; }
				else if( fragments.exists(ExtCorner_SW) ) { alt=ExtCorner_SW; flipY=true; }
				else if( fragments.exists(ExtCorner_SE) ) { alt=ExtCorner_SE; flipX=true; flipY=true; }

			case ExtCorner_NE:
				if( fragments.exists(ExtCorner_NW) ) { alt=ExtCorner_NW; flipX=true; }
				else if( fragments.exists(ExtCorner_SE) ) { alt=ExtCorner_SE; flipY=true; }
				else if( fragments.exists(ExtCorner_SW) ) { alt=ExtCorner_SW; flipX=true; flipY=true; }

			case ExtCorner_SW:
				if( fragments.exists(ExtCorner_SE) ) { alt=ExtCorner_SE; flipX=true; }
				else if( fragments.exists(ExtCorner_NW) ) { alt=ExtCorner_NW; flipY=true; }
				else if( fragments.exists(ExtCorner_NE) ) { alt=ExtCorner_NE; flipX=true; flipY=true; }

			case ExtCorner_SE:
				if( fragments.exists(ExtCorner_SW) ) { alt=ExtCorner_SW; flipX=true; }
				else if( fragments.exists(ExtCorner_NE) ) { alt=ExtCorner_NE; flipY=true; }
				else if( fragments.exists(ExtCorner_NW) ) { alt=ExtCorner_NW; flipX=true; flipY=true; }

			case InCorner_NW:
				if( fragments.exists(InCorner_NE) ) { alt=InCorner_NE; flipX=true; }
				else if( fragments.exists(InCorner_SW) ) { alt=InCorner_SW; flipY=true; }
				else if( fragments.exists(InCorner_SE) ) { alt=InCorner_SE; flipX=true; flipY=true; }

			case InCorner_NE:
				if( fragments.exists(InCorner_NW) ) { alt=InCorner_NW; flipX=true; }
				else if( fragments.exists(InCorner_SE) ) { alt=InCorner_SE; flipY=true; }
				else if( fragments.exists(InCorner_SW) ) { alt=InCorner_SW; flipX=true; flipY=true; }

			case InCorner_SW:
				if( fragments.exists(InCorner_SE) ) { alt=InCorner_SE; flipX=true; }
				else if( fragments.exists(InCorner_NW) ) { alt=InCorner_NW; flipY=true; }
				else if( fragments.exists(InCorner_NE) ) { alt=InCorner_NE; flipX=true; flipY=true; }

			case InCorner_SE: null;
				if( fragments.exists(InCorner_SW) ) { alt=InCorner_SW; flipX=true; }
				else if( fragments.exists(InCorner_NE) ) { alt=InCorner_NE; flipY=true; }
				else if( fragments.exists(InCorner_NW) ) { alt=InCorner_NW; flipX=true; flipY=true; }
		}
		return alt!=null ? { f:alt, flipX:flipX, flipY:flipY } : null;
	}


	function setCurrent(?f:WallFragment) {
		currentFragment = f;
		jGrids.find(".cell").removeClass("active");
		if( f!=null )
			jGrids.find(".cell[name="+f+"]").addClass("active");
	}


	function getRuleMatrixFromFragment(f:WallFragment) {
		var m = switch f {
			case Full: [
				"-o-",
				"ooo",
				"-o-",
			];
			case Wall_N: [
				"-x-",
				"-o-",
				"---",
			];
			case Wall_S: [
				"---",
				"-o-",
				"-x-",
			];
			case Wall_W: [
				"---",
				"xo-",
				"---",
			];
			case Wall_E: [
				"---",
				"-ox",
				"---",
			];
			case ExtCorner_NW: [
				"-x-",
				"xoo",
				"-o-",
			];
			case ExtCorner_NE: [
				"-x-",
				"oox",
				"-o-",
			];
			case ExtCorner_SW: [
				"-o-",
				"xoo",
				"-x-",
			];
			case ExtCorner_SE: [
				"-o-",
				"oox",
				"-x-",
			];
			case InCorner_NW: [
				"xo-",
				"oo-",
				"---",
			];
			case InCorner_NE: [
				"-ox",
				"-oo",
				"---",
			];
			case InCorner_SW: [
				"---",
				"oo-",
				"xo-",
			];
			case InCorner_SE: [
				"---",
				"-oo",
				"-ox",
			];
		}
		return m;
	}


	var _cachedAtlasPixels : Null<hxd.Pixels>;
	public function createHtmlImage(iconId:String, size=48) : js.jquery.JQuery {
		if( _cachedAtlasPixels==null )
			_cachedAtlasPixels = hxd.Res.atlas.icons.toAseprite().toTile().getTexture().capturePixels();

		var tile = Assets.aseIcons.getTile(iconId);
		var subPixels = _cachedAtlasPixels.sub(tile.ix, tile.iy, tile.iwidth, tile.iheight);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		var img = new js.html.Image(subPixels.width, subPixels.height);
		img.src = 'data:image/png;base64,$b64';
		var jImg = new J(img);

		jImg.css({
			width:size+"px",
			height:size+"px",
			imageRendering: "pixelated",
		});

		return jImg;
	}

}