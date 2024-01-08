package ui.modal.dialog;

import data.def.AutoLayerRuleGroupDef;

enum WallFragment {
	// WARNING: the order of the enum is used to sort rules accordingly!
	@at(3,1) Single;
	@at(3,2) Cross;

	@at(2,3) Turn_NW;
	@at(3,3) Turn_NE;
	@at(3,4) Turn_SE;
	@at(2,4) Turn_SW;

	@at(10,2) Diagonal_SW_NE;
	@at(10,3) Diagonal_NW_SE;
	@at(6,2) Corner_NW_to_N;
	@at(6,0) Corner_NW_to_W;
	@at(10,0) Corner_NW_to_NW;
	@at(7,2) Corner_NE_to_N;
	@at(7,0) Corner_NE_to_E;
	@at(11,0) Corner_NE_to_NE;
	@at(7,1) Corner_SE_to_E;
	@at(7,3) Corner_SE_to_S;
	@at(11,1) Corner_SE_to_SE;
	@at(6,3) Corner_SW_to_S;
	@at(6,1) Corner_SW_to_W;
	@at(10,1) Corner_SW_to_SW;

	@at(8,3) TCross_N;
	@at(8,2) TCross_E;
	@at(9,2) TCross_S;
	@at(9,3) TCross_W;

	@at(8,0) TWall_W;
	@at(9,0) TWall_E;
	@at(8,1) TWall_S;
	@at(9,1) TWall_N;

	@at(3,0) Horizontal_W;
	@at(5,0) Horizontal_E;
	@at(4,0) Horizontal_Mid;
	@at(4,1) Vertical_N;
	@at(4,3) Vertical_S;
	@at(4,2) Vertical_Mid;

	@at(0,0) ExtCorner_NW;
	@at(2,0) ExtCorner_NE;
	@at(2,2) ExtCorner_SE;
	@at(0,2) ExtCorner_SW;

	@at(1,0) Wall_N;
	@at(2,1) Wall_E;
	@at(1,2) Wall_S;
	@at(0,1) Wall_W;

	@at(0,3) InCorner_NW;
	@at(1,3) InCorner_NE;
	@at(1,4) InCorner_SE;
	@at(0,4) InCorner_SW;

	@at(1,1) Full;
}

class RulesWizard extends ui.modal.Dialog {
	var ld : data.def.LayerDef;
	var td : data.def.TilesetDef;
	var editedGroup : Null<AutoLayerRuleGroupDef>;

	var tileset : ui.Tileset;
	var jGrid : js.jquery.JQuery;
	var jName : js.jquery.JQuery;
	var currentFragment : Null<WallFragment>;
	var fragments : Map<WallFragment, Array<Int>> = new Map();
	var groupName = "";

	var mainValue : Int = 0;
	var otherValue : Int = 0;
	var breakOnMatch = true;

	var _allFragmentEnums : Array<WallFragment> = [];


