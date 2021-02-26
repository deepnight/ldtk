package form.input;

class IntInput extends form.Input<Int> {
	var min : Int = M.T_INT16_MIN;
	var max : Int = M.T_INT16_MAX;
	public var isColorCode(default,set) = false;
	public var allowNull = false;

	public function new(j:js.jquery.JQuery, getter:Void->Int, setter:Int->Void) {
		super(j, getter, setter);
	}

	function set_isColorCode(v) {
		isColorCode = v;
		writeValueToInput();
		return isColorCode;
	}

	override function getSlideDisplayValue(v:Float):String {
		return Std.string(v);
	}

	override public function enableSlider(speed:Float = 1.0) {
		super.enableSlider(speed*11);
	}

	public function setBounds(min:Null<Float>, max:Null<Float>) {
		this.min = min==null ? M.T_INT16_MIN : Std.int(min);
		this.max = max==null ? M.T_INT16_MAX : Std.int(max);
	}

	override function writeValueToInput() {
		if( isColorCode )
			jInput.val( C.intToHex(getter()) );
		else
			super.writeValueToInput();
	}

	override function parseInputValue() : Int {
		if( allowNull && StringTools.trim( jInput.val() ).length==0 )
			return null;

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
