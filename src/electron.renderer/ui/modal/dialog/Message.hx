package ui.modal.dialog;

class Message extends ui.modal.Dialog {
	public function new(str:dn.data.GetText.LocaleString, ?iconId:String) {
		super("message");

		if( iconId!=null ) {
			jContent.append('<div class="iconWrapper"> <div class="icon $iconId"/> </div>');
			jModalAndMask.addClass("hasIcon");
		}

		var jMsg = new J('<div class="message"/>');
		jMsg.appendTo(jContent);

		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jMsg.append(p);

		addClose();
	}

	public static function error(msg:LocaleString) {
		var m = new Message(msg);
		m.addClass("error");
		return m;
	}
}