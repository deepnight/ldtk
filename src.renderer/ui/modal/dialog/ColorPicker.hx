package ui.modal.dialog;

class ColorPicker extends ui.modal.Dialog {
	var picker : simpleColorPicker.ColorPicker;
	var jTargetInput : js.jquery.JQuery;

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

				if( ev.key=="Enter" )
					jInput.blur();
			})
			.on( "blur", ev->jInput.val( picker.getHexString().substr(1) ) )
			.focus();

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


		// Color picker
		picker = new simpleColorPicker.ColorPicker({});
		picker.setColor(color);
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

		// Init elements
		jInput.val( picker.getHexString().substr(1) );
		jPreview.css({ backgroundColor:picker.getHexString() });
		picker.setSize(jContent.innerWidth(), 150);
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
			case K.ENTER if( jContent.find("input:focus").length==0 ):
				close();
		}
	}

	function validate() {
		if( jTargetInput!=null )
			jTargetInput.val( picker.getHexString() );
	}

	override function onClickMask() {
		super.onClickMask();
		validate();
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