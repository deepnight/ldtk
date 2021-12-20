package ui.modal.dialog;

class ColorPicker extends ui.modal.Dialog {
	var picker : simpleColorPicker.ColorPicker;
	var jTargetInput : js.jquery.JQuery;
	var originalColor : Int;

	public function new(?target:js.jquery.JQuery, ?color:UInt) {
		super();

		loadTemplate("colorPicker");

		if( target!=null ) {
			positionNear(target);
			if( target.is("input") )
				jTargetInput = target;
		}

		var jPreview = jContent.find(".preview");

		// Manual text input
		var jInput = jContent.find(".input input");
		jInput
			.on("change keyup", (ev:js.jquery.Event)->{
				if( jInput.val().indexOf("#")>=0 )
					jInput.val( StringTools.replace(jInput.val(), "#", "") );

				if( C.isValidHex( jInput.val() ) )
					picker.setColor( C.sanitizeHexStr( jInput.val() ) );
			})
			.on( "blur", ev->jInput.val( picker.getHexString().substr(1) ) );

		// Paste from clipboard
		jContent.find(".paste").click( (ev:js.jquery.Event)->{
			var cb = electron.Clipboard.readText();
			if( C.isValidHex(cb) ) {
				picker.setColor( C.sanitizeHexStr( cb ) );
				N.quick("Pasted color");
			}
		});
		updatePaste();

		// Copy to clipboard
		jContent.find(".copy").click( (ev:js.jquery.Event)->{
			electron.Clipboard.writeText( picker.getHexString() );
			ev.getThis().addClass("done");
			N.quick("Copied to clipboard");
			updatePaste();
		});


		//
		var jExpand = jContent.find(".expand");
		var jRecents = jContent.find(".recents");
		function _updateRecents() {
			jRecents.empty();
			jExpand.removeClass("on");
			jExpand.removeClass("off");

			if( settings.v.showProjectColors ) {
				// Update recent colors list
				for(c in project.getUsedColorsAsArray()) {
					var jC = new J('<div class="color"/>');
					jC.css("background-color", C.intToHex(c));
					jC.appendTo(jRecents);
					jC.click((_)->{
						picker.setColor(c);
						jInput.val( C.intToHex(c,false) );
					});
				}
				jExpand.addClass("on");
			}
			else
				jExpand.addClass("off");
		}
		jExpand.click( _->{
			settings.v.showProjectColors = !settings.v.showProjectColors;
			settings.save();
			if( settings.v.showProjectColors )
				jExpand.next().slideDown(100);
			else
				jExpand.next().slideUp(60);
			_updateRecents();
		});
		_updateRecents();


		// Color picker
		picker = new simpleColorPicker.ColorPicker({});
		picker.setSize(320, 150);
		picker.appendTo( jContent.find(".picker").get(0) );
		picker.onChange( c->{
			if( picker.isChoosing )
				jInput.val( c.substr(1) );
			jContent.find(".copy").removeClass("done");
			jPreview.css({ backgroundColor:picker.getHexString() });
		});

		// Init color
		if( color!=null )
			picker.setColor(color);
		else if( jTargetInput!=null )
			picker.setColor( jTargetInput.val() );
		originalColor = getColor();

		// Init elements
		jInput
			.val( picker.getHexString().substr(1) )
			.focus()
			.select();
		jPreview.css({ backgroundColor:picker.getHexString() });
	}

	function updatePaste() {
		var jPaste = jContent.find(".paste");
		if( C.isValidHex( electron.Clipboard.readText() ) ) {
			jPaste.addClass("enabled");
			jPaste.css({ backgroundColor: C.sanitizeHexStr(electron.Clipboard.readText()) });
		}
		else
			jPaste.removeClass("enabled");
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		switch keyCode {
			case K.ESCAPE:
				validate();
				close();

			case K.ENTER:
				validate();
				close();
		}
	}

	function validate() {
		if( jTargetInput!=null )
			jTargetInput.val( picker.getHexString() ).change();

		project.unregisterColor( originalColor );
		project.registerUsedColor( getColor() );
		onValidate( getColor() );
	}

	public dynamic function onValidate(c:UInt) {}
	public dynamic function onCancel() {}

	override function onClickMask() {
		validate();
		super.onClickMask();
	}

	override function onDispose() {
		super.onDispose();
		picker.remove();
		picker = null;
	}

	public function getColor() {
		return picker.getHexNumber();
	}
}