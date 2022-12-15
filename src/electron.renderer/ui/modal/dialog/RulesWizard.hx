package ui.modal.dialog;

enum WallFragment {
	Full;
	Single;
	Wall_N;
	Wall_E;
	Wall_S;
	Wall_W;
	Vertical_N;
	Vertical_Mid;
	Vertical_S;
	Horizontal_W;
	Horizontal_Mid;
	Horizontal_E;
	ExtCorner_NW;
	ExtCorner_NE;
	ExtCorner_SE;
	ExtCorner_SW;
	InCorner_NW;
	InCorner_NE;
	InCorner_SE;
	InCorner_SW;
	Turn_NW;
	Turn_NE;
	Turn_SE;
	Turn_SW;
}

class RulesWizard extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var td : data.def.TilesetDef;
	var tileset : ui.Tileset;
	var jGrid : js.jquery.JQuery;
	var jName : js.jquery.JQuery;
	var currentFragment : Null<WallFragment>;
	var fragments : Map<WallFragment, Array<Int>> = new Map();
	var intGridValue : Int = 0;
	var groupName = "";

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

		jGrid = jContent.find(".grid");

		createCell(1,1, Full);
		createCell(0,0, ExtCorner_NW);
		createCell(2,0, ExtCorner_NE);
		createCell(0,2, ExtCorner_SW);
		createCell(2,2, ExtCorner_SE);
		createCell(1,0, Wall_N);
		createCell(1,2, Wall_S);
		createCell(0,1, Wall_W);
		createCell(2,1, Wall_E);
		createCell(2,3, Single);
		createCell(0,3, InCorner_NW);
		createCell(1,3, InCorner_NE);
		createCell(0,4, InCorner_SW);
		createCell(1,4, InCorner_SE);
		createCell(3,0, Turn_NW);
		createCell(4,0, Turn_NE);
		createCell(3,1, Turn_SW);
		createCell(4,1, Turn_SE);
		createCell(3,2, Vertical_N);
		createCell(3,3, Vertical_Mid);
		createCell(3,4, Vertical_S);
		createCell(4,4, Horizontal_W);
		createCell(5,4, Horizontal_Mid);
		createCell(6,4, Horizontal_E);

		updatePalette();

		var jInt = jContent.find(".intGrid");
		jInt.click(_->{
			new ui.modal.dialog.IntGridValuePicker(ld, intGridValue, onPickIntGridValue);
		});

		jName = jContent.find("input[name=name]");
		jName.change( _->setName(jName.val()) );

		// Confirm
		addButton(L.t._("Create group of rules"), ()->{
			if( intGridValue==0 ) {
				Notification.error(L.t._("You need to pick an IntGrid value."));
				return;
			}
			if( groupName.length==0 ) {
				Notification.error(L.t._("Name this group of rules."));
				jName.focus();
				return;
			}
			var rg = createRules();
			onConfirm(rg);
			close();
		});
		addCancel();
	}

	function setName(s:String) {
		groupName = s;
		jName.val(groupName);
	}


	function onPickIntGridValue(v:Int) {
		if( v==0 )
			return;

		intGridValue = v;
		var jInt = jContent.find(".intGrid");
		var color = ld.getIntGridValueColor(v);
		jInt.css("background-color", color.toBlack(0.4).toHex());
		jInt.css("color", color.toWhite(0.6).toHex());
		jInt.removeClass("empty");
		jInt.find(".color").css("background-color", color.toHex());
		jInt.find(".id").html("#"+v);
		var vd = ld.getIntGridValueDef(v);
		jInt.find(".name").html(vd.identifier==null ? "Unnamed" : vd.identifier);

		setName( vd.identifier==null ? "Rules for #"+v : vd.identifier );
	}


	function createCell(cx:Int, cy:Int, f:WallFragment) {
		var jCell = new J('<div class="cell"/>');
		jGrid.append(jCell);
		jCell.css("grid-column", '${cx+1}/${cx+2}');
		jCell.css("grid-row", '${cy+1}/${cy+2}');
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
		for(elem in jGrid.find(".cell")) {
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
			case Single: D.icons.single;
			case Wall_N: D.icons.wall_n;
			case Wall_S: D.icons.wall_s;
			case Wall_W: D.icons.wall_w;
			case Wall_E: D.icons.wall_e;
			case Vertical_N: D.icons.vertical_n;
			case Vertical_Mid: D.icons.vertical_mid;
			case Vertical_S: D.icons.vertical_s;
			case Horizontal_W: D.icons.horizontal_w;
			case Horizontal_Mid: D.icons.horizontal_mid;
			case Horizontal_E: D.icons.horizontal_e;
			case ExtCorner_NW: D.icons.extCorner_nw;
			case ExtCorner_NE: D.icons.extCorner_ne;
			case ExtCorner_SW: D.icons.extCorner_sw;
			case ExtCorner_SE: D.icons.extCorner_se;
			case InCorner_NW: D.icons.inCorner_nw;
			case InCorner_NE: D.icons.inCorner_ne;
			case InCorner_SW: D.icons.inCorner_sw;
			case InCorner_SE: D.icons.inCorner_se;
			case Turn_NW: D.icons.turn_nw;
			case Turn_NE: D.icons.turn_ne;
			case Turn_SE: D.icons.turn_se;
			case Turn_SW: D.icons.turn_sw;
		}
	}

	function isSymetricalAltFor(cur:WallFragment, altOf:WallFragment) {
		var alt = getSymetricalAlternative(altOf);
		return alt!=null && alt.f==cur;
	}

	function flip(f:WallFragment, flipX:Bool, flipY:Bool) {
		return switch f {
			case Full, Single : f;
			case Wall_N: flipY ? Wall_S : f;
			case Wall_E: flipX ? Wall_W : f;
			case Wall_S: flipY ? Wall_N : f;
			case Wall_W: flipX ? Wall_E : f;
			case Vertical_N: flipY ? Vertical_S : f;
			case Vertical_Mid: f;
			case Vertical_S: flipY ? Vertical_N : f;
			case Horizontal_W: flipX ? Horizontal_E : f;
			case Horizontal_Mid: f;
			case Horizontal_E: flipX ? Horizontal_W : f;
			case ExtCorner_NW: flipX && flipY ? ExtCorner_SE : flipX ? ExtCorner_NE : flipY ? ExtCorner_SW : f;
			case ExtCorner_NE: flipX && flipY ? ExtCorner_SW : flipX ? ExtCorner_NW : flipY ? ExtCorner_SE : f;
			case ExtCorner_SE: flipX && flipY ? ExtCorner_NW : flipX ? ExtCorner_SW : flipY ? ExtCorner_NE : f;
			case ExtCorner_SW: flipX && flipY ? ExtCorner_NE : flipX ? ExtCorner_SE : flipY ? ExtCorner_NW : f;
			case InCorner_NW: flipX && flipY ? InCorner_SE : flipX ? InCorner_NE : flipY ? InCorner_SW : f;
			case InCorner_NE: flipX && flipY ? InCorner_SW : flipX ? InCorner_NW : flipY ? InCorner_SE : f;
			case InCorner_SE: flipX && flipY ? InCorner_NW : flipX ? InCorner_SW : flipY ? InCorner_NE : f;
			case InCorner_SW: flipX && flipY ? InCorner_NE : flipX ? InCorner_SE : flipY ? InCorner_NW : f;
			case Turn_NW: flipX && flipY ? Turn_SE : flipX ? Turn_NE : flipY ? Turn_SW : f;
			case Turn_NE: flipX && flipY ? Turn_SW : flipX ? Turn_NW : flipY ? Turn_SE : f;
			case Turn_SE: flipX && flipY ? Turn_NW : flipX ? Turn_SW : flipY ? Turn_NE : f;
			case Turn_SW: flipX && flipY ? Turn_NE : flipX ? Turn_SE : flipY ? Turn_NW : f;
		}
	}

	function getSymetricalAlternative(f:WallFragment) {
		var sym = flip(f,true,false);
		if( sym!=f && fragments.exists(sym) )
			return { f:sym, flipX:true, flipY:false }

		var sym = flip(f,false,true);
		if( sym!=f && fragments.exists(sym) )
			return { f:sym, flipX:false, flipY:true }

		var sym = flip(f,true,true);
		if( sym!=f && fragments.exists(sym) )
			return { f:sym, flipX:true, flipY:true }

		return null;
	}


	function setCurrent(?f:WallFragment) {
		currentFragment = f;
		jGrid.find(".cell").removeClass("active");
		if( f!=null )
			jGrid.find(".cell[name="+f+"]").addClass("active");
	}



	function createRules() {
		var rg = ld.createRuleGroup(project.generateUniqueId_int(), groupName, 0);
		createRule(rg, Single);

		createRule(rg, Turn_NW);
		createRule(rg, Turn_NE);
		createRule(rg, Turn_SE);
		createRule(rg, Turn_SW);

		createRule(rg, Vertical_N);
		createRule(rg, Vertical_S);
		createRule(rg, Vertical_Mid);

		createRule(rg, Horizontal_W);
		createRule(rg, Horizontal_E);
		createRule(rg, Horizontal_Mid);

		createRule(rg, InCorner_NW);
		createRule(rg, InCorner_NE);
		createRule(rg, InCorner_SE);
		createRule(rg, InCorner_SW);

		createRule(rg, ExtCorner_NW);
		createRule(rg, ExtCorner_NE);
		createRule(rg, ExtCorner_SE);
		createRule(rg, ExtCorner_SW);

		createRule(rg, Wall_N);
		createRule(rg, Wall_E);
		createRule(rg, Wall_S);
		createRule(rg, Wall_W);

		createRule(rg, Full);
		return rg;
	}

	function createRule(rg:data.DataTypes.AutoLayerRuleGroup, f:WallFragment) {
		if( !fragments.exists(f) )
			return false;

		var m = getRuleMatrixFromFragment(f);
		var size = m[0].length;
		var rd = new data.def.AutoLayerRuleDef(project.generateUniqueId_int(), size);
		rg.rules.push(rd);
		for(cy in 0...size)
		for(cx in 0...size) {
			var c = m[cy].charAt(cx);
			rd.set(cx,cy, switch c {
				case "x": -intGridValue;
				case "o": intGridValue;
				case _: 0;
			});
		}
		rd.tileIds = fragments.get(f).copy();

		for(k in WallFragment.getConstructors()) {
			var e = WallFragment.createByName(k);
			if( isSymetricalAltFor(f, e) ) {
				var alt = getSymetricalAlternative(e);
				if( alt.flipX )
					rd.flipX = true;
				if( alt.flipY )
					rd.flipY = true;
			}
		}
		return true;
	}


	function getRuleMatrixFromFragment(f:WallFragment, flipX=false, flipY=false) : Array<String> {
		var m : Array<String> = switch f {
			case Full: [
				"-o-",
				"ooo",
				"-o-",
			];
			case Single: [
				"-x-",
				"xox",
				"-x-",
			];

			case Vertical_N: [
				"-x-",
				"xox",
				"xox",
			];
			case Vertical_Mid: [
				"---",
				"xox",
				"---",
			];
			case Vertical_S: getRuleMatrixFromFragment(Vertical_N, false, true);

			case Horizontal_W: [
				"-xx",
				"xoo",
				"-xx",
			];
			case Horizontal_Mid: [
				"-x-",
				"-o-",
				"-x-",
			];
			case Horizontal_E: getRuleMatrixFromFragment(Horizontal_W, true, false);

			case Turn_NW: [
				"-x-",
				"xoo",
				"-ox",
			];
			case Turn_NE: getRuleMatrixFromFragment(Turn_NW, true, false);
			case Turn_SE: getRuleMatrixFromFragment(Turn_NW, true, true);
			case Turn_SW: getRuleMatrixFromFragment(Turn_NW, false, true);

			case Wall_N: [
				"-x-",
				"-o-",
				"---",
			];
			case Wall_S: getRuleMatrixFromFragment(Wall_N, false, true);

			case Wall_W: [
				"---",
				"xo-",
				"---",
			];
			case Wall_E: getRuleMatrixFromFragment(Wall_W, true, false);

			case ExtCorner_NW: [
				"-x-",
				"xoo",
				"-o-",
			];
			case ExtCorner_NE: getRuleMatrixFromFragment(ExtCorner_NW, true, false);
			case ExtCorner_SE: getRuleMatrixFromFragment(ExtCorner_NW, true, true);
			case ExtCorner_SW: getRuleMatrixFromFragment(ExtCorner_NW, false, true);

			case InCorner_NW: [
				"xo-",
				"oo-",
				"---",
			];
			case InCorner_NE: getRuleMatrixFromFragment(InCorner_NW, true, false);
			case InCorner_SE: getRuleMatrixFromFragment(InCorner_NW, true, true);
			case InCorner_SW: getRuleMatrixFromFragment(InCorner_NW, false, true);
		}

		if( flipX ) {
			var out = [];
			for(line in m) {
				var lineOut = "";
				for(c in line.split(""))
					lineOut = c + lineOut;
				out.push(lineOut);
			}
			m = out;
		}
		if( flipY )
			m.reverse();

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