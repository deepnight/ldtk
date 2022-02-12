package ui.modal.dialog;

class ColorPicker extends ui.modal.Dialog {
	var picker : simpleColorPicker.ColorPicker;
	var jTargetInput : js.jquery.JQuery;
	var originalColor : Int;
	var usedColorsTag : Null<String>;

	public function new(?usedColorsTag:String, ?target:js.jquery.JQuery, ?color:UInt) {
		super();

		this.usedColorsTag = usedColorsTag;
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
			N.copied();
			updatePaste();
		});


		// Recently used colors
		var jExpand = jContent.find(".recentColors .expand");
		var jRecents = jContent.find(".recentColors .recents");
		if( usedColorsTag==null ) {
			jExpand.hide();
			jRecents.hide();
		}
		else {
			var showAll = false;
			function _updateRecents() {
				jRecents.empty();
				jExpand.removeClass("on");
				jExpand.removeClass("off");
				if( showAll )
					jExpand.addClass("showAll");
				else
					jExpand.removeClass("showAll");

				if( settings.getUiStateBool(ShowProjectColors) && usedColorsTag!=null ) {
					// Update recent colors list
					var usedColors = project.getUsedColorsAsArray(showAll ? null : usedColorsTag);
					for( c in usedColors ) {
						var jC = new J('<div class="color"/>');
						jC.css("background-color", C.intToHex(c));
						jC.appendTo(jRecents);
						jC.click((_)->{
							picker.setColor(c);
							jInput.val( C.intToHex(c,false) );
						});
					}
					if( usedColors.length==0 ) {
						jRecents.addClass("empty");
						jRecents.append("Empty");
					}
					else {
						// Show all button
						if( !showAll ) {
							var jShowAll = new J('<a class="showAll">Show all colors used in this project</a>');
							jShowAll.click(_->{
								showAll = true;
								_updateRecents();
							});
							jShowAll.appendTo(jRecents);
						}
						jRecents.removeClass("empty");
					}

					jExpand.addClass("on");
				}
				else
					jExpand.addClass("off");
			}
			jExpand.click( _->{
				settings.toggleUiStateBool(ShowProjectColors);
				settings.save();
				if( settings.getUiStateBool(ShowProjectColors) )
					jExpand.next().slideDown(100).css('display','grid');
				else
					jExpand.next().slideUp(60);
				_updateRecents();
			});
			_updateRecents();
		}


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

		JsTools.parseComponents(jContent);
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

		project.unregisterColor( usedColorsTag, originalColor );
		project.registerUsedColor( usedColorsTag, getColor() );
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