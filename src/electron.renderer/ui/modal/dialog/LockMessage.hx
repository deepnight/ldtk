package ui.modal.dialog;

class LockMessage extends ui.modal.Dialog {
	static var ME : LockMessage;

	public function new(str:dn.data.GetText.LocaleString, action:Void->Void) {
		super("lockMessage");

		ME = this;

		canBeClosedManually = false;

		var jMsg = new J('<div class="task"/>');
		jMsg.appendTo(jContent);
		var p = '<p>' + StringTools.replace(str,"\n","</p><p>") + '</p>';
		jMsg.append(p);

		jContent.append('<div class="sub">'+L.t._("Please wait...")+'</div>');

		delayer.addS(action, 0.2);
		cd.setS("wait",0.5);
	}

	public static function hasAny() {
		return ME!=null && !ME.destroyed;
	}

	override function onDispose() {
		super.onDispose();
		if( ME==this )
			ME = null;
	}

	override function update() {
		super.update();

		if( !cd.has("wait") && !Progress.hasAny() )
			close();
	}
}