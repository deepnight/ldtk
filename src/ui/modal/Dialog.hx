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

		// Position
		if( target!=null ) {
			var off = target.offset();
			jWrapper.offset({ left:off.left, top:off.top+target.outerHeight() });
		}

		// Arrival anim
		jWrapper.hide().slideDown(60);
	}

	public function removeButtons() {
		jButtons.empty().hide();
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
}