	public function new(?baseRg:AutoLayerRuleGroupDef, ld:data.def.LayerDef, onConfirm:AutoLayerRuleGroupDef->Void) {
		super();

		loadTemplate("rulesWizard.html");

		this.ld = ld;
		td = project.defs.getTilesetDef(ld.tilesetDefUid);

		for( k in WallFragment.getConstructors() )
			_allFragmentEnums.push( WallFragment.createByName(k) );

		// Tile picker
		tileset = new ui.Tileset(jContent.find(".tileset"), td, MultipleIndividuals);
		tileset.onSelectAnything = ()->{
			onSelectTiles( tileset.getSelectedTileIds() );
		}

		jGrid = jContent.find(".grid");

		for(k in WallFragment.getConstructors()) {
			var f = WallFragment.createByName(k);
			var coords = try Reflect.field( haxe.rtti.Meta.getFields(WallFragment), k ).at catch(_) null;
			if( coords!=null )
				createCell(coords[0], coords[1], f);
		}

		// IntGrid value picker
		var jInt = jContent.find(".intGrid.main");
		jInt.click(_->{
			new ui.modal.dialog.IntGridValuePicker(jInt, ld, mainValue, onPickIntGridValue);
		});

		// Other intGrid value picker
		var jInt = jContent.find(".intGrid.other");
		jInt.click(_->{
			new ui.modal.dialog.IntGridValuePicker(jInt, ld, otherValue, jInt.find(".noValue").text(), onPickOtherValue);
		});

		// Name input
		jName = jContent.find("input[name=name]");
		jName.change( _->setName(jName.val()) );

		// Confirm
		addButton(baseRg==null ? L.t._("Create rules") : L.t._("Update rules"), ()->{
			if( mainValue==0 ) {
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

		// Pick default intGrid value if there's only one
		var allValues = switch ld.type {
			case IntGrid: ld.getAllIntGridValues();
			case Entities: [];
			case Tiles: [];
			case AutoLayer: ld.autoSourceLd!=null ? ld.autoSourceLd.getAllIntGridValues() : [];
		}
		if( allValues.length==1 )
			onPickIntGridValue( allValues[0].value );


		// Try to match existing group to wizard patterns
		if( baseRg!=null )
			importRuleGroup(baseRg);

		updateUI();
	}


	function guessMainValue(source:AutoLayerRuleGroupDef) {
		for(r in source.rules) {
			final center = Std.int(r.size*0.5);
			if( r.getPattern(center,center)>0 )
				return M.iabs( r.getPattern(center,center) );
		}
		return 0;
	}


	function guessOtherValue(source:AutoLayerRuleGroupDef) {
		for(r in source.rules)
		for(cy in 0...r.size)
		for(cx in 0...r.size)
			if( r.getPattern(cx,cy)!=0 && M.iabs(r.getPattern(cx,cy))!=mainValue && M.iabs(r.getPattern(cx,cy)) < Const.AUTO_LAYER_ANYTHING )
				return M.iabs( r.getPattern(cx,cy) );
		return 0;
	}

	function importRuleGroup(source:AutoLayerRuleGroupDef) {
		// Guess intGrid values
		mainValue = guessMainValue(source);
		otherValue = guessOtherValue(source);
		if( mainValue==0 )
			return;

		editedGroup = source;
		setName(source.name);

		var i = 0;
		for(rd in source.rules) {
			// Guess break on match setting
			if( i==0 )
				breakOnMatch = rd.breakOnMatch;

			// Iterate all rules from this group, and try to match them with standard Fragments
			for(f in _allFragmentEnums)
				if( matchRuleToFragment(rd,f) ) {
					fragments.set(f, rd.tileRectsIds[0].copy());
					break;
				}
			i++;
		}
	}


	function matchRuleToFragment(rd:data.def.AutoLayerRuleDef, f:WallFragment) : Bool {
		if( rd.size>3 )
			return null;

		var matrix = getRuleIntMatrix(f);
		if( rd.size==1 ) {
			for(idx in 0...9)
				if( idx!=4 && matrix.get(idx)!=0 )
					return false;
				else if( idx==4 && matrix.get(idx)!=rd.getPattern(0,0) )
					return false;
		}
		else {
			for(cy in 0...rd.size)
			for(cx in 0...rd.size)
				if( matrix.get(cx+cy*3)!=rd.getPattern(cx,cy) )
					return false;
		}

		return true;
	}


	function setName(s:String) {
		groupName = s;
		jName.val(groupName);
	}


	function onPickIntGridValue(v:Int) {
		if( v==0 )
			return;

		mainValue = v;
		if( mainValue==otherValue )
			onPickOtherValue(0);

		var vd = ld.type==IntGrid ? ld.getIntGridValueDef(v) : ld.autoSourceLd.getIntGridValueDef(v);
		if( editedGroup==null )
			setName( vd.identifier==null ? "Rules for #"+v : vd.identifier );
		updateUI();
	}


	function onPickOtherValue(v:Int) {
		otherValue = v;
		updateUI();
	}


	function createCell(cx:Int, cy:Int, f:WallFragment) {
		var jCell = new J('<div class="cell"/>');
		jGrid.append(jCell);
		jCell.css("grid-column", '${cx+1}/${cx+2}');
		jCell.css("grid-row", '${cy+1}/${cy+2}');
		jCell.attr("name", f.getName());
		jCell.mousedown( (ev:js.jquery.Event)->{
			setCurrent(f);
			switch ev.button {
				case 0:
					if( fragments.exists(f) )
						tileset.setSelectedTileIds(fragments.get(f));
					else
						tileset.setSelectedTileIds([]);

				case 1, 2:
					fragments.remove(f);
					updateUI();
			}
		});
		return jCell;
	}


	function onSelectTiles(tids:Array<Int>) {
		if( currentFragment!=null ) {
			if( tids.length==0 )
				fragments.remove(currentFragment);
			else
				fragments.set(currentFragment, tids);
			updateUI();
		}
	}


	function updateUI() {
		updateGrid();
		updateTileset();

		updateIntGridValue("main", mainValue);
		updateIntGridValue("other", otherValue);

		updateOptionsForm();
	}

	function updateOptionsForm() {
		var jForm = jContent.find("dl.form");
		jForm.find("*").off();

		var i = Input.linkToHtmlInput(breakOnMatch, jForm.find("[name=breakOnMatch]"));
		i.invert();
		i.onValueChange = (v)->{
			breakOnMatch = v;
			updateUI();
		}

		JsTools.parseComponents(jForm);
	}


	function updateIntGridValue(className:String, value:Int) {
		var jInt = jContent.find(".intGrid."+className);
		if( value<=0 ) {
			jInt.addClass("empty");
			jInt.removeAttr("style");
		}
		else {
			var color = ld.type==IntGrid ? ld.getIntGridValueColor( value ) : ld.autoSourceLd.getIntGridValueColor(value);
			jInt.css("background-color", color.toBlack(0.4).toHex());
			jInt.css("color", color.toWhite(0.6).toHex());
			jInt.removeClass("empty");

			jInt.find(".color").css("background-color", color.toHex());

			jInt.find(".id").html("#"+value);

			var vd = ld.type==IntGrid ? ld.getIntGridValueDef( value ) : ld.autoSourceLd.getIntGridValueDef(value);
			jInt.find(".name").html(vd.identifier==null ? "Unnamed" : vd.identifier);
		}
	}


	function updateTileset() {
		tileset.renderAtlas();
	}

	function updateGrid() {
		for(elem in jGrid.find(".cell")) {
			var jCell = new J(elem);
			jCell.empty().removeClass("mirror");
			var f = WallFragment.createByName(jCell.attr("name"));
			if( fragments.exists(f) ) {
				// Defined cell
				var jImg = td.createTileHtmlImageFromTileId(fragments.get(f)[0], 48);
				jCell.append(jImg);
				jCell.addClass("defined");
			}
			else if( getSymetricalAlternative(f)!=null ) {
				// Cell is using symetrical alternative
				var alt = getSymetricalAlternative(f);
				var jImg = td.createTileHtmlImageFromTileId(fragments.get(alt.f)[0], 48);
				if( alt.flipX && alt.flipY )
					jImg.css("transform", "scaleX(-1) scaleY(-1)");
				else if( alt.flipX )
					jImg.css("transform", "scaleX(-1)");
				else if( alt.flipY )
					jImg.css("transform", "scaleY(-1)");

				jImg.css("opacity", "0.4");
				jCell.addClass("mirror");
				jCell.append(jImg);
			}

			// Cell layout
			var id = getIconId(f);
			var jImg = iconToJqueryImage(id, 48);
			if( !jCell.is(":empty") )
				jImg.addClass("faded");
			jCell.append(jImg);
		}
	}


	function getIconId(f:WallFragment) {
		return switch f {
			case Full: D.icons.full;
			case Single: D.icons.single;
			case Cross: D.icons.cross;
			case Wall_N: D.icons.wall_n;
			case Wall_S: D.icons.wall_s;
			case Wall_W: D.icons.wall_w;
			case Wall_E: D.icons.wall_e;
			case Diagonal_NW_SE: D.icons.diagonal_nw_se;
			case Diagonal_SW_NE: D.icons.diagonal_sw_ne;
			case TWall_N: D.icons.tWall_n;
			case TWall_E: D.icons.tWall_e;
			case TWall_S: D.icons.tWall_s;
			case TWall_W: D.icons.tWall_w;
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
			case TCross_N: D.icons.tcross_n;
			case TCross_E: D.icons.tcross_e;
			case TCross_S: D.icons.tcross_s;
			case TCross_W: D.icons.tcross_w;
			case Corner_NW_to_NW: D.icons.corner_nw_to_nw;
			case Corner_NE_to_NE: D.icons.corner_ne_to_ne;
			case Corner_SW_to_SW: D.icons.corner_sw_to_sw;
			case Corner_SE_to_SE: D.icons.corner_se_to_se;
			case Turn_NW: D.icons.turn_nw;
			case Turn_NE: D.icons.turn_ne;
			case Turn_SE: D.icons.turn_se;
			case Turn_SW: D.icons.turn_sw;
			case Corner_NW_to_N: D.icons.corner_nw_to_n;
			case Corner_NW_to_W: D.icons.corner_nw_to_w;
			case Corner_NE_to_N: D.icons.corner_ne_to_n;
			case Corner_NE_to_E: D.icons.corner_ne_to_e;
			case Corner_SE_to_E: D.icons.corner_se_to_e;
			case Corner_SE_to_S: D.icons.corner_se_to_s;
			case Corner_SW_to_S: D.icons.corner_sw_to_s;
			case Corner_SW_to_W: D.icons.corner_sw_to_w;
		}
	}

	function isSymetricalAltFor(cur:WallFragment, altOf:WallFragment) {
		var alt = getSymetricalAlternative(altOf);
		return alt!=null && alt.f==cur;
	}

	function flip(f:WallFragment, flipX:Bool, flipY:Bool) {
		return switch f {
			case Full, Single, Cross : f;
			case Wall_N: flipY ? Wall_S : f;
			case Wall_E: flipX ? Wall_W : f;
			case Wall_S: flipY ? Wall_N : f;
			case Wall_W: flipX ? Wall_E : f;
			case Diagonal_NW_SE: flipX || flipY ? Diagonal_SW_NE: f;
			case Diagonal_SW_NE: flipX || flipY ? Diagonal_NW_SE: f;
			case TCross_N: flipY ? TCross_S : f;
			case TCross_S: flipY ? TCross_N : f;
			case TCross_W: flipX ? TCross_E : f;
			case TCross_E: flipX ? TCross_W : f;
			case TWall_N: flipY ? TWall_S : f;
			case TWall_S: flipY ? TWall_N : f;
			case TWall_W: flipX ? TWall_E : f;
			case TWall_E: flipX ? TWall_W : f;
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

			case Corner_NW_to_N: flipX && flipY ? Corner_SE_to_S : flipX ? Corner_NE_to_N : flipY ? Corner_SW_to_S : f;
			case Corner_NW_to_W: flipX && flipY ? Corner_SE_to_E : flipX ? Corner_NE_to_E : flipY ? Corner_SW_to_W : f;

			case Corner_NE_to_N: flipX && flipY ? Corner_SW_to_S : flipX ? Corner_NW_to_N : flipY ? Corner_SE_to_S : f;
			case Corner_NE_to_E: flipX && flipY ? Corner_SW_to_W : flipX ? Corner_NW_to_W : flipY ? Corner_SE_to_E : f;

			case Corner_SW_to_S: flipX && flipY ? Corner_NE_to_N : flipX ? Corner_SE_to_S : flipY ? Corner_NW_to_N : f;
			case Corner_SW_to_W: flipX && flipY ? Corner_NE_to_E : flipX ? Corner_SE_to_E : flipY ? Corner_NW_to_W : f;

			case Corner_SE_to_E: flipX && flipY ? Corner_NW_to_W : flipX ? Corner_SW_to_W : flipY ? Corner_NE_to_E : f;
			case Corner_SE_to_S: flipX && flipY ? Corner_NW_to_N : flipX ? Corner_SW_to_S : flipY ? Corner_NE_to_N : f;

			case Corner_NW_to_NW: flipX && flipY ? Corner_SE_to_SE : flipX ? Corner_NE_to_NE : flipY ? Corner_SW_to_SW : f;
			case Corner_NE_to_NE: flipX && flipY ? Corner_SW_to_SW : flipX ? Corner_NW_to_NW : flipY ? Corner_SE_to_SE : f;
			case Corner_SW_to_SW: flipX && flipY ? Corner_NE_to_NE : flipX ? Corner_SE_to_SE : flipY ? Corner_NW_to_NW : f;
			case Corner_SE_to_SE: flipX && flipY ? Corner_NW_to_NW : flipX ? Corner_SW_to_SW : flipY ? Corner_NE_to_NE : f;
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


	function getRuleIntMatrix(f:WallFragment) {
		var m = getRuleMatrixFromFragment(f);
		var out = new Map();
		var cy = 0;
		for(line in m) {
			var cx = 0;
			for(c in line.split("")) {
				out.set( cx+cy*3, c=="x" ? getOtherValueForMatrix() : c=="o" ? mainValue : 0 );
				cx++;
			}
			cy++;
		}

		return out;
	}


	function getRuleMatrixFromFragment(f:WallFragment, flipX=false, flipY=false) : Array<String> {
		var m : Array<String> = switch f {
			case Full: [
				"---",
				"-o-",
				"---",
			];
			case Single: [
				"-x-",
				"xox",
				"-x-",
			];

			case Cross: [
				"xox",
				"ooo",
				"xox",
			];

			case Diagonal_NW_SE: [
				"oox",
				"ooo",
				"xoo",
			];

			case Diagonal_SW_NE: [
				"xoo",
				"ooo",
				"oox",
			];

			case TWall_N: [
				"xox",
				"ooo",
				"ooo",
			];
			case TWall_S: getRuleMatrixFromFragment(TWall_N, false, true);

			case TWall_W: [
				"xoo",
				"ooo",
				"xoo",
			];
			case TWall_E: getRuleMatrixFromFragment(TWall_W, true, false);

			case TCross_N: [
				"xox",
				"ooo",
				"-x-",
			];
			case TCross_S: getRuleMatrixFromFragment(TCross_N, false, true);

			case TCross_W: [
				"xo-",
				"oox",
				"xo-",
			];
			case TCross_E: getRuleMatrixFromFragment(TCross_W, true, false);

			case Vertical_N: [
				"-x-",
				"xox",
				"---",
			];
			case Vertical_Mid: [
				"---",
				"xox",
				"---",
			];
			case Vertical_S: getRuleMatrixFromFragment(Vertical_N, false, true);

			case Horizontal_W: [
				"-x-",
				"xo-",
				"-x-",
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
				"xo-",
				"---",
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

			case Corner_NW_to_N: [
				"-ox",
				"xoo",
				"-oo",
			];
			case Corner_NE_to_N: getRuleMatrixFromFragment(Corner_NW_to_N, true, false);
			case Corner_SE_to_S: getRuleMatrixFromFragment(Corner_NW_to_N, true, true);
			case Corner_SW_to_S: getRuleMatrixFromFragment(Corner_NW_to_N, false, true);

			case Corner_NW_to_W: [
				"-x-",
				"ooo",
				"xoo",
			];
			case Corner_NE_to_E: getRuleMatrixFromFragment(Corner_NW_to_W, true, false);
			case Corner_SE_to_E: getRuleMatrixFromFragment(Corner_NW_to_W, true, true);
			case Corner_SW_to_W: getRuleMatrixFromFragment(Corner_NW_to_W, false, true);

			case Corner_NW_to_NW: [
				"xox",
				"ooo",
				"xoo",
			];
			case Corner_NE_to_NE: getRuleMatrixFromFragment(Corner_NW_to_NW, true, false);
			case Corner_SW_to_SW: getRuleMatrixFromFragment(Corner_NW_to_NW, false, true);
			case Corner_SE_to_SE: getRuleMatrixFromFragment(Corner_NW_to_NW, true, true);
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
	public function iconToHtmlImage(iconId:String) : js.html.Image {
		if( _cachedAtlasPixels==null )
			_cachedAtlasPixels = hxd.Res.atlas.icons.toAseprite().toTile().getTexture().capturePixels();

		var tile = Assets.aseIcons.getTile(iconId);
		var subPixels = _cachedAtlasPixels.sub(tile.ix, tile.iy, tile.iwidth, tile.iheight);

		// Colorize pixels using IntGrid colors
		var p : dn.Col = 0;
		var mainColor = mainValue==0 ? dn.Col.white(true) : ld.getIntGridValueColor(mainValue).withAlpha(1);
		var otherColor = otherValue==0 ? dn.Col.black(true) : ld.getIntGridValueColor(otherValue).withAlpha(1);
		mainColor.lightness = M.fmax(mainColor.lightness, 0.5);
		mainColor.af = 0.33;
		otherColor.lightness = M.fmax(otherColor.lightness, 0.5);
		otherColor.af = 0.33;
		for(y in 0...subPixels.height)
		for(x in 0...subPixels.width) {
			p = subPixels.getPixel(x,y);
			if( p.rf>0.5 )
				subPixels.setPixel( x, y, mainColor.toBlack( (1-p.rf) ) );
			else
				subPixels.setPixel( x, y, otherColor );
		}

		// Build HTML image
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		var img = new js.html.Image(subPixels.width, subPixels.height);
		img.src = 'data:image/png;base64,$b64';
		return img;
	}


	public function iconToJqueryImage(iconId:String, size=48) : js.jquery.JQuery {
		var jImg = new J( iconToHtmlImage(iconId) );
		jImg.css({
			width:size+"px",
			height:size+"px",
			imageRendering: "pixelated",
		});

		return jImg;
	}


	inline function getOtherValueForMatrix() {
		return otherValue==0 ? -mainValue : otherValue;
	}

	function createRule(rg:AutoLayerRuleGroupDef, f:WallFragment) {
		if( !fragments.exists(f) )
			return false;

		var m = getRuleMatrixFromFragment(f);
		var size = m[0].length;

		var rd = new data.def.AutoLayerRuleDef(project.generateUniqueId_int(), size);
		rg.rules.push(rd);

		// Fill rule matrix
		for(cy in 0...size)
		for(cx in 0...size) {
			var c = m[cy].charAt(cx);
			rd.setPattern(cx,cy, switch c {
				case "x": getOtherValueForMatrix();
				case "o": mainValue;
				case _: 0;
			});
		}

		// Update tile IDs
		rd.tileRectsIds = fragments.get(f).map( tid->[tid] );

		// Out of bounds policy
		rd.outOfBoundsValue = mainValue;

		// Break on match flag
		// var opaque = true;
		// for(tid in rd.tileIds)
		// 	if( !td.isTileOpaque(tid) ) {
		// 		opaque = false;
		// 		break;
		// 	}
		rd.breakOnMatch = breakOnMatch;

		// Update flip X/Y flags
		for(e in _allFragmentEnums)
			if( isSymetricalAltFor(f, e) && !fragments.exists(e) ) {
				var alt = getSymetricalAlternative(e);
				if( alt.flipX )
					rd.flipX = true;
				if( alt.flipY )
					rd.flipY = true;
			}

		// Trim & cleanup
		rd.updateUsedValues();
		rd.tidy(ld);

		return true;
	}



	function createRules() {
		if( editedGroup!=null )
			editedGroup.rules = [];

		var rg = editedGroup!=null ? editedGroup : ld.createEmptyRuleGroup(project.generateUniqueId_int(), groupName, 0);
		rg.name = groupName;
		rg.usesWizard = true;
		for(f in _allFragmentEnums)
			createRule( rg, f );

		return rg;
	}

}