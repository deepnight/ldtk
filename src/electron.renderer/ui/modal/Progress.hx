package ui.modal;

typedef ProgressOp = {
	var ?label : Null<String>;
	var cb : Void->Void;
}

class Progress extends ui.Modal {
	static var ALL: Array<Progress> = [];

	public var done(default,null) = false;
	var nextLocked = false;

	public function new(title:String, opsPerCycle=1, ops:Array<ProgressOp>, ?onComplete:Void->Void) {
		super();

		ALL.push(this);
		canBeClosedManually = false;
		jModalAndMask.addClass("progress");
		jMask.hide().fadeIn(500);
		App.LOG.general('"$title", ${ops.length} operation(s):');

		jContent.append('<div class="title">$title</div>');

		var jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		var log = [];
		var cur = 0;
		var total = ops.length;

		function _updateBar(?label:String) {
			var pct = 100 * cur/total;
			jBar.find(".bar").css({ width:pct+"%" });
			if( label!=null )
				jBar.find(".label").text( label );
		}

		var time = haxe.Timer.stamp();
		createChildProcess( (p)->{
			if( editor!=null )
				editor.requestFps();

			if( nextLocked )
				return;

			if( ops.length==0 ) {
				// All done!
				canBeClosedManually = true;
				App.LOG.general('Done "$title" (${M.pretty(haxe.Timer.stamp()-time)}s)');
				done = true;
				_updateBar();

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

				if( onComplete!=null )
					onComplete();
			}
			else {
				// Execute "opsPerCycle" operation(s)

				var i = 0;
				while( i++<opsPerCycle && ops.length>0 ) {
					var op = ops.shift();
					nextLocked = true;
					delayer.addF(()->{
						op.cb();
						nextLocked = false;
					}, 1);
					_updateBar(op.label);
					if( op.label!=null )
						log.push(op.label);
					cur++;
				}
			}

		}, true);

		updateAllPositions();
	}


	public static function single( label:LocaleString, cb:Void->Void, onComplete:Void->Void ) : Progress {
		var p = new Progress(label, 1, [{ cb:cb }], onComplete);
		return p;
	}

	public static function hasAny() {
		for(e in ALL)
			if( !e.destroyed && !e.done )
				return true;
		return false;
	}

	@:allow(App)
	static function stopAll() {
		for(e in ALL)
			e.destroy();
	}

	static function updateAllPositions() {
		for(w in ALL)
			if( !w.destroyed )
				w.jWrapper.css({ marginTop:(8 + w.getStackIndex()*100)+"px" });
	}

	function getStackIndex() {
		var i = 0;
		for(e in ALL)
			if( e==this )
				return i;
			else
				i++;
		return 0;
	}

	override function onDispose() {
		super.onDispose();
		ALL.remove(this);
		updateAllPositions();
	}
}