package form.input;

class IntInput extends form.Input<Int> {
	var min : Int = M.T_INT16_MIN;
	var max : Int = M.T_INT16_MAX;
	public var isColorCode(default,set) = false;

	public function new(j:js.jquery.JQuery, getter:Void->Int, setter:Int->Void) {
		super(j, getter, setter);
	}

	function set_isColorCode(v) {
		isColorCode = v;
		writeValueToInput();
		return isColorCode;
	}

	public function setBounds(min,max) {
		this.min = min;
		this.max = max;
	}

	override function writeValueToInput() {
		if( isColorCode )
			jInput.val( C.intToHex(getter()) );
		else
			super.writeValueToInput();
	}

	override function parseInputValue() : Int {
		if( isColorCode ) {
			var v = C.hexToInt( jInput.val() );
			return v;
		}
		else {
			var v = Std.parseInt( jInput.val() );
			if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
				v = 0;

			return M.iclamp(v, min, max);
		}
	}
}
