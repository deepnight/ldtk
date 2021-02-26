package form.input;

class FloatInput extends form.Input<Float> {
	var min : Float = M.T_INT16_MIN;
	var max : Float = M.T_INT16_MAX;
	var displayAsPct : Bool;
	var valueStep = -1.;
	public var allowNull = false;

	public function new(j:js.jquery.JQuery, rawGetter:Void->Float, rawSetter:Float->Void) {
		super(j, rawGetter, rawSetter);
		displayAsPct = false;
	}

	public function setValueStep(step:Float) {
		valueStep = step<=0 ? -1 : step;
		writeValueToInput();
	}

	// public function enableSlider() {
	// 	jInput.addClass("slider");
	// 	var startX = -1.;
	// 	var threshold = 3;

	// 	jInput
	// 		.off(".slider")
	// 		.on("mousedown.slider", function(ev:js.jquery.Event) {
	// 			startX = ev.pageX;
	// 			ev.preventDefault();

	// 			var startVal = getter();
	// 			App.ME.jDoc
	// 				.off(".slider")
	// 				.on("mousemove.slider", function(ev) {
	// 					var delta = startX<0 ? 0 : ev.pageX-startX;
	// 					if( M.fabs(delta)>=threshold ) {
	// 						var v = displayAsPct
	// 							? M.round( startVal + delta*0.8 )
	// 							: startVal + delta*0.008;
	// 						jInput.val( applyStep(v) );
	// 						jInput.val( parseInputValue() ); // Force clamping
	// 						jInput.addClass("editing");
	// 					}
	// 				})
	// 				.on("mouseup.slider", function(ev) {
	// 					App.ME.jDoc.off(".slider");
	// 					jInput.removeClass("editing");

	// 					var delta = startX<0 ? 0 : ev.pageX-startX;
	// 					if( M.fabs(delta)<=threshold )
	// 						jInput.focus().select();
	// 					else
	// 						onInputChange();
	// 				});
	// 		});
	// }


	public function enablePercentageMode(slider=true) {
		displayAsPct = true;
		writeValueToInput();
		if( slider )
			enableSlider( displayAsPct ? 100 : 1 );
	}

	static var zerosReg = ~/([\-0-9]+\.[0-9]*?)0{3,}/g;
	override function getSlideDisplayValue(v:Float):String {
		var str = Std.string( M.round( applyStep(v)/0.05 )*0.05 );
		if( zerosReg.match(str) )
			str = zerosReg.matched(1);
		return str;
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
		else
			return applyStep( rawGetter() * ( displayAsPct ? 100 : 1 ) );
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
		if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
			v = 0;

		return M.fclamp( v, min * (displayAsPct?100:1), max * (displayAsPct?100:1) );
	}
}
