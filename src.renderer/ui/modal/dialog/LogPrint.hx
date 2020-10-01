package ui.modal.dialog;

class LogPrint extends ui.modal.Dialog {
	public function new(log:dn.Log) {
		super();
		loadTemplate("logPrint");

		var jList = jContent.find(".log");
		jList.appendTo(jContent);
		for(l in log.entries) {
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

		addClose();
	}
}