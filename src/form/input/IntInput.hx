package form.input;

class IntInput extends form.Input<Int> {
	var min : Int = M.T_INT16_MIN;
	var max : Int = M.T_INT16_MAX;

	public function new(j:js.jquery.JQuery, getter:Void->Int, setter:Int->Void) {
		super(j, getter, setter);
	}

	public function setBounds(min,max) {
		this.min = min;
		this.max = max;
	}

	override function parseFormValue() : Int {
		var v = Std.parseInt( input.val() );
		return Math.isNaN(v) || !Math.isFinite(v) || v==null
			? 0
			: M.iclamp(v, min, max);
	}
}
