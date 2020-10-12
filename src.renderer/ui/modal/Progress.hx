package ui.modal;

class Progress extends ui.Modal {
	public function new(?title:String, ops:Array< Void->String >, ?onComplete:Void->Void) {
		super();

		jModalAndMask.addClass("progress");
		jWrapper.hide().slideDown(60);

		if( title==null )
			title = L.t._("Please wait...");
		jContent.append('<h2>$title</h2>');

		var jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		var cur = 0;
		var total = ops.length;
		createChildProcess( (p)->{
			if( ops.length==0 )
				close();
			else {
				var label = ops.shift()();
				cur++;
				var pct = 100 * cur/total;
				jBar.find(".bar").css({ width:pct+"%" });
				jBar.find(".label").text(label);
			}
		});
	}
}