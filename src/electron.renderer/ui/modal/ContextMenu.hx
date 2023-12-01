package ui.modal;

import dn.data.GetText.LocaleString;

typedef ContextActions = Array<ContextAction>;
typedef ContextAction = {
	var ?label : LocaleString;
	var ?iconId : String;
	var ?jHtmlImg : js.jquery.JQuery;
	var ?subText : Null<LocaleString>;
	var ?className : String;
	var ?cb : Void->Void;
	var ?show : Void->Bool;
	var ?enable : Void->Bool;
	var ?separatorBefore : Bool;
	var ?separatorAfter : Bool;
	var ?subMenu : Void->ContextActions;
	var ?selectionTick : Bool;
}

class ContextMenu extends ui.Modal {
	public static var ALL : Array<ContextMenu> = [];
	var jAttachTarget : js.jquery.JQuery; // could be empty

	public function new(?m:Coords, ?jNear:js.jquery.JQuery, ?openEvent:js.jquery.Event, isSubMenu=false) {
		super();

		if( !isSubMenu )
			closeAll();
		ALL.push(this);

		setTransparentMask();
		addClass("contextMenu");

		if( openEvent!=null || jNear!=null ) {
			var jEventTarget = jNear!=null ? jNear : new J(openEvent.target);
			jAttachTarget = jEventTarget;
			if( jAttachTarget.is("button.context") )
				jAttachTarget = jAttachTarget.parent();
			jAttachTarget.addClass("contextMenuOpen");

			if( jEventTarget.is("button") || jEventTarget.parent().is("button") || jNear!=null )
				setAnchor( MA_JQuery(jEventTarget) );
			else if( openEvent!=null )
				setAnchor( MA_Coords(new Coords(openEvent.pageX, openEvent.pageY)) );
		}
		else {
			jAttachTarget = new J("");
			if( m!=null )
				setAnchor( MA_Coords(m) );
		}
	}

	public function disableTextWrapping() {
		jContent.addClass("noWrap");
	}

	public static function closeAll() {
		for(m in ALL)
			m.destroy();
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
	}

	override function onClose() {
		super.onClose();
		jAttachTarget.removeClass("contextMenuOpen");
	}

	public static function attachTo(jTarget:js.jquery.JQuery, showButton=true, ?jButtonContext:js.jquery.JQuery, actions:ContextActions) {
		// Cleanup
		jTarget
			.off(".context")
			.find("button.context").remove();

		// Open callback
		function _open(event:js.jquery.Event) {
			var ctx = new ContextMenu(event);
			for(a in actions)
				ctx.addAction(a);
		}

		// Menu button
		if( showButton ) {
			var jButton = new J('<button class="transparent context"/>');
			jButton.appendTo(jButtonContext==null ? jTarget : jButtonContext);
			jButton.append('<div class="icon contextMenu"/>');
			jButton.click( (ev:js.jquery.Event)->{
				ev.stopPropagation();
				_open(ev);
			});
		}

		// Right click
		jTarget.on("contextmenu.context", (ev:js.jquery.Event)->{
			ev.stopPropagation();
			ev.preventDefault();
			_open(ev);
		});
	}


	override function applyAnchor() {
		super.applyAnchor();

		var pad = 16;
		var docHei = App.ME.jDoc.innerHeight();

		if( jWrapper.offset().top < pad )
			jWrapper.css("top", pad+"px");

		if( jWrapper.offset().top + jWrapper.outerHeight() >= docHei-pad )
			jWrapper.css("bottom", pad+"px");
	}


	public function addTitle(str:LocaleString) {
		var jTitle = new J('<div class="title">$str</div>');
		jTitle.appendTo(jContent);
		applyAnchor();
	}


	public function addAction(a:ContextAction) {
		if( a.show!=null && !a.show() )
			return new js.jquery.JQuery();

		var isButton = a.cb!=null || a.subMenu!=null;

		var jElement = isButton
			? new J('<button class="transparent"/>')
			: new J('<div class="title"/>');
		jElement.appendTo(jContent);

		if( a.jHtmlImg!=null ) {
			jElement.prepend(a.label);
			jElement.prepend(a.jHtmlImg);
		}
		else if( a.iconId!=null )
			jElement.prepend('<span class="icon ${a.iconId}"></span> ${a.label}');
		else
			jElement.html(a.label);

		if( a.subText!=null && a.subText!=a.label )
			jElement.append('<span class="sub">${a.subText}</span>');

		if( a.enable!=null && !a.enable() )
			jElement.prop("disabled", true);

		if( a.className!=null )
			jElement.addClass(a.className);

		if( a.separatorBefore )
			jElement.addClass("separatorBefore");

		if( a.separatorAfter )
			jElement.addClass("separatorAfter");

		if( a.selectionTick!=null ) {
			if( a.selectionTick ) {
				jElement.addClass("selected");
				jElement.prepend('<span class="icon selectionTick checkboxOn"></span>');
			}
			else
				jElement.prepend('<span class="icon selectionTick checkboxOff"></span>');
		}

		// Button action
		if( isButton )
			jElement.click( (_)->{
				if( a.subMenu==null )
					closeAll();
				else {
					addClass("subMenuOpen");
					var c = new ContextMenu(jElement, true);
					c.onCloseCb = ()->removeClass("subMenuOpen");

					for(subAction in a.subMenu())
						c.addAction(subAction);
				}

				if( a.cb!=null )
					a.cb();
			});

		applyAnchor();
		return jElement;
	}
}