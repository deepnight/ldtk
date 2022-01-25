package ui.modal;

class MetaProgress extends ui.Modal {
	static var CUR: Null<MetaProgress> = null;
	static var MAX_FRAME_DURATION_S = 0.25;

	public var log : dn.Log;

	var idx = 0;
	var max = 1;
	var startTime = -1.;
	var jBar : js.jquery.JQuery;
	var title : String;

	var curRatio = 0.;
	var targetRatio = 0.;

	private function new(title:String, ops:Int) {
		super();

		if( CUR!=null && !CUR.isClosing() )
			CUR.close();

		this.title = title;
		CUR = this;
		canBeClosedManually = false;
		max = ops;

		jModalAndMask.addClass("metaProgress");
		jMask.remove();

		jContent.append('<div class="title">$title</div>');

		jBar = App.ME.jBody.find("xml#progressBar").children().clone();
		jBar.appendTo(jContent);

		updateBar();
	}


	public static inline function exists() return CUR!=null && !CUR.isClosing();
	public static inline function closeCurrent() {
		if( exists() )
			CUR.close();
	}
	public static inline function completeCurrent() {
		if( exists() )
			CUR.complete();
	}

	public static function start(title:String, ops:Int) {
		closeCurrent();
		return new MetaProgress(title, ops);
	}

	public static inline function getHeight() {
		return exists() ? CUR.jWrapper.outerHeight() : 0;
	}

	public static function advance(n=1) {
		if( exists() ) {
			CUR.idx+=n;
			if( CUR.idx>=CUR.max )
				CUR.complete();
			else
				CUR.updateBar();
		}
	}

	public function complete() {
		idx = max;
		updateBar();
		cd.setS("autoKillLock",0.2);
	}


	function updateBar(immediate=false) {
		targetRatio = 100 * idx/max;
		if( immediate ) {
			curRatio = targetRatio;
			jBar.find(".bar").css({ width:targetRatio+"%" });
		}
	}

	override function onDispose() {
		super.onDispose();
		if( CUR==this )
			CUR = null;
	}

	override function update() {
		super.update();

		if( curRatio!=targetRatio ) {
			curRatio += (targetRatio-curRatio) * ( idx>=max ? 0.6 : 0.3 );
			if( M.fabs(curRatio-targetRatio)<=0.01 )
				curRatio = targetRatio;
			jBar.find(".bar").css({ width:curRatio+"%" });
		}

		if( idx>=max && !cd.has("autoKillLock") )
			close();
	}
}