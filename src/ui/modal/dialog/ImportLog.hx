package ui.modal.dialog;

class ImportLog extends ui.modal.Dialog {
	public function new(log:Array<String>) {
		super("log");

		jContent.append('<h2>Import successful!</h2>');

		var jList = new J('<ul class="log"/>');
		jList.appendTo(jContent);
		for(str in log) {
			var li = new J('<li>$str</li>');
			if( str.toLowerCase().indexOf("added")>=0 )
				li.addClass("good");
			else if( str.toLowerCase().indexOf("removed")>=0 )
				li.addClass("bad");
			li.appendTo(jList);
		}

		addClose();
	}
}