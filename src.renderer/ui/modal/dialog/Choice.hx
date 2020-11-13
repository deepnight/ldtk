package ui.modal.dialog;

class Choice extends ui.modal.Dialog {
	public function new(?target:js.jquery.JQuery, str:LocaleString, hasCancel:Bool, choices:Array<{ label:String, cb:Void->Void }>) {
		super(target);

		jModalAndMask.addClass("choice");
		canBeClosedManually = hasCancel;

		str = '<p>'+str.split("\n").join("</p><p>")+'</p>';
		jContent.html(str);

		for(c in choices)
			addButton(c.label, c.cb);

		if( hasCancel )
			addCancel();
	}
}