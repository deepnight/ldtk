package ui.modal;

import dn.data.GetText.LocaleString;

typedef ContextAction = {
	var label : LocaleString;
	var cb : Void->Void;
}

class ContextMenu extends ui.Modal {
	var jAttachTarget : Null<js.jquery.JQuery>;
	public function new(?openEvent:js.jquery.Event) {
		super();

		jAttachTarget = new J(openEvent.currentTarget);
		if( jAttachTarget.length>0 )
			positionNear(jAttachTarget);

		if( jAttachTarget.is("button.context") )
			jAttachTarget.addClass("open");

		setTransparentMask();
		addClass("contextMenu");
	}

	override function onClose() {
		super.onClose();
		if( jAttachTarget.is("button.context") )
			jAttachTarget.removeClass("open");
	}

	public static function addTo(jTarget:js.jquery.JQuery, actions:Array<ContextAction>) {
		// Cleanup
		jTarget
			.off(".context")
			.find("button.context").remove();

		// Init arrow button
		var jButton = new J('<button class="transparent context"></button>');
		jButton.appendTo(jTarget);
		jButton.append('<div class="icon contextMenu"/>');

		// Open
		function _open(event:js.jquery.Event) {
			var ctx = new ContextMenu(event);
			for(a in actions)
				ctx.add( a.label, a.cb );
		}

		// Arrow button
		jButton.click( (ev)->_open(ev) );

		// Right click
		jTarget.on("contextmenu.context", (ev:js.jquery.Event)->{
			ev.stopPropagation();
			ev.preventDefault();
			_open(ev);
		});
	}


	public function add(label:dn.data.GetText.LocaleString, cb:Void->Void) {
		var jButton = new J('<button class="transparent"/>');
		jButton.appendTo(jContent);
		jButton.text(label);
		jButton.click( (_)->{
			close();
			cb();
		 });
		 return jButton;
	}
}