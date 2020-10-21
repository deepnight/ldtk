package ui.modal;

class Progress extends ui.Modal {
	public function new(title:String, ops:Array<{ label:String, cb:Void->Void }>, ?onComplete:Void->Void) {
		super();

		App.LOG.general('"$title", ${ops.length} operation(s):');

		canBeClosedManually = false;
		jModalAndMask.addClass("progress");
		jMask.hide().fadeIn(500);

		jContent.append('<h2>$title</h2>');

		var jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		var log = [];
		var cur = 0;
		var total = ops.length;
		createChildProcess( (p)->{
			if( ops.length==0 ) {
				// Done!
				canBeClosedManually = true;
				if( onComplete!=null )
					onComplete();

				if( !App.ME.isCtrlDown() || !App.ME.isShiftDown() )
					close();
				else {
					// Display debug log
					var jButton = new J('<button>Close</button>');
					jButton.appendTo(jContent);
					var jLog = new J('<ul class="log"/>');
					jLog.appendTo(jContent);
					for(l in log)
						jLog.append('<li>$l</li>');
					jButton.click( (_)->close() );
					p.destroy();
				}
			}
			else {
				// Execute operation
				var op = ops.shift();
				delayer.addF(op.cb, 1);
				cur++;
				var pct = 100 * cur/total;
				jBar.find(".bar").css({ width:pct+"%" });
				jBar.find(".label").text( op.label );
				log.push(op.label);
				App.LOG.general('  - ${op.label} (${Std.int(pct)}%)');
			}
		}, true);
	}
}