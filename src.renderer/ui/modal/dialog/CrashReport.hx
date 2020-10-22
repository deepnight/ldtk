package ui.modal.dialog;

class CrashReport extends ui.modal.Dialog {
	public function new(msg:String, error:js.lib.Error) {
		super("crash");

		loadTemplate("crash");
		canBeClosedManually = false;

		var jPs = '<p>' + StringTools.replace(msg,"\n","</p><p>") + '</p>';
		jContent.find(".warning").append(jPs);

		jContent.find(".log").html(error.stack);
	}
}