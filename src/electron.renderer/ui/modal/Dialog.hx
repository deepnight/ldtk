package ui.modal;

class Dialog extends ui.Modal {
	var jButtons: js.jquery.JQuery;

	public function new(?jTarget:js.jquery.JQuery, ?className:String) {
		super();

		jModalAndMask.addClass("dialog");
		if( className!=null )
			jModalAndMask.addClass(className);

		// Buttons
		jButtons = new J('<div class="buttons"/>');
		jButtons.appendTo(jWrapper);
		jButtons.hide();

		// Arrival anim
		openAnim();

		// Position near attach target
		if( jTarget!=null )
			setAnchor( MA_JQuery(jTarget) );
		else
			setAnchor( MA_Centered );
	}

	function openAnim() {
		jWrapper.hide().slideDown(60, applyAnchor);
	}

	public static function closeAll() {
		for(m in Modal.ALL)
			if( !m.isClosing() && Std.isOfType(m, Dialog) )
				m.close();
	}

	public function removeButtons() {
		jButtons.empty().hide();
	}


	public function addTitle(label:dn.data.GetText.LocaleString, atTheBeginning:Bool) {
		var t = new J('<h2>$label</h2>');
		if( atTheBeginning )
			jContent.prepend(t);
		else
			jContent.append(t);
	}

	public function addParagraph(str:dn.data.GetText.LocaleString, ?className:String) {
		var jElem = new J('<p>$str</p>');
		if( className!=null )
			jElem.addClass(className);
		jContent.append(jElem);
	}

	public function addDiv(str:dn.data.GetText.LocaleString, ?className:String) {
		var jElem = new J('<div>$str</div>');
		if( className!=null )
			jElem.addClass(className);
		jContent.append(jElem);
	}


	public function addButton(label:LocaleString, ?className:String, cb:Void->Void) : js.jquery.JQuery {
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

	public function addIconButton(iconId:String, ?className:String, cb:Void->Void) : js.jquery.JQuery {
		var b = new J("<button/>");
		jButtons.show().append(b);
		b.attr("type","button");
		b.append('<span class="icon $iconId"></span>');
		if( className!=null )
			b.addClass(className);
		b.click( function(ev) {
			cb();
		});
		return b;
	}

	public function addConfirm(cb:Void->Void) {
		var b = addButton(L.t._("Confirm"), "confirm", function() {
			cb();
			close();
		});
		b.detach();
		jButtons.prepend(b);
	}

	public function addCancel(?cb:Void->Void) {
		var b = addButton(L.t._("Cancel"), "cancel", function() {
			if( cb!=null )
				cb();
			close();
		});
	}

	public function addClose(?cb:Void->Void) {
		var b = addButton(L.t._("Close"), "confirm", function() {
			if( cb!=null )
				cb();
			close();
		});
	}

	override function update() {
		super.update();


	}
}