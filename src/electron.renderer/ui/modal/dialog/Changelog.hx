package ui.modal.dialog;

class Changelog extends ui.modal.Dialog {
	var isNewUpdate : Bool;

	public function new(isNewUpdate=false) {
		super("changelog");

		this.isNewUpdate = isNewUpdate;
		canBeClosedManually = !isNewUpdate;
		showVersion();
	}


	public function showVersion(?version:dn.Version) {
		var changeLog = Const.getChangeLog().latest;

		// Pick specific version
		if( version!=null ) {
			for( c in Const.getChangeLog().entries )
				if( c.version.isEqual(version,true) ) {
					changeLog = c;
					break;
				}
		}

		// Prepare markdown
		var rawMd = changeLog.allNoteLines.join("\n");
		var imgReg = ~/!\[]\((.*?)\)/gim;
		rawMd = imgReg.replace(rawMd, "![](file:///"+JsTools.getChangelogImgDir()+"/$1)");

		loadTemplate("changelog", {
			ver: changeLog.version.numbers,
			app: Const.APP_NAME,
			title: changeLog.title==null ? "" : '&ldquo;&nbsp;'+changeLog.title+'&nbsp;&rdquo;',
			md: rawMd,
		}, false);


		jContent.find(".close")
			.click( (_)->close() );

		var jOthers = jContent.find(".others");
		jOthers.click( ev->{
			var ctx = new ui.modal.ContextMenu(ev);
				for( c in Const.getChangeLog().entries )
				ctx.add({
					label: L.t.untranslated( c.version.numbers + ( c.title!=null ? " - "+c.title : "" ) ),
					cb: ()->{
						showVersion(c.version);
					}
				});
		} );

		if( isNewUpdate )
			jOthers.hide();
		else
			jContent.find(".newUpdate").hide();
	}

}