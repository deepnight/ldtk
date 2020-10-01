package ui.modal.dialog;

class LogPrint extends ui.modal.Dialog {
	var log : dn.Log;

	public function new(log:dn.Log) {
		super();
		this.log = log;
		loadTemplate("logPrint");

		// Show all
		var jShowAll= jContent.find(".showAll");
		jShowAll.click( function(_) {
			renderLog(true);
			jShowAll.remove();
		});

		renderLog( !log.containsAnyCriticalEntry() ? true : false );

		addClose();
	}

	function renderLog(full:Bool) {
		var jList = jContent.find(".log");
		jList.empty();
		for(l in log.entries) {
			if( !full && !l.critical )
				continue;

			var li = new J('<li></li>');
			if( l.critical )
				li.addClass("critical");

			li.css({
				borderColor: C.intToHex(l.color),
				backgroundColor: C.intToHex(l.color)+(l.critical?"60":"20"), // add some alpha
			});
			li.append(l.str);
			li.appendTo(jList);
		}

	}
}