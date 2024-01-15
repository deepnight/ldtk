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

enum CtxElement {
	Ctx_Action(settings:CtxActionSettings);
	Ctx_Group(elements:Array<CtxElement>);
	Ctx_CopyPaster(settings:CtxCopyPasterSettings);
	Ctx_Title(label:String);
	Ctx_Separator;
}

typedef CtxActionSettings = {
	var ?label : LocaleString;
	var ?subText : LocaleString;
	var cb : Void->Void;
	var ?iconId : String;
	var ?jHtmlImg : js.jquery.JQuery;
	var ?className : String;
	var ?enable : Void->Bool;
	var ?selectionTick : Bool;
	var ?tip : String;
}

typedef CtxCopyPasterSettings = {
	var elementName : String;
	var clipType : ClipboardType;
	var copy : Null< Void->Void >;
	var cut : Null< Void->Void >;
	var paste : Null< Void->Void >;
	var duplicate : Null< Void->Void >;
	var delete : Null< Void->Void >;
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

		// Emulated right click on macOS
		if( App.isMac() )
			jTarget.on("mousedown.context", (ev:js.jquery.Event)->{
				if( ev.button==0 && App.ME.isMacCtrlDown() ) {
					ev.stopPropagation();
					ev.preventDefault();
					_open(ev);
				}
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

		if( a.jHtmlImg!=null )
			jElement.append(a.jHtmlImg);
		else if( a.iconId!=null )
			jElement.append('<span class="icon ${a.iconId}"></span>');

		if( a.label!=null )
			jElement.append(a.label);

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



	public static function attachTo_new(jTarget:js.jquery.JQuery, showButton=true, ?jButtonContext:js.jquery.JQuery, builder:ContextMenu->Void) {
		// Open callback
		function _open(event:js.jquery.Event) {
			var ctx = new ContextMenu(event);
			builder(ctx);
		}

		// Cleanup
		jTarget
			.off(".context")
			.find("button.context").remove();

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

	public inline function addActionElement(settings:CtxActionSettings) {
		addElement( Ctx_Action(settings) );
	}


	public function addElement(e:CtxElement, ?jTarget:js.jquery.JQuery) {
		var jElement : js.jquery.JQuery = null;

		switch e {
			case Ctx_Action(settings):
				jElement = new J('<button class="transparent"/>');

				if( settings.jHtmlImg!=null )
					jElement.append(settings.jHtmlImg);
				else if( settings.iconId!=null )
					jElement.append('<span class="icon ${settings.iconId}"></span>');

				if( settings.label!=null )
					jElement.append(settings.label);

				if( settings.subText!=null && settings.subText!=settings.label )
					jElement.append('<span class="sub">${settings.subText}</span>');

				if( settings.enable!=null && !settings.enable() )
					jElement.prop("disabled", true);

				if( settings.className!=null )
					jElement.addClass(settings.className);

				if( settings.selectionTick!=null ) {
					if( settings.selectionTick ) {
						jElement.addClass("selected");
						jElement.prepend('<span class="icon selectionTick checkboxOn"></span>');
					}
					else
						jElement.prepend('<span class="icon selectionTick checkboxOff"></span>');
				}

				if( settings.tip!=null )
					Tip.attach(jElement, settings.tip);

				// Callback
				jElement.click( (_)->{
					closeAll();
					settings.cb();
				});

			case Ctx_Group(elements):
				jElement = new J('<div class="group"/>');
				for(e in elements)
					addElement(e, jElement);

			case Ctx_CopyPaster(settings):
				jElement = new J('<div class="group"/>');
				addElement( Ctx_Action({
					iconId : "copy",
					cb : settings.copy,
					enable: ()->settings.copy!=null,
					tip : L._Copy(settings.elementName)
				}), jElement );

				addElement( Ctx_Action({
					iconId : "cut",
					cb : settings.cut,
					enable: ()->settings.cut!=null,
					tip : L._Cut(settings.elementName)
				}), jElement );

				addElement( Ctx_Action({
					iconId : "paste",
					cb : settings.paste,
					enable: ()->settings.paste!=null && App.ME.clipboard.is(settings.clipType),
					tip : L._PasteAfter(settings.elementName),
				}), jElement );

				addElement( Ctx_Action({
					label : L.untranslated("x2"),
					className : "duplicate",
					cb : settings.duplicate,
					enable: ()->settings.duplicate!=null,
					tip : L._Duplicate(settings.elementName)
				}), jElement );

				addElement( Ctx_Action({
					iconId : "delete",
					cb : settings.delete,
					enable: ()->settings.delete!=null,
					tip : L._Delete(settings.elementName)
				}), jElement );

			case Ctx_Title(label):
				jElement = new J('<div class="title"/>');
				jElement.append(label);

			case Ctx_Separator:
				jElement = new J('<div class="separator"/>');
		}

		if( jTarget!=null )
			jTarget.append(jElement);
		else
			jContent.append(jElement);
		applyAnchor();
	}
}