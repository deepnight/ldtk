package ui.modal.dialog;

class LogPrint extends ui.modal.Dialog {
	var log : dn.Log;

	public function new(log:dn.Log, ?title:LocaleString) {
		super();
		this.log = log;
		loadTemplate("logPrint");

		if( title!=null )
			jContent.find("h2.title").text( title );

		// Show all
		var full = false;
		var jShowAll = jContent.find(".showAll");
		jShowAll.click( (_)->{
			full = !full;
			renderLog(full);
		 } );

		renderLog(full);
		addClose();
	}

	function renderLog(full:Bool) {
		var jList = jContent.find(".log");
		jList.empty();

		// Update show all button
		var labels = jContent.find(".showAll span");
		labels.hide().filter(full?".full":".short").show();

		// Header
		var n = log.countCriticalEntries();
		var header = jContent.find(".logHeader .content");
		header.empty();
		if( n>0 ) {
			header.append('$n error(s)');
			jContent.find(".logHeader").addClass("error");
		}
		else
			header.append('No error');
		header.append(', ${log.entries.length} entries');

		// Log list
		for(l in log.entries) {
			if( !full && !l.critical )
				continue;

			var li = new J('<li></li>');
			if( l.critical )
				li.addClass("critical");
			else
				li.css({
					borderColor: C.intToHex(l.color),
					backgroundColor: C.intToHex(l.color)+(l.critical?"60":"20"), // add some alpha
				});
			li.append(l.str);
			li.appendTo(jList);
		}

	}
}