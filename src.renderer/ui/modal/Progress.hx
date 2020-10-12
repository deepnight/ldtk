package ui.modal;

class Progress extends ui.Modal {
	public function new(?title:String, ops:Array<{ label:String, cb:Void->Void }>, ?onComplete:Void->Void) {
		super();

		canBeClosedManually = false;
		jModalAndMask.addClass("progress");

		if( title==null )
			title = L.t._("Please wait...");
		jContent.append('<h2>$title</h2>');
		
		jMask.hide().fadeIn(500);

		var jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		var cur = 0;
		var total = ops.length;
		createChildProcess( (p)->{
			if( ops.length==0 ) {
				close();
			}
			else {
				var op = ops.shift();
				delayer.addF(op.cb, 1);
				var pct = 100 * cur/total;
				jBar.find(".bar").css({ width:pct+"%" });
				jBar.find(".label").text( op.label );
				cur++;
			}
		}, true);
	}
}