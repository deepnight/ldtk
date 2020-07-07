package ui;

class InstanceEditor extends dn.Process {
	public static var ALL : Array<InstanceEditor> = [];

	var jPanel : js.jquery.JQuery;
	var ei : led.inst.EntityInstance;

	public function new(ei:led.inst.EntityInstance) {
		super(Client.ME);

		ALL.push(this);
		this.ei = ei;
		Client.ME.ge.listenAll(onGlobalEvent);

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
		Client.ME.ge.stopListening(onGlobalEvent);
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

				case F_Color:
					var input = new J("<input/>");
					input.appendTo(li);
					input.attr("type","color");
					input.val( fi.getColorAsHexStr() );
					input.change( function(ev) {
						fi.parseValue( input.val() );
						onFieldChange();
					});

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