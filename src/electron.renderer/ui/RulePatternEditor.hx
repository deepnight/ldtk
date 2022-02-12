package ui;

class RulePatternEditor {
	public var jRoot : js.jquery.JQuery;

	var rule : data.def.AutoLayerRuleDef;
	var sourceDef : data.def.LayerDef;
	var layerDef : data.def.LayerDef;
	var previewMode : Bool;
	var explainCell : Null< (desc:Null<String>)->Void >;
	var getSelectedValue: Null< Void->Int >;
	var onChange: Null< Void->Void >;

	var drawButton = -1;
	var valueAtStartPoint : Null<Int> = null; // value when clicking starts

	public function new(
		rule: data.def.AutoLayerRuleDef,
		sourceDef: data.def.LayerDef,
		layerDef: data.def.LayerDef,
		previewMode=false,
		?explainCell: (desc:Null<String>)->Void,
		?getSelectedValue: Void->Int,
		?onChange: Void->Void
	) {
		this.rule = rule;
		this.sourceDef = sourceDef;
		this.layerDef = layerDef;
		this.previewMode = previewMode;
		this.explainCell = explainCell;
		this.getSelectedValue = getSelectedValue;
		this.onChange = onChange;

		valueAtStartPoint = null;
		jRoot = new J('<div/>');

		render();
	}


	inline function isEditable() return onChange!=null;


	function render() {
		// Init root
		jRoot.empty().off();
		jRoot.removeClass();
		jRoot.addClass("autoPatternGrid");
		jRoot.addClass("size-"+rule.size);

		if( isEditable() )
			jRoot.addClass("editable");

		if( previewMode )
			jRoot.addClass("preview");

		// Add a rollover tip
		function addExplain(jTarget:js.jquery.JQuery, desc:String) {
			if( explainCell==null )
				return;

			jTarget
				.mouseover( function(_) {
					explainCell(desc);
				})
				.mouseout( function(_) {
					explainCell(null);
				});
		}

		var buttonDown = -1;

		for(cy in 0...rule.size)
		for(cx in 0...rule.size) {
			var coordId = cx+cy*rule.size;
			var isCenter = cx==Std.int(rule.size/2) && cy==Std.int(rule.size/2);

			// Cell wrapper
			var jCell = new J('<div class="cell"/>');
			jCell.appendTo(jRoot);
			if( isEditable() )
				jCell.addClass("editable");

			// Center guide
			if( isCenter ) {
				switch rule.tileMode {
					case Single:
						jCell.addClass("center");

					case Stamp:
						var jStampPreview = new J('<div class="stampPreview"/>');
						jStampPreview.appendTo(jCell);
						var previewWid = 32;
						var previewHei = 32;
						if( rule.tileIds.length>1 ) {
							var td = Editor.ME.curLayerInstance.getTilesetDef();
							if( td!=null ) {
								var bounds = td.getTileGroupBounds(rule.tileIds);
								if( bounds.wid>1 )
									previewWid = Std.int( previewWid * 1.9 );
								if( bounds.hei>1 )
									previewHei = Std.int( previewHei * 1.9 );
							}
						}
						jStampPreview.css("width", previewWid + "px");
						jStampPreview.css("height", previewHei + "px");
						jStampPreview.css("left", ( rule.pivotX * (32-previewWid) ) + "px");
						jStampPreview.css("top", ( rule.pivotY * (32-previewHei) ) + "px");
				}

				// Render actual Tile in context
				if( previewMode ) {
					var td = Editor.ME.curLayerInstance.getTilesetDef();
					if( td!=null ) {
						var jTile = JsTools.createTile(td, rule.tileIds[0], 32);
						jCell.append(jTile);
						jCell.addClass("tilePreview");
						if( rule.tileIds.length>1 )
							jTile.addClass("multi");
					}
				}
			}

			// Cell color
			if( !isCenter || !previewMode ) {
				var ruleValue = rule.get(cx,cy);
				if( ruleValue!=0 ) {
					var intGridVal = M.iabs(ruleValue);
					if( ruleValue>0 ) {
						// Required value
						if( intGridVal == Const.AUTO_LAYER_ANYTHING ) {
							jCell.addClass("anything");
							addExplain(jCell, 'This cell should contain any IntGrid value to match.');
						}
						else if( sourceDef.hasIntGridValue(intGridVal) ) {
							jCell.css("background-color", C.intToHex( sourceDef.getIntGridValueDef(intGridVal).color ) );
							addExplain(jCell, 'This cell should contain "${sourceDef.getIntGridValueDisplayName(intGridVal)}" to match.');
						}
						else
							jCell.addClass("unknown");
					}
					else {
						// Forbidden value
						jCell.addClass("not");
						var icon = intGridVal!=Const.AUTO_LAYER_ANYTHING ? "cross" : "nothing";
						jCell.append('<span class="cellIcon $icon"></span>');

						if( intGridVal == Const.AUTO_LAYER_ANYTHING ) {
							jCell.addClass("anything");
							addExplain(jCell, 'This cell should NOT contain any IntGrid value to match.');
						}
						else if( sourceDef.hasIntGridValue(intGridVal) ) {
							jCell.css("background-color", C.intToHex( sourceDef.getIntGridValueDef(intGridVal).color ) );
							addExplain(jCell, 'This cell should NOT contain "${sourceDef.getIntGridValueDisplayName(intGridVal)}" to match.');
						}
						else
							jCell.addClass("error");
					}
				}
				else {
					// "Anything" value
					addExplain(jCell, 'This cell content doesn\'t matter.');
					jCell.addClass("empty");
				}
			}

			// Edit grid value
			if( isEditable() ) {

				var anyChange = false;
				function draw() {

					var v = rule.get(cx,cy);
					switch drawButton {
						case 0:
							// Require value
							if( valueAtStartPoint>=0 )
								rule.set(cx,cy, getSelectedValue());
							else if( v<0 )
								rule.set(cx,cy, 0);

						case 2:
							// Forbid value
							if( valueAtStartPoint==0 )
								rule.set(cx,cy, -getSelectedValue());
							else
								rule.set(cx,cy, 0);

						case 1:
							// Clear
							rule.set(cx,cy,0);

						case _:
					}

					// Refresh
					if( v!=rule.get(cx,cy) ) {
						anyChange = true;
						render();
					}

				}

				jCell.mousedown( (ev:js.jquery.Event)->{
					valueAtStartPoint = rule.get(cx,cy);
					drawButton = ev.button;
					App.ME.jBody.on("mouseup.rulePattern", (_)->{
						drawButton = -1;
						App.ME.jBody.off("mouseup.rulePattern");
						if( anyChange )
							onChange();
					});
					draw();
				});

				jCell.mousemove( function(ev) {
					if( drawButton>=0 )
						draw();
				});
			}
		}

		return jRoot;
	}
}