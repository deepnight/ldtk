package ui.modal;

class Dialog extends ui.Modal {
	var jButtons: js.jquery.JQuery;

	public function new(?target:js.jquery.JQuery, ?className:String) {
		super();

		jModalAndMask.addClass("dialog");
		if( className!=null )
			jModalAndMask.addClass(className);

		// Buttons
		jButtons = new J('<div class="buttons"/>');
		jButtons.appendTo(jWrapper);
		jButtons.hide();

		// Arrival anim
		jWrapper.hide().slideDown(60);


		// Position near attach target
		positionNear(target);
	}

	public function positionNear(?target:js.jquery.JQuery, toLeft=false) {
		if( target==null )
			jModalAndMask.addClass("centered");
		else {
			jModalAndMask.removeClass("centered");
			var targetOff = target.offset();
			var x = toLeft ? targetOff.left+target.outerWidth()-jContent.width() : targetOff.left;
			var hei = App.ME.jDoc.innerHeight();
			if( targetOff.top>=hei*0.7 ) {
				// Place above target
				jWrapper.offset({
					left: x,
					top: 0,
				});
				jWrapper.css("top", "auto");
				jWrapper.css("bottom", (hei-targetOff.top)+"px");
			}
			else {
				// Place beneath target
				jWrapper.offset({
					left: x,
					top: targetOff.top+target.outerHeight()
				});
			}
		}
	}

	public static function closeAll() {
		for(m in Modal.ALL)
			if( !m.isClosing() && Std.is(m, Dialog) )
				m.close();
	}

	public function removeButtons() {
		jButtons.empty().hide();
	}


	public function addTitle(label:dn.data.GetText.LocaleString) {
		jContent.append('<h2>$label</h2>');
	}

	public function addParagraph(str:dn.data.GetText.LocaleString) {
		jContent.append('<p>$str</p>');
	}


	public function addButton(label:String, ?className:String, cb:Void->Void) : js.jquery.JQuery {
		var b = new J("<button/>");
		jButtons.show().append(b);
		b.attr("type","button");
		b.text(label);
		if( className!=null )
			b.addClass(className);
		b.click( function(ev) {
			cb();
		});
		return b;
	}

	public function addConfirm(cb:Void->Void) {
		var b = addButton("Confirm", "confirm", function() {
			cb();
			close();
		});
		b.detach();
		jButtons.prepend(b);
	}

	public function addCancel(?cb:Void->Void) {
		var b = addButton("Cancel", "cancel", function() {
			if( cb!=null )
				cb();
			close();
		});
	}

	public function addClose(?cb:Void->Void) {
		var b = addButton("Close", "confirm", function() {
			if( cb!=null )
				cb();
			close();
		});
	}

	override function update() {
		super.update();


	}
}