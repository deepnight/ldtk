package ui.modal;

class Panel extends ui.Modal {
	var jPanelMask: js.jquery.JQuery; // mask over main panel
	var jLinkedButton : Null<js.jquery.JQuery>;
	var jCloseButton : js.jquery.JQuery;

	public function new() {
		super();

		LOG.userAction("Opened panel "+this);
		ui.Modal.closeAll(this);

		editor.selectionTool.clear();

		var mainPanel = new J("#mainPanel");

		jModalAndMask.addClass("panel");
		anchor = MA_Free;

		jCloseButton = new J('<button class="close gray"> <div class="icon close"/> </button>');
		jCloseButton.click( ev->if( !isClosing() ) close() );

		jPanelMask = new J("<div/>");
		jPanelMask.addClass("panelMask");
		jPanelMask.prependTo( App.ME.jPage );
		jPanelMask.offset({ top:mainPanel.find("#layers").offset().top, left:0 });
		jPanelMask.width(mainPanel.outerWidth());
		jPanelMask.height( mainPanel.outerHeight() - jPanelMask.offset().top );
		jPanelMask.click( function(_) close() );

		dn.Process.resizeAll();
	}

	override function loadTemplate(tplName:String, ?className:String, ?vars:Dynamic, useCache = true) {
		super.loadTemplate(tplName, className, vars, useCache);
		insertCloseButton();
	}

	/**
		Show or hide the top Help banner in the panel.
	**/
	function checkHelpBanner( ?needsHelp:Void->Bool ) {
		if( project.isSample() || needsHelp!=null && needsHelp() )
			jContent.removeClass("noHelp");
		else
			jContent.addClass("noHelp");

	}

	function checkBackup() {
		if( !project.isBackup() )
			return;

		jContent.find("*:not(.close)")
			.off()
			.mouseover( (ev)->ev.preventDefault() );
		jContent.find("input, select, textarea, button").prop("disabled",true);

		jWrapper.find(".backupNotice").remove();
		jWrapper.append('<div class="backupNotice"><span>This panel is disabled for backup files.</span></div>');
		jWrapper.addClass("backupLock");
	}

	override function onResize() {
		super.onResize();
		var jBar = editor.jMainPanel.find("#mainBar");
		var y = settings.v.zenMode ? 0 : jBar.offset().top + jBar.outerHeight() - 6;
		jWrapper.css({
			top: y+"px",
			left: "0px",
			height: 'calc( 100vh - ${y}px )',
		});
	}

	function insertCloseButton() {
		var jTitle = jModalAndMask.find("h2").first();
		jCloseButton.show().appendTo(jTitle);
	}

	function linkToButton(selector:String) {
		jLinkedButton = new J(selector);
		jLinkedButton.addClass("active");
		jLinkedButton.closest(".buttons").addClass("faded");
		return jLinkedButton.length>0;
	}

	override function onDispose() {
		super.onDispose();

		if( jLinkedButton!=null ) {
			if( !ui.Modal.isOpen(Panel) )
				jLinkedButton.closest(".buttons").removeClass("faded");
			jLinkedButton.removeClass("active");
		}
		jLinkedButton = null;

		jPanelMask.empty().remove();
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

		if( jCloseButton.is(":visible") )
			jCloseButton.hide();

		jPanelMask.remove();

		LOG.userAction("Closed panel "+this);
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
