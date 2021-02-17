package ui.modal;

class Panel extends ui.Modal {
	var jPanelMask: js.jquery.JQuery; // mask over main panel
	var jLinkedButton : Null<js.jquery.JQuery>;
	var jCloseButton : js.jquery.JQuery;
	var closeBtInvalidated = true;

	public function new() {
		super();
		ui.Modal.closeAll(this);

		editor.selectionTool.clear();

		var mainPanel = new J("#mainPanel");

		jModalAndMask.addClass("panel");
		jModalAndMask.removeClass("centered");

		jCloseButton = new J('<button class="close gray"> <div class="icon close"/> </button>');
		jModalAndMask.append(jCloseButton);
		jCloseButton.click( ev->if( !isClosing() ) close() );
		enableCloseButton();

		jPanelMask = new J("<div/>");
		jPanelMask.addClass("panelMask");
		jPanelMask.prependTo( App.ME.jPage );
		jPanelMask.offset({ top:mainPanel.find("#layers").offset().top, left:0 });
		jPanelMask.width(mainPanel.outerWidth());
		jPanelMask.height( mainPanel.outerHeight() - jPanelMask.offset().top );
		jPanelMask.click( function(_) close() );

		dn.Process.resizeAll();
	}

	override function onResize() {
		super.onResize();
		var jBar = editor.jMainPanel.find("#mainBar");
		var y = jBar.offset().top + jBar.outerHeight();
		jWrapper.css({
			top: y+"px",
			height: 'calc( 100vh - ${y}px )',
		});

		closeBtInvalidated = true;
	}

	var _lastWrapperWid : Float = 0;
	function updateCloseButton() {
		closeBtInvalidated = false;
		if( isClosing() ) {
			if( jCloseButton.is(":visible") )
				jCloseButton.hide();
			return;
		}

		var w = jWrapper.outerWidth();
		if( w!=_lastWrapperWid ) {
			_lastWrapperWid = w;
			jCloseButton.css({ left:(w-3)+"px" });
		}
	}

	function hideCloseButton() {
		jCloseButton.hide();
	}

	function enableCloseButton() {
		jCloseButton.show();
		closeBtInvalidated = true;
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

	override function postUpdate() {
		super.postUpdate();
		if( closeBtInvalidated )
			updateCloseButton();
	}
}
