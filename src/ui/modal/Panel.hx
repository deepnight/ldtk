package ui.modal;

class Panel extends ui.Modal {
	var jPanelMask: js.jquery.JQuery;
	var jLinkedButton : Null<js.jquery.JQuery>;

	public function new() {
		super();

		var mainPanel = new J("#mainPanel");

		jModalAndMask.addClass("panel");
		jModalAndMask.offset({ top:0, left:mainPanel.outerWidth() });

		jPanelMask = new J("<div/>");
		jPanelMask.addClass("panelMask");
		jPanelMask.prependTo("body");
		jPanelMask.offset({ top:mainPanel.find("#layers").offset().top, left:0 });
		jPanelMask.width(mainPanel.outerWidth());
		jPanelMask.height( mainPanel.outerHeight() - jPanelMask.offset().top );
		jPanelMask.click( function(_) close() );

		ui.Modal.closeAll(this);
	}

	function linkToButton(selector:String) {
		jLinkedButton = new J(selector);
		jLinkedButton.addClass("active");
		return jLinkedButton.length>0;
	}

	override function onDispose() {
		super.onDispose();

		if( jLinkedButton!=null )
			jLinkedButton.removeClass("active");
		jLinkedButton = null;

		jPanelMask.remove();
		jPanelMask = null;
	}

	override function doCloseAnimation() {
		jMask.fadeOut(50);
		jContent.stop(true,false).animate({ width:"toggle" }, 100, function(_) {
			destroy();
		});
	}

	override function onClose() {
		super.onClose();

		if( jLinkedButton!=null )
			jLinkedButton.removeClass("active");

		jPanelMask.remove();
	}
}
