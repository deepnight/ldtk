package ui.modal;

import dn.data.GetText.LocaleString;

typedef ContextActions = Array<ContextAction>;
typedef ContextAction = {
	var label : LocaleString;
	var ?icon : String; // TODO rename iconId
	var ?jHtmlImg : js.jquery.JQuery;
	var ?subText : Null<LocaleString>;
	var ?className : String;
	var ?cb : Void->Void;
	var ?show : Void->Bool;
	var ?enable : Void->Bool;
	var ?separatorBefore: Bool;
	var ?separatorAfter: Bool;
	var ?subMenu: Void->ContextActions;
	var ?selectionTick : Bool;
	var ?keepOpen : Bool;
}

enum ContextMenuElement {
	CM_Action(a:ContextAction);
	CM_Title(str:LocaleString);
}

class ContextMenu extends ui.Modal {
	public static var ALL : Array<ContextMenu> = [];
	var jAttachTarget : js.jquery.JQuery; // could be empty
	var elements : Array<ContextMenuElement> = [];

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
				ctx.add(a);
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


	function reAttach() {
		jContent.empty();
		var elems = elements.copy();
		elements = [];
		for(e in elems)
			switch e {
				case CM_Action(a): add(a);
				case CM_Title(str): addTitle(str);
			}
	}


	public function addTitle(str:LocaleString) {
		elements.push( CM_Title(str) );
		var jTitle = new J('<div class="title">$str</div>');
		jTitle.appendTo(jContent);
		applyAnchor();
	}

	function createButton(a:ContextAction) {
		var jButton = new J('<button class="transparent"/>');

		if( a.jHtmlImg!=null ) {
			jButton.prepend(a.label);
			jButton.prepend(a.jHtmlImg);
		}
		else if( a.icon!=null )
			jButton.prepend('<span class="icon ${a.icon}"></span> ${a.label}');
		else
			jButton.html(a.label);

		if( a.subText!=null && a.subText!=a.label )
			jButton.append('<span class="sub">${a.subText}</span>');

		if( a.enable!=null && !a.enable() )
			jButton.prop("disabled", true);

		if( a.className!=null )
			jButton.addClass(a.className);

		if( a.separatorBefore )
			jButton.addClass("separatorBefore");

		if( a.separatorAfter )
			jButton.addClass("separatorAfter");

		if( a.selectionTick!=null ) {
			if( a.selectionTick ) {
				jButton.addClass("selected");
				jButton.append('<span class="icon selectionTick active"></span>');
			}
			else
				jButton.append('<span class="icon selectionTick inactive"></span>');
		}

		// Button action
		jButton.click( (_)->{
			if( a.cb!=null )
				a.cb();

			if( a.subMenu==null ) {
				if( a.keepOpen==true )
					reAttach();
				else
					closeAll();
			}

			if( a.subMenu!=null ) {
				addClass("subMenuOpen");
				var c = new ContextMenu(jButton, true);
				c.onCloseCb = ()->removeClass("subMenuOpen");

				for(subAction in a.subMenu())
					c.add(subAction);
			}
		});

		return jButton;
	}


	public function add(a:ContextAction) {
		if( a.show!=null && !a.show() )
			return new js.jquery.JQuery();

		elements.push( CM_Action(a) );

		var jButton = createButton(a);
		jButton.appendTo(jContent);
		applyAnchor();
		return jButton;
	}
}