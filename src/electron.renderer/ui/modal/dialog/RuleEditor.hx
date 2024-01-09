package ui.modal.dialog;

import data.DataTypes;

class RuleEditor extends ui.modal.Dialog {
	var curValue = -1;
	var layerDef : data.def.LayerDef;
	var sourceDef : data.def.LayerDef;
	var rule : data.def.AutoLayerRuleDef;
	var guidedMode = false;
	var hasAnyChange = false;

	public function new(layerDef:data.def.LayerDef, rule:data.def.AutoLayerRuleDef) {
		super("ruleEditor");

		if( rule.size<Const.MAX_AUTO_PATTERN_SIZE )
			rule.resize(Const.MAX_AUTO_PATTERN_SIZE);

		setTransparentMask();
		this.layerDef = layerDef;
		this.rule = rule;
		sourceDef = layerDef.type==IntGrid ? layerDef : project.defs.getLayerDef( layerDef.autoSourceLayerDefUid );

		// Smart pick current IntGrid value
		curValue = -1;
		var counts = new Map();
		var best = -1;
		for(cy in 0...rule.size)
		for(cx in 0...rule.size) {
			var v = M.iabs( rule.getPattern(cx,cy) );
			if( v==0 || v==Const.AUTO_LAYER_ANYTHING )
				continue;

			if( !counts.exists(v) )
				counts.set(v,1);
			else
				counts.set(v,counts.get(v)+1);

			if( best<0 || counts.get(best)<counts.get(v) )
				best = v;
		}
		curValue = best;

		// Default current value
		if( curValue<0 )
			for(iv in sourceDef.getAllIntGridValues()) {
				curValue = iv.value;
				break;
			}
		if( curValue==-1 )
			curValue = Const.AUTO_LAYER_ANYTHING;

		renderAll();
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch(e) {
			case LayerRuleChanged(rule):

			case _:
		}
	}

	function enableGuidedMode() {
		guidedMode = true;
		jContent.addClass("guided");
		jContent.find(".disableTip").removeClass("disableTip");
		jContent.find(".explain").show();
	}


	override function close() {
		rule.trim();
		rule.updateUsedValues();

		super.close();

		if( rule.isEmpty() ) {
			// Kill empty
			for(rg in layerDef.autoRuleGroups)
				rg.rules.remove(rule);
			editor.ge.emit( LayerRuleRemoved(rule, false) );
		}
		else {
			rule.tidy(layerDef);
			if( hasAnyChange ) {
				editor.ge.emit( LayerRuleChanged(rule) );
				N.msg("Rule updated");
			}
		}
	}


	function onAnyRuleChange() {
		hasAnyChange = true;
		// editor.ge.emit( LayerRuleChanged(rule) );
	}


	function updateTileSettings() {
		var jTilesSettings = jContent.find(".tileSettings");
		jTilesSettings.off();

		// Tile mode
		var jModeSelect = jContent.find("select[name=tileMode]");
		jModeSelect.empty();
		var i = new form.input.EnumSelect(
			jModeSelect,
			ldtk.Json.AutoLayerRuleTileMode,
			()->rule.tileMode,
			(v)->rule.tileMode = v,
			(v)->switch v {
				case Single: Lang.t._("Individual tiles");
				case Stamp: Lang.t._("Rectangles of tiles");
			}
		);
		i.onChange = function() {
			onAnyRuleChange();
			rule.tileRectsIds = [];
			updateTileSettings();
		}

		// Tile(s)
		var jTileRects = jTilesSettings.find(">.tileRects").empty();
		function _pickTiles(rectIdx:Int) {
			var pickerTids = rectIdx<0 || rule.tileRectsIds.length==0 ? [] : switch rule.tileMode {
				case Single: rule.tileRectsIds.map( tids->tids[0] );
				case Stamp: rule.tileRectsIds[rectIdx];
			}
			JsTools.openTilePickerModal(
				Editor.ME.curLayerInstance.getTilesetUid(),
				rule.tileMode==Single ? MultipleIndividuals : TileRectAndClose,
				pickerTids,
				false,
				function(tids) {
					if( tids.length>0 ) {
						switch rule.tileMode {
							case Single:
								rule.tileRectsIds = tids.map( tid->[tid] );

							case Stamp:
								if( rectIdx<0 )
									rule.tileRectsIds.push( tids.copy() );
								else
									rule.tileRectsIds[rectIdx] = tids.copy();
						}
					}
					updateTileSettings();
					onAnyRuleChange();
				}
			);
		}
		var jAllTiles = new J('<div class="allTiles"/>');
		jAllTiles.appendTo(jTileRects);
		var td = project.defs.getTilesetDef(layerDef.tilesetDefUid);
		if( td==null )
			jAllTiles.append('<div class="error">Invalid tileset</div>');
		else {
			switch rule.tileMode {
				case Single:
					for(rectIds in rule.tileRectsIds)
						jAllTiles.append( td.createTileHtmlImageFromTileId(rectIds[0]) );
					jAllTiles.addClass("clickable");
					jAllTiles.click( _->_pickTiles(0) );

				case Stamp:
					var rectIdx = 0;
					for(rectIds in rule.tileRectsIds) {
						var rect = td.getTileRectFromTileIds(rectIds);
						var jImg = td.createTileHtmlImageFromRect(rect);
						jImg.addClass("clickable");
						Tip.attach(jImg, "Left click to change\nRight click to remove");
						var i = rectIdx;
						jImg.mousedown( (ev:js.jquery.Event)->{
							switch ev.button {
								case 0:
									_pickTiles(i);

								case 1,2:
									rule.tileRectsIds.splice(i,1);
									onAnyRuleChange();
									updateTileSettings();
							}
						});
						jAllTiles.append( jImg );
						rectIdx++;
					}
					if( rule.tileRectsIds.length>0 ) {
						var jAdd = new J('<button> <span class="icon add"></span> </button>');
						jAdd.appendTo(jAllTiles);
						jAdd.click( _->_pickTiles(-1) );
					}
					else {
						jAllTiles.addClass("clickable");
						jAllTiles.click( _->_pickTiles(0) );
					}
			}
		}


		// Pivot (optional)
		var jTileOptions = jTilesSettings.find(">.options").empty();
		switch rule.tileMode {
			case Single:
			case Stamp:
				var jPivot = JsTools.createPivotEditor(rule.pivotX, rule.pivotY, (xr,yr)->{
					rule.pivotX = xr;
					rule.pivotY = yr;
					onAnyRuleChange();
					renderAll();
				});
				jTileOptions.append(jPivot);
		}

		JsTools.parseComponents(jTilesSettings);
	}



	function updateValuePalette() {
		var jValuePalette = jContent.find(">.pattern .valuePalette>ul").empty();

		// Values view mode
		var stateId = settings.makeStateId(RuleValuesColumns, layerDef.uid);
		var columns = settings.getUiStateInt(stateId, project, 5);
		JsTools.removeClassReg(jValuePalette, ~/col-[0-9]+/g);
		jValuePalette.addClass("col-"+columns);

		// View select
		var jMode = jContent.find(".displayMode");
		jMode.off().click(_->{
			var m = new ContextMenu(jMode);
			m.addAction({
				label:L.t._("List"),
				iconId: "listView",
				cb: ()->{
					settings.deleteUiState(stateId, project);
					updateValuePalette();
				}
			});
			for(n in [2,3,4,5,6,7,8,9,10]) {
				m.addAction({
					label:L.t._("::n:: columns", {n:n}),
					iconId: "gridView",
					cb: ()->{
						settings.setUiStateInt(stateId, n, project);
						updateValuePalette();
					}
				});
			}
		});

		// Groups
		for(g in sourceDef.getGroupedIntGridValues()) {
			if( g.all.length==0 )
				continue;

			var groupValue = sourceDef.getRuleValueFromGroupUid(g.groupUid);

			var jHeader = new J('<li class="title"/>');
			jHeader.append('<span class="icon folderClose"/>');
			if( sourceDef.hasIntGridGroups() ) {
				jHeader.appendTo(jValuePalette);
				jHeader.append('<span class="name">${g.displayName}</span>');

				jHeader.click(_->{
					curValue = groupValue;
					updateValuePalette();
				});
			}

			var jSubList = new J('<li class="subList"> <ul class="groupValues"></ul> </li>');
			jSubList.appendTo(jValuePalette);

			if( g.color!=null ) {
				var alpha = curValue==groupValue ? 1 : 0.4;
				jHeader.css("background-color", g.color.toCssRgba(0.8*alpha));
				jSubList.css("background-color", g.color.toCssRgba(0.5*alpha));
			}

			if( curValue==groupValue )
				jHeader.add(jSubList).addClass("active");

			// Individual values
			jSubList = jSubList.find("ul");
			for(v in g.all) {
				var jVal = new J('<li class="value"/>');
				jVal.appendTo(jSubList);
				jVal.css("background-color", C.intToHex(v.color));
				jVal.append( JsTools.createIntGridValue(project, v, false) );
				jVal.append('<span class="name">${v.identifier!=null ? v.identifier : Std.string(v.value)}</span>');
				jVal.find(".name").css("color", C.intToHex( C.autoContrast(v.color) ) );

				if( curValue==v.value )
					jVal.addClass("active");

				var id = v.value;
				jVal.click( function(ev) {
					curValue = id;
					updateValuePalette();
				});
			}
		}

		// "Anything" value
		var jVal = new J('<li/>');
		jVal.appendTo(jValuePalette);
		jVal.addClass("any");
		jVal.append('<span class="value"></span>');
		var label = '"Any value" / "No value"';
		jVal.append('<span class="name">$label</span>');
		if( curValue==Const.AUTO_LAYER_ANYTHING )
			jVal.addClass("active");
		jVal.click( function(ev) {
			curValue = Const.AUTO_LAYER_ANYTHING;
			onAnyRuleChange();
			updateValuePalette();
		});
	}


	function renderAll() {

		loadTemplate("ruleEditor");
		jContent.find("[data-title],[title]").addClass("disableTip"); // removed on guided mode

		// Mini explanation tip
		var jExplain = jContent.find(".explain").hide();

		// Guided mode button
		jContent.find("button.guide").click( (_)->{
			enableGuidedMode();
		} );
		jContent.find(".debugInfos").text('#${rule.uid}');

		updateTileSettings();

		// Pattern grid editor
		var patternEditor = new RulePatternEditor(
			rule, sourceDef, layerDef,
			(str:String)->{
				if( str==null )
					jExplain.empty();
				else {
					if( str.indexOf("\\n")>=0 )
						str = "<p>" + str.split("\\n").join("</p><p>") + "</p>";
					jExplain.html(str);
				}
			},
			()->curValue,
			()->onAnyRuleChange()
		);
		jContent.find(">.pattern .editor .grid").empty().append( patternEditor.jRoot );

		// Out-of-bounds policy
		var jOutOfBounds = jContent.find("#outOfBoundsValue");
		JsTools.createOutOfBoundsRulePolicy(jOutOfBounds, sourceDef, rule.outOfBoundsValue, (v)->{
			rule.outOfBoundsValue = v;
			onAnyRuleChange();
			renderAll();
		});

		// Finalize
		updateValuePalette();
		if( guidedMode )
			enableGuidedMode();

		JsTools.parseComponents(jContent);
	}

}