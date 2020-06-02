package form.input;

class FloatInput extends form.Input<Float> {
	var min : Float = M.T_INT16_MIN;
	var max : Int = M.T_INT16_MAX;
	public var displayAsPct(default,set) : Bool;

	public function new(j:js.jquery.JQuery, getter:Void->Float, setter:Float->Void) {
		super(j, floatGetter.bind(getter), floatSetter.bind(setter));
		displayAsPct = false;
	}

	function set_displayAsPct(v) {
		displayAsPct = v;
		input.val( Std.string(getter()) );
		return displayAsPct;
	}

	function floatGetter(def:Void->Float) : Float {
		return def() * ( displayAsPct ? 100 : 1 );
	}

	function floatSetter(def:Float->Void, v:Float) {
		def( v / ( displayAsPct ? 100 : 1) );
	}

	public function setBounds(min,max) {
		this.min = min;
		this.max = max;
	}

	override function parseFormValue() : Float {
		var v = Std.parseFloat( input.val() );
		if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
			v = 0;

		return M.fclamp( v, min * (displayAsPct?100:1), max * (displayAsPct?100:1) );
	}
}
