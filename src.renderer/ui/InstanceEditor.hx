package ui;

class InstanceEditor<T> extends dn.Process {
	public static var CURRENT : Null<InstanceEditor<T>> = null;

	var jPanel : js.jquery.JQuery;
	var inst : T;
	var link : h2d.Graphics;

	private function new(inst:T) {
		super(Editor.ME);

		closeAny();
		CURRENT = this;
		this.inst = inst;
		Editor.ME.ge.addGlobalListener(onGlobalEvent);

		link = new h2d.Graphics();
		Editor.ME.root.add(link, Const.DP_UI);

		jPanel = new J('<div class="instanceEditor"/>');
		App.ME.jPage.append(jPanel);

		updateForm();
	}

	override function onResize() {
		super.onResize();

		jPanel.css({
			left : js.Browser.window.innerWidth - jPanel.outerWidth(),
			top : Std.int(js.Browser.window.innerHeight*0.5 - jPanel.outerHeight()*0.5)+"px",
		});
	}

	override function onDispose() {
		super.onDispose();

		jPanel.remove();
		jPanel = null;

		link.remove();
		link = null;

		inst = null;

		if( CURRENT==this )
			CURRENT = null;
		Editor.ME.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case LayerInstanceSelected:
				close();

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				close(); // TODO do softer refresh?

			case ViewportChanged :
				renderLink();

			case _:
		}
	}


	function renderLink() {} // should be overriden

	final function drawLink(c:UInt, worldX:Int, worldY:Int) {
		jPanel.css("border-color", C.intToHex(c));
		var cam = Editor.ME.camera;
		var render = Editor.ME.levelRender;
		link.clear();
		link.lineStyle(4*cam.pixelRatio, c, 0.33);
		var coords = Coords.fromWorldCoords(worldX, worldY);
		link.moveTo(coords.canvasX, coords.canvasY);
		link.lineTo(
			cam.width - jPanel.outerWidth() * cam.pixelRatio,
			cam.height*0.5
		);
	}

	public static function existsFor(inst:Dynamic) {
		return isOpen() && CURRENT.inst==inst;
	}

	public static inline function isOpen() {
		return CURRENT!=null && !CURRENT.destroyed;
	}

	public static function closeAny() {
		if( isOpen() ) {
			CURRENT.close();
			CURRENT = null;
			return true;
		}
		else
			return false;
	}

	function close() {
		destroy();
	}


	function hideInputIfDefault(arrayIdx:Int, input:js.jquery.JQuery, fi:data.inst.FieldInstance) {
		input.off(".def").removeClass("usingDefault");

		if( fi.isUsingDefault(arrayIdx) ) {
			if( input.is("button") ) {
				// Button input
				if( fi.def.type!=F_Point || fi.def.canBeNull )
					input.addClass("gray usingDefault");
			}
			else if( input.is("[type=color]") ) {
				// Color input
				input.addClass("usingDefault");
				input.text("default");
			}
			else if( input.is(".colorWrapper") ) {
				// Wrapped color input
				input.addClass("usingDefault");
			}
			else if( !input.is("select") ) {
				// General INPUT
				var jRep = new J('<a class="usingDefault" href="#"/>');
				if( input.is("[type=checkbox]") ) {
					var chk = new J('<input type="checkbox"/>');
					chk.prop("checked", fi.getBool(arrayIdx));
					jRep.append( chk.wrap('<span class="value"/>').parent() );
					jRep.addClass("checkbox");
				}
				else
					jRep.append('<span class="value">${fi.getForDisplay(arrayIdx)}</span>');
				jRep.append('<span class="label">Default</span>');
				jRep.on("click.def", function(ev) {
					ev.preventDefault();
					jRep.remove();
					input.show().focus();
					if( input.is("[type=checkbox]") ) {
						input.prop("checked", !fi.getBool(arrayIdx));
						input.change();
					}
				});
				jRep.insertBefore(input);
				input.hide();

				input.on("blur.def", function(ev) {
					jRep.remove();
					hideInputIfDefault(arrayIdx, input,fi);
				});
			}
			else if( input.is("select") && ( fi.getEnumValue(arrayIdx)!=null || fi.def.canBeNull ) ) {
				// SELECT case
				input.addClass("usingDefault");
				input.on("click.def", function(ev) {
					input.removeClass("usingDefault");
				});
				input.on("blur.def", function(ev) {
					hideInputIfDefault(arrayIdx, input,fi);
				});
			}
		}
		else if( fi.def.type==F_Color || fi.def.type==F_Bool || fi.def.type==F_Point && fi.def.canBeNull ) {
			// Require a "Reset to default" link
			var span = input.wrap('<span class="inputWithDefaultOption"/>').parent();
			span.find("input").wrap('<span class="value"/>');
			var defLink = new J('<a class="reset" href="#">[ Reset ]</a>');
			defLink.appendTo(span);
			defLink.on("click.def", function(ev) {
				fi.parseValue(arrayIdx, null);
				onFieldChange();
				ev.preventDefault();
			});
		}
	}


	function createInputFor(fi:data.inst.FieldInstance, arrayIdx:Int, jTarget:js.jquery.JQuery) {
		switch fi.def.type {
			case F_Int:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","text");
				input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( Std.string(fi.getInt(arrayIdx)) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

			case F_Color:
				var cHex = fi.getColorAsHexStr(arrayIdx);

				var jWrapper = new J('<label class="colorWrapper"/>');
				jWrapper.appendTo(jTarget);
				jWrapper.css({
					backgroundColor: cHex,
					borderColor: C.intToHex( C.toWhite( C.hexToInt(cHex), 0.2 ) ),
				});
				if( fi.isUsingDefault(arrayIdx) )
					jWrapper.append("(default)");

				var input = new J("<input/>");
				input.appendTo(jWrapper);
				input.attr("type","color");
				input.addClass("advanced");
				input.val(cHex);
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});

				hideInputIfDefault(arrayIdx, jWrapper, fi);

			case F_Float:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","text");
				input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( Std.string(fi.getFloat(arrayIdx)) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

			case F_String, F_Text:
				var input = if( fi.def.type==F_Text ) {
					var input = new J("<textarea/>");
					input.appendTo(jTarget);
					input.keyup( (ev)-> {
						input.css("height","auto");
						if( input.height() < input.get(0).scrollHeight ) {
							var padding = input.innerHeight() - input.height();
							input.height( input.get(0).scrollHeight+3 - padding );
						}
					});
					input;
				}
				else {
					var input = new J("<input/>");
					input.appendTo(jTarget);
					input.attr("type","text");
					input;
				}
				var def = fi.def.getStringDefault();
				input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( fi.getString(arrayIdx) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				if( fi.def.type==F_Text )
					input.keyup();
				hideInputIfDefault(arrayIdx, input, fi);

			case F_Point:
				if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull || !fi.def.isArray ) {
					// Button mode
					var jPick = new J('<button/>');
					if( !fi.valueIsNull(arrayIdx) )
						jPick.addClass("gray");
					jPick.appendTo(jTarget);
					jPick.addClass("point");
					if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull ) {
						jPick.addClass("required");
						jPick.text( "Point required!" );
					}
					else
						jPick.text( fi.valueIsNull(arrayIdx) ? "--none--" : fi.getPointStr(arrayIdx) );
					jPick.click( function(_) {
						if( Editor.ME.isSpecialToolActive(tool.PickPoint) ) {
							// Cancel
							Editor.ME.clearSpecialTool();
							updateForm();
						}
						else {
							// Start picking
							jPick.text("Cancel");
							startPointsEditing(fi, arrayIdx);
						}
					});

					if( fi.def.canBeNull && !fi.valueIsNull(arrayIdx) ) {
						var jRem = new J('<button class="dark removePoint">x</button>');
						jRem.appendTo(jTarget);
						jRem.click( (_)->{
							fi.parseValue(arrayIdx,null);
							onFieldChange();
						});
					}
				}
				else {
					// Text mode
					var jPoint = new J('<span class="point"/>');
					jPoint.appendTo(jTarget);
					jPoint.text( fi.getPointStr(arrayIdx) );
				}


			case F_Enum(name):
				var ed = Editor.ME.project.defs.getEnumDef(name);
				var select = new J("<select/>");
				select.appendTo(jTarget);

				// Null value
				if( fi.def.canBeNull || fi.getEnumValue(arrayIdx)==null ) {
					var opt = new J('<option/>');
					opt.appendTo(select);
					opt.attr("value","");
					if( fi.def.canBeNull )
						opt.text("-- null --");
					else {
						// SELECT shouldn't be null
						select.addClass("required");
						opt.text("[ Value required ]");
						select.click( function(ev) {
							select.removeClass("required");
							select.blur( function(ev) updateForm() );
						});
					}
					if( fi.getEnumValue(arrayIdx)==null )
						opt.attr("selected","selected");
				}

				for(v in ed.values) {
					var opt = new J('<option/>');
					opt.appendTo(select);
					opt.attr("value",v.id);
					opt.text(v.id);
					if( fi.getEnumValue(arrayIdx)==v.id && !fi.isUsingDefault(arrayIdx) )
						opt.attr("selected","selected");
				}

				select.change( function(ev) {
					var v = select.val()=="" ? null : select.val();
					fi.parseValue(arrayIdx, v);
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, select, fi);

			case F_Bool:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","checkbox");
				input.prop("checked",fi.getBool(arrayIdx));
				input.change( function(ev) {
					fi.parseValue( arrayIdx, Std.string( input.prop("checked") ) );
					onFieldChange();
				});

				hideInputIfDefault(arrayIdx, input, fi);
		}
	}

	function getInstanceCx() return -1;
	function getInstanceCy() return -1;
	function getInstanceColor() : UInt return 0x0;

	function startPointsEditing(fi:data.inst.FieldInstance, editIdx:Int) {
		jPanel.addClass("picking");

		var t = new tool.PickPoint();

		t.pickOrigin = { cx:getInstanceCx(), cy:getInstanceCy(), color:getInstanceColor() }

		// Connect to last of path
		if( fi.def.isArray && fi.def.editorDisplayMode==PointPath ) {
			var pt = fi.getPointGrid( editIdx-1 );
			if( pt!=null )
				t.pickOrigin = { cx:pt.cx, cy:pt.cy, color:getInstanceColor() }
		}

		// Picking of a point
		t.onPick = function(m) {
			if( this.destroyed )
				return;

			if( fi.def.isArray && editIdx>=fi.getArrayLength()-1 ) {
				// Append points in an array
				fi.parseValue(editIdx, m.cx+Const.POINT_SEPARATOR+m.cy);
				editIdx = fi.getArrayLength();

				if( fi.def.editorDisplayMode==PointPath ) {
					// Connect to path previous
					var pt = fi.getPointGrid( editIdx-1 );
					if( pt!=null )
						t.pickOrigin = { cx:pt.cx, cy:pt.cy, color:getInstanceColor() }
				}
			}
			else {
				// Edit a single point
				Editor.ME.clearSpecialTool();
				fi.parseValue(editIdx, m.cx+Const.POINT_SEPARATOR+m.cy);
			}
			onFieldChange(true);
			jPanel.addClass("picking");
		}

		// Tool stopped
		t.onDisposeCb = function() {
			if( !destroyed )
				updateForm();
		}

		Editor.ME.setSpecialTool(t);
	}



	function onFieldChange(keepCurrentSpecialTool=false) {
		if( !keepCurrentSpecialTool )
			Editor.ME.clearSpecialTool();

		updateForm();
	}


	function renderForm() {}
	final function updateForm() {
		jPanel.empty();
		jPanel.removeClass("picking");

		renderForm();
		if( destroyed )
			return;

		JsTools.parseComponents(jPanel);
		renderLink();

		// Re-position
		onResize();
	}
}