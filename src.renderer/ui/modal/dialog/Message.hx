package ui.modal.dialog;

class Message extends ui.modal.Dialog {
	public function new(str:dn.data.GetText.LocaleString) {
		super("message");

		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jContent.append(p);

		addClose();
	}
}