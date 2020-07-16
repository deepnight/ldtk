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
		Client.ME.jBody.append(jPanel);
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

	function hideInputDefault(input:js.jquery.JQuery, fi:led.inst.FieldInstance) {
		input.off(".def");

		if( fi.isUsingDefault() ) {
			var jRep = new J('<a class="formDefault" href="#"/>');
			jRep.append('<span class="value">${fi.getForDisplay()}</span>');
			jRep.append('<span class="label">(default)</span>');
			jRep.on("click.def", function(ev) {
				ev.preventDefault();
				jRep.remove();
				input.show().focus();

				// Using some hack to manually drop SELECT down
				// if( input.is("select") ) {
				// 	var event = new js.html.MouseEvent("click", {
				// 		view: js.Browser.window,
				// 		bubbles: true,
				// 		cancelable: true,
				// 	});
				// 	input.get(0).dispatchEvent(event);
				// }
			});
			jRep.insertBefore(input);
			input.hide();

			input.on("blur.def", function(ev) {
				jRep.remove();
				hideInputDefault(input,fi);
			});
		}

		// showDropdown = function (element) {
		// 	var event = js.Browser.document.createEvent('MouseEvents');
		// 	event.initMouseEvent('mousedown', true, true, js.Browser.window);
		// 	element.dispatchEvent(event);
		// };

		// // This isn't magic.
		// window.runThis = function () {
		// 	var dropdown = document.getElementById('dropdown');
		// 	showDropdown(dropdown);
		// };
	}

	function updateForm() {
		jPanel.empty();
		jPanel.append("<h2>"+ei.def.name+"</h2>");

		var form = new J('<ul class="form"/>');
		form.appendTo(jPanel);
		for(fd in ei.def.fieldDefs) {
			var fi = ei.getFieldInstance(fd);
			var li = new J("<li/>");
			li.appendTo(form);
			li.append('<label>${fi.def.name}</label>');

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
					hideInputDefault(input, fi);

				case F_Color:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","color");
					input.val( fi.getColorAsHexStr() );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});
					hideInputDefault(input, fi);

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
					hideInputDefault(input, fi);

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
					hideInputDefault(input, fi);

				case F_Enum(name):
					var ed = Client.ME.project.defs.getEnumDef(name);
					var select = new J("<select/>");
					select.appendTo(li);

					var opt = new J('<option/>');
					opt.appendTo(select);
					opt.attr("value","");
					opt.text("-- Use default ("+fi.def.getDefault()+") --");
					if( fi.isUsingDefault() )
						opt.attr("selected","selected");

					if( fi.def.canBeNull ) {
						var opt = new J('<option/>');
						opt.appendTo(select);
						opt.attr("value","");
						opt.text("null");
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
						N.debug(fi.getEnumValue());
						onFieldChange();
					});
					hideInputDefault(select, fi);

					// var def = fi.def.getStringDefault();
					// input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
					// if( !fi.isUsingDefault() )
					// 	input.val( fi.getString() );
					// input.change( function(ev) {
					// 	fi.parseValue( input.val() );
					// 	onFieldChange();
					// });

				case F_Bool:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","checkbox");
					input.prop("checked",fi.getBool());
					input.change( function(ev) {
						fi.parseValue( Std.string( input.prop("checked") ) );
						onFieldChange();
					});
			}
		}
	}
}