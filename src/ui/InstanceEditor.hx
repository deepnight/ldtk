package ui;

class InstanceEditor extends dn.Process {
	public static var ALL : Array<InstanceEditor> = [];

	var jPanel : js.jquery.JQuery;
	var ei : led.inst.EntityInstance;

	public function new(ei:led.inst.EntityInstance) {
		super(Client.ME);

		ALL.push(this);
		this.ei = ei;
		Client.ME.ge.addGlobalListener(onGlobalEvent);

		jPanel = new J('<div class="instanceEditor"/>');
		App.ME.jBody.append(jPanel);
		updateForm();
	}

	override function onDispose() {
		super.onDispose();

		jPanel.remove();
		jPanel = null;

		ei = null;

		ALL.remove(this);
		Client.ME.ge.removeListener(onGlobalEvent);
	}

	function onGlobalEvent(ge:GlobalEvent) {
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, EntityFieldDefChanged, EntityFieldSorted:
				if( ei==null || ei.def==null )
					destroy();
				else
					updateForm();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted:
				updateForm();

			case _:
		}
	}

	public static function closeAll() {
		for(e in ALL)
			e.destroy();
	}

	function onFieldChange() {
		updateForm();
		var client = Client.ME;
		client.curLevelHistory.saveLayerState( client.curLayerInstance );
		client.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
		client.ge.emit(EntityFieldInstanceChanged);
	}


	function hideInputIfDefault(input:js.jquery.JQuery, fi:led.inst.FieldInstance) {
		input.off(".def").removeClass("usingDefault");

		if( fi.isUsingDefault() ) {
			if( !input.is("select") ) {
				// General INPUT
				var jRep = new J('<a class="usingDefault" href="#"/>');
				if( input.is("[type=checkbox]") ) {
					var chk = new J('<input type="checkbox"/>');
					chk.prop("checked", fi.getBool());
					jRep.append( chk.wrap('<span class="value"/>').parent() );
					jRep.addClass("checkbox");
				}
				else
					jRep.append('<span class="value">${fi.getForDisplay()}</span>');
				jRep.append('<span class="label">Default</span>');
				jRep.on("click.def", function(ev) {
					ev.preventDefault();
					jRep.remove();
					input.show().focus();
					if( input.is("[type=checkbox]") ) {
						input.prop("checked", !fi.getBool());
						input.change();
					}
				});
				jRep.insertBefore(input);
				input.hide();

				input.on("blur.def", function(ev) {
					jRep.remove();
					hideInputIfDefault(input,fi);
				});
			}
			else if( input.is("select") && ( fi.getEnumValue()!=null || fi.def.canBeNull ) ) {
				// SELECT case
				input.addClass("usingDefault");
				input.on("click.def", function(ev) {
					input.removeClass("usingDefault");
				});
				input.on("blur.def", function(ev) {
					hideInputIfDefault(input,fi);
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
				fi.parseValue(null);
				onFieldChange();
				ev.preventDefault();
			});
		}
	}

	function updateForm() {
		jPanel.empty();
		jPanel.append("<h2>"+ei.def.identifier+"</h2>");

		var form = new J('<ul class="form"/>');
		form.appendTo(jPanel);
		for(fd in ei.def.fieldDefs) {
			var fi = ei.getFieldInstance(fd);
			var li = new J("<li/>");
			li.appendTo(form);
			li.append('<label>${fi.def.identifier}</label>');

			switch fi.def.type {
				case F_Int:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","text");
					input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
					if( !fi.isUsingDefault() )
						input.val( Std.string(fi.getInt()) );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});
					hideInputIfDefault(input, fi);

				case F_Color:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","color");
					input.val( fi.getColorAsHexStr() );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});
					hideInputIfDefault(input, fi);

				case F_Float:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","text");
					input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
					if( !fi.isUsingDefault() )
						input.val( Std.string(fi.getFloat()) );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});
					hideInputIfDefault(input, fi);

				case F_String:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","text");
					var def = fi.def.getStringDefault();
					input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
					if( !fi.isUsingDefault() )
						input.val( fi.getString() );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});
					hideInputIfDefault(input, fi);

				case F_Enum(name):
					var ed = Client.ME.project.defs.getEnumDef(name);
					var select = new J("<select/>");
					select.appendTo(li);

					// Null value
					if( fi.def.canBeNull || fi.getEnumValue()==null ) {
						var opt = new J('<option/>');
						opt.appendTo(select);
						opt.attr("value","");
						if( fi.def.canBeNull )
							opt.text("-- null --");
						else {
							// SELECT shouldn't be null
							select.addClass("required");
							opt.text("[ Select one ]");
							select.click( function(ev) {
								select.removeClass("required");
								select.blur( function(ev) updateForm() );
							});
						}
						if( fi.getEnumValue()==null )
							opt.attr("selected","selected");
					}

					for(v in ed.values) {
						var opt = new J('<option/>');
						opt.appendTo(select);
						opt.attr("value",v);
						opt.text(v);
						if( fi.getEnumValue()==v && !fi.isUsingDefault() )
							opt.attr("selected","selected");
					}

					select.change( function(ev) {
						var v = select.val()=="" ? null : select.val();
						fi.parseValue(v);
						onFieldChange();
					});
					hideInputIfDefault(select, fi);

				case F_Bool:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","checkbox");
					input.prop("checked",fi.getBool());
					input.change( function(ev) {
						fi.parseValue( Std.string( input.prop("checked") ) );
						onFieldChange();
					});

					hideInputIfDefault(input, fi);
			}
		}
	}
}