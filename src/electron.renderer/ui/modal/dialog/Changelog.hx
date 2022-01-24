package ui.modal.dialog;

class Changelog extends ui.modal.Dialog {
	var isNewUpdate : Bool;

	public function new(isNewUpdate:Bool) {
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

		loadTemplate("changeLog", {
			ver: changeLog.version.numbers,
			app: Const.APP_NAME,
			title: changeLog.title==null ? "" : '&ldquo;&nbsp;'+changeLog.title+'&nbsp;&rdquo;',
			md: changeLog.allNoteLines.join("\n"),
		}, false);
		if( isNewUpdate )
			addClass("newUpdate");

		w.jContent.find(".close")
			.click( (_)->w.close() );

		w.jContent.find(".others").click( ev->{
			var ctx = new ui.modal.ContextMenu(ev);
				for( c in Const.getChangeLog().entries )
				ctx.add({
					label: L.t.untranslated( c.version.numbers + ( c.title!=null ? " - "+c.title : "" ) ),
					cb: ()->{
						w.close();
						showUpdate(c.version);
					}
				});
		} );
	}

}