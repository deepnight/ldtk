package form.input;

class FloatInput extends form.Input<Float> {
	var min : Float = M.T_INT16_MIN;
	var max : Float = M.T_INT16_MAX;
	var displayAsPct : Bool;
	var valueStep = -1.;
	public var allowNull = false;
	public var nullReplacement : Null<Float> = null;
	var precision = 4;

	public function new(j:js.jquery.JQuery, rawGetter:Void->Float, rawSetter:Float->Void) {
		super(j, rawGetter, rawSetter);
		displayAsPct = false;
	}

	public function setPrecision(?p:Int) {
		precision = p==null ? -1 : M.iclamp(p,0,10);
		writeValueToInput();
	}

	override function cleanInputString(v:Float) {
		return v==null || precision<0 ? super.cleanInputString(v) : M.truncateStr(v,precision);
	}

	public function setValueStep(step:Float) {
		valueStep = step<=0 ? -1 : step;
		writeValueToInput();
		enableIncrementControls();
	}


	public function enablePercentageMode(slider=true) {
		displayAsPct = true;
		jInput.addClass("percentage");
		writeValueToInput();
		setValueStep(0.01);
		if( slider )
			enableSlider( displayAsPct ? 50 : 1 );
	}

	static var zerosReg = ~/([\-0-9]+\.[0-9]*?)0{3,}/g;
	override function getSlideDisplayValue(v:Float):String {
		if( displayAsPct )
			return Std.string( M.round(v) );
		else {
			var str = Std.string( M.round( applyStep(v)/0.05 )*0.05 );
			if( zerosReg.match(str) )
				str = zerosReg.matched(1);
			return str;
		}
	}

	function applyStep(v:Float) {
		if( valueStep<=0 )
			return v;
		else {
			var step = displayAsPct ? valueStep*100 : valueStep;
			return M.round( v/step ) * step;
		}
	}

	override function getter():Float {
		if( rawGetter()==null )
			return null;
		else {
			var v : Float = applyStep( rawGetter() * ( displayAsPct ? 100 : 1 ) );
			if( M.fabs(v-Std.int(v))<=0.000001 )
				return Std.int(v);
			else
				return v;
		}
	}

	override function setter(v:Float) {
		if( allowNull && v==null )
			rawSetter(null);
		else
			rawSetter( applyStep(v) / ( displayAsPct ? 100 : 1) );
	}

	public function setBounds(min:Null<Float>, max:Null<Float>) {
		this.min = min==null ? M.T_INT16_MIN : min;
		this.max = max==null ? M.T_INT16_MAX : max;
	}

	override function parseInputValue() : Float {
		if( allowNull && StringTools.trim( jInput.val() ).length==0 )
			return null;

		var v = Std.parseFloat( jInput.val() );
		if( Math.isNaN(v) || !Math.isFinite(v) || v==null ) {
			if( !allowNull && nullReplacement!=null )
				v = nullReplacement * ( displayAsPct ? 100 : 1);
			else
				v = 0;
		}

		return M.fclamp( v, min * (displayAsPct?100:1), max * (displayAsPct?100:1) );
	}
}
