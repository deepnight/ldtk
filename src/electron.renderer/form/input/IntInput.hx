package form.input;

class IntInput extends form.Input<Int> {
	var min : Int = M.T_INT16_MIN;
	var max : Int = M.T_INT16_MAX;
	var isColorCode = false;
	public var allowNull = false;
	var emptyValue : Null<Int>;
	var unit = 0;

	public function new(j:js.jquery.JQuery, getter:Void->Int, setter:Int->Void) {
		isColorCode = j.is("[type=color]");
		super(j, getter, setter);
		enableIncrementControls();
	}

	public function setEmptyValue(v:Int) {
		emptyValue = v;
		writeValueToInput();
	}

	public function setUnit(grid:Int) {
		unit = grid;
		writeValueToInput();
	}

	override function getSlideDisplayValue(v:Float):String {
		return Std.string(v);
	}

	override public function enableSlider(speed:Float = 1.0, showIcon=true) {
		super.enableSlider(speed*11, showIcon);
	}

	public function setBounds(min:Null<Float>, max:Null<Float>) {
		this.min = min==null ? M.T_INT16_MIN : Std.int(min);
		this.max = max==null ? M.T_INT16_MAX : Std.int(max);
	}

	override function writeValueToInput() {
		if( getter()==emptyValue )
			jInput.val("");
		else if( isColorCode )
			jInput.val( C.intToHex(getter()) );
		else if( unit>1 && getter()!=null )
			jInput.val( Std.string( getter()/unit ) );
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
		else if( unit>1 ) {
			var v = Std.parseFloat( jInput.val() );
			if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
				v = 0;
			v*=unit;
			return M.iclamp(Std.int(v), min, max);
		}
		else {
			var v = Std.parseInt( jInput.val() );
			if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
				v = 0;

			return M.iclamp(v, min, max);
		}
	}
}
