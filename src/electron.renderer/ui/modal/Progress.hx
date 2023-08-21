package ui.modal;

typedef ProgressOp = {
	var ?label : Null<String>;
	var cb : Void->Void;
	var ?isExpensive : Bool; // true if cb() is guaranteed to take a long time
}

enum ProgressState {
	WaitingOther;
	InitFrame;
	Running;
	EndFrame;
	Completed;
}

class Progress extends ui.Modal {
	static var ALL: Array<Progress> = [];
	static var MAX_FRAME_DURATION_S = 0.25;

	public var log : dn.Log;

	var state = WaitingOther;
	var curOps : Array<ProgressOp> = [];
	var curIdx = 0;
	var opsCount : Int;
	var startTime = -1.;
	var jBar : js.jquery.JQuery;
	var title : String;
	var onComplete : Null<Void->Void>;

	public function new(title:String, ?ops:Array<ProgressOp>, ?onComplete:Void->Void) {
		super();

		log = new dn.Log();
		var name = dn.Lib.buildShortName(title, 10);
		log.def = (s)->log.add("progress", '$name: '+s);
		this.title = title;
		ALL.push(this);
		canBeClosedManually = false;
		curOps = ops==null ? [] : ops;
		opsCount = curOps.length;
		this.onComplete = onComplete;

		jModalAndMask.addClass("progress");
		jMask.hide();
		App.LOG.general('Progress created.');

		jContent.append('<div class="title">$title</div>');

		jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		updateBar();
		updateAllPositions();
	}


	public function addOp(op:ProgressOp) {
		if( destroyed || state==Completed )
			throw "addOp() called on completed Progress";

		curOps.push(op);
		opsCount++;
		updateBar();
	}


	function updateBar(?label:String) {
		var pct = 100 * curIdx/opsCount;
		jBar.find(".bar").css({ width:pct+"%" });

		if( label!=null )
			jBar.find(".label").text( label );
		else
			jBar.find(".label").empty();
	}

	/**
		Create a single op Progress bar (useful for long operations)
	**/
	public static inline function single( label:String, cb:Void->Void, onComplete:Void->Void ) : Progress {
		return new Progress(label, [{ cb:cb }], onComplete);
	}


	public static function hasAny() {
		for(e in ALL)
			if( !e.destroyed )
				return true;
		return false;
	}

	@:allow(App)
	static function stopAll() {
		for(e in ALL)
			e.destroy();
	}

	public function cancel() {
		destroy();
	}

	static function updateAllPositions() {
		var off = MetaProgress.exists() ? MetaProgress.getHeight() : 0;
		for(w in ALL)
			if( !w.destroyed ) {
				var idx = w.getStackIndex();
				w.jWrapper.css({ marginTop:(off + 8 + idx*100)+"px" });
				if( idx>=6 )
					w.jWrapper.hide();
				else {
					w.jWrapper.show();
					if( idx>=4 )
						w.jWrapper.css({ opacity:0.4 });
					else
						w.jWrapper.css({ opacity:1 });
				}
			}
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


	override function update() {
		super.update();

		switch state {
			case WaitingOther:
				log.def("Waiting...");
				if( ALL[0]==this )
					state = InitFrame;

			case InitFrame:
				dn.js.ElectronTools.disableThrottling();
				App.LOG.general('Progress started: : "$title", ${curOps.length} operation(s)');
				log.def("Started...");
				state = Running;
				jMask.fadeIn(500);
				updateBar( curOps.length>0 ? curOps[0].label : null );

			case Running:
				if( startTime<0 )
					startTime = haxe.Timer.stamp();

				var spent = 0.;
				while( curOps.length>0 && spent<MAX_FRAME_DURATION_S ) {
					if( spent>0 && curOps[0].isExpensive ) // ensure "expensive" op start in their own frame
						break;

					var op = curOps.shift();
					var start = haxe.Timer.stamp();
					op.cb();
					var t = haxe.Timer.stamp()-start;
					spent += t;
					curIdx++;

					// #if debug
					// log.def("  "+(op.label==null?"Unknown":op.label)+": "+M.pretty(t,1)+"s");
					// #end
				}
				if( curOps.length==0 )
					state = EndFrame;
				else
					updateBar(curOps[0].label);

			case EndFrame:
				var t = M.pretty( haxe.Timer.stamp()-startTime, 1 );
				log.def('Completed (${t}s)...');
				App.LOG.general('Progress completed: "$title" (${t}s)');
				state = Completed;
				updateBar();

			case Completed:
				if( onComplete!=null )
					onComplete();
				dn.js.ElectronTools.enableThrottling();
				destroy();
		}

	}
}