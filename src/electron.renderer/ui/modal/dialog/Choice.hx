package ui.modal.dialog;

class Choice extends ui.modal.Dialog {
	public function new(str:LocaleString, choices:Array<{ label:String, cb:Void->Void, ?className:String }>) {
		super();

		jModalAndMask.addClass("choice");

		str = '<p>'+str.split("\n").join("</p><p>")+'</p>';
		jContent.html(str);

		for(c in choices)
			addButton(c.label, c.className, ()->{
				close();
				c.cb();
			});

		addCancel();
	}
}