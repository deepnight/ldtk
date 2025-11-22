package ui.modal.dialog;

import dn.data.LocaleString;

class Retry extends ui.modal.Dialog {
	public function new(str:LocaleString, cb:Void->Void) {
		super("retry");

		jContent.append('<h2>Error</h2>');
		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jContent.append(p);

		addButton(L.t._("Retry"), ()->{
			close();
			cb();
		} );
		addButton(L.t._("Ignore"), close);
	}
}