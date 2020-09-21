package ui;

class EntityInstanceEditor extends dn.Process {
	public static var CURRENT : Null<EntityInstanceEditor> = null;

	var jPanel : js.jquery.JQuery;
	var ei : led.inst.EntityInstance;
	var link : h2d.Graphics;

	public function new(ei:led.inst.EntityInstance) {
		super(Editor.ME);

		CURRENT = this;
		this.ei = ei;
		Editor.ME.ge.addGlobalListener(onGlobalEvent);

		link = new h2d.Graphics();
		Editor.ME.root.add(link, Const.DP_UI);

		jPanel = new J('<div class="entityInstanceEditor"/>');
		App.ME.jBody.append(jPanel);

		updateForm();
		renderLink();
	}

	override function onDispose() {
		super.onDispose();

		jPanel.remove();
		jPanel = null;

		link.remove();
		link = null;

		ei = null;

		if( CURRENT==this )
			CURRENT = null;
		Editor.ME.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, EntityFieldDefChanged(_), EntityFieldSorted:
				if( ei==null || ei.def==null )
					destroy();
				else
					updateForm();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:
				updateForm();

			case ViewportChanged:
				renderLink();

			case _:
		}
	}

	function renderLink() {
		jPanel.css("border-color", C.intToHex(ei.def.color));
		var win = js.Browser.window;
		var render = Editor.ME.levelRender;
		link.clear();
		link.lineStyle(2*win.devicePixelRatio, ei.def.color);
		link.moveTo(
			render.levelToUiX(ei.x),
			render.levelToUiY(ei.y)
		);
		link.lineTo(
			Editor.ME.canvasWid() - jPanel.outerWidth()*win.devicePixelRatio,
			Editor.ME.canvasHei()*0.5
		);
	}

	public static function close() {
		if( CURRENT!=null && !CURRENT.destroyed ) {
			CURRENT.destroy();
			CURRENT = null;
			return true;
		}
		else
			return false;
	}

	function onFieldChange() {
		updateForm();
		var editor = Editor.ME;
		editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
		editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
		editor.ge.emit( EntityInstanceFieldChanged(ei) );
	}


	function hideInputIfDefault(arrayIdx:Int, input:js.jquery.JQuery, fi:led.inst.FieldInstance) {
		input.off(".def").removeClass("usingDefault");

		if( fi.isUsingDefault(arrayIdx) ) {
			if( !input.is("select") ) {
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
		else if( fi.def.type==F_Color || fi.def.type==F_Bool ) {
			// BOOL or COLOR requiring a "Reset to default" link
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


	function createInputFor(fi:led.inst.FieldInstance, arrayIdx:Int, jTarget:js.jquery.JQuery) {
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
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","color");
				input.val( fi.getColorAsHexStr(arrayIdx) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

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

			case F_String:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","text");
				var def = fi.def.getStringDefault();
				input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( fi.getString(arrayIdx) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

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


	function updateForm() {
		jPanel.empty();
		var jHeader = new J('<header/>');
		jHeader.appendTo(jPanel);
		jHeader.append('<div>${ei.def.identifier}</div>');
		var jEdit = new J('<a class="edit">Edit</a>');
		jEdit.click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs();
		});
		jHeader.append(jEdit);

		if( ei.def.fieldDefs.length==0 )
			jPanel.append('<div class="empty">This entity has no custom field.</div>');
		else {
			var form = new J('<ul class="form"/>');
			form.appendTo(jPanel);
			for(fd in ei.def.fieldDefs) {
				var fi = ei.getFieldInstance(fd);
				var li = new J("<li/>");
				li.appendTo(form);
				li.append('<label>${fi.def.identifier}</label>');

				if( !fd.isArray ) {
					// Single value
					createInputFor(fi, 0, li);
				}
				else {
					// Array
					var jArray = new J('<div class="array"/>');
					jArray.appendTo(li);
					if( fd.arrayMinLength!=null && fi.getArrayLength()<fd.arrayMinLength
						|| fd.arrayMaxLength!=null && fi.getArrayLength()>fd.arrayMaxLength ) {
						var bounds : String =
							fd.arrayMinLength==fd.arrayMaxLength ? Std.string(fd.arrayMinLength)
							: fd.arrayMaxLength==null ? fd.arrayMinLength+"+"
							: fd.arrayMinLength+"-"+fd.arrayMaxLength;
						jArray.append('<div class="warning">Array should have $bounds value(s)</div>');
					}

					for(i in 0...fi.getArrayLength()) {
						createInputFor(fi, i, jArray);

						// "Remove" button
						var jRemove = new J('<button class="remove dark">x</button>');
						jRemove.appendTo(jArray);
						var idx = i;
						jRemove.click( function(_) {
							fi.removeArrayValue(idx);
							Editor.ME.ge.emit( EntityInstanceFieldChanged(ei) );
							updateForm();
						});
					}
					// "Add" button
					if( fi.def.arrayMaxLength==null || fi.getArrayLength()<fi.def.arrayMaxLength ) {
						var jAdd = new J('<button class="add">+</button>');
						jAdd.appendTo(jArray);
						jAdd.click( function(_) {
							fi.addArrayValue();
							Editor.ME.ge.emit( EntityInstanceFieldChanged(ei) );
							updateForm();
						});
					}
				}
			}
		}

		// Position panel
		var wh = js.Browser.window.innerHeight;
		var h = jPanel.outerHeight();
		jPanel.css("top", Std.int(wh*0.5 - h*0.5)+"px");
	}
}