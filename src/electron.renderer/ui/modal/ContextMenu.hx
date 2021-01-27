package ui.modal;

import dn.data.GetText.LocaleString;

typedef ContextAction = {
	var label : LocaleString;
	var ?sub : Null<LocaleString>;
	var ?className : String;
	var cb : Void->Void;
	var ?cond : Void->Bool;
}

class ContextMenu extends ui.Modal {
	public static var ME : ContextMenu;
	var jAttachTarget : js.jquery.JQuery; // could be empty

	public function new(?m:Coords, ?openEvent:js.jquery.Event) {
		super();

		if( ME!=null && !ME.destroyed )
			ME.destroy();
		ME = this;

		if( openEvent!=null ) {
			var jEventTarget = new J(openEvent.currentTarget);
			jAttachTarget = jEventTarget;
			if( jAttachTarget.is("button.context") )
				jAttachTarget = jAttachTarget.parent();
			jAttachTarget.addClass("contextMenuOpen");

			if( jEventTarget.is("button.context") )
				positionNear(jEventTarget);
			else if( openEvent!=null )
				positionNear( new Coords(openEvent.pageX, openEvent.pageY) );

		}
		else {
			jAttachTarget = new J("");
			if( m!=null )
				positionNear(m);
		}

		setTransparentMask();
		addClass("contextMenu");
	}

	public static inline function isOpen() return ME!=null && !ME.destroyed;

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	override function onClose() {
		super.onClose();
		jAttachTarget.removeClass("contextMenuOpen");
		if( ME==this )
			ME = null;
	}

	public static function addTo(jTarget:js.jquery.JQuery, ?jButtonContext:js.jquery.JQuery, actions:Array<ContextAction>) {
		// Cleanup
		jTarget
			.off(".context")
			.find("button.context").remove();

		// Init arrow button
		var jButton = new J('<button class="transparent context"></button>');
		jButton.appendTo(jButtonContext==null ? jTarget : jButtonContext);
		jButton.append('<div class="icon contextMenu"/>');

		// Open
		function _open(event:js.jquery.Event) {
			var ctx = new ContextMenu(event);
			for(a in actions)
				if( a.cond==null || a.cond() )
					ctx.add(a);
		}

		// Arrow button
		jButton.click( (ev:js.jquery.Event)->{
			ev.stopPropagation();
			_open(ev);
		});

		// Right click
		jTarget.on("contextmenu.context", (ev:js.jquery.Event)->{
			ev.stopPropagation();
			ev.preventDefault();
			_open(ev);
		});
	}


	public function add(a:ContextAction) {
		var jButton = new J('<button class="transparent"/>');
		jButton.appendTo(jContent);
		jButton.text(a.label);
		if( a.sub!=null && a.sub!=a.label )
			jButton.append('<span class="sub">${a.sub}</span>');

		if( a.className!=null )
			jButton.addClass(a.className);

		jButton.click( (_)->{
			close();
			a.cb();
		 });
		 return jButton;
	}
}