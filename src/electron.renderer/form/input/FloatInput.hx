package form.input;

class FloatInput extends form.Input<Float> {
	var min : Float = M.T_INT16_MIN;
	var max : Float = M.T_INT16_MAX;
	var displayAsPct : Bool;
	var valueStep = -1.;

	public function new(j:js.jquery.JQuery, getter:Void->Float, setter:Float->Void) {
		super(j, floatGetter.bind(getter), floatSetter.bind(setter));
		displayAsPct = false;
	}

	public function setValueStep(step:Float) {
		valueStep = step<=0 ? -1 : step;
		writeValueToInput();
	}

	public function enableSlider() {
		jInput.addClass("slider");
		var startX = -1.;
		var threshold = 3;

		jInput
			.off(".slider")
			.on("mousedown.slider", function(ev:js.jquery.Event) {
				startX = ev.pageX;
				ev.preventDefault();

				var startVal = getter();
				App.ME.jDoc
					.off(".slider")
					.on("mousemove.slider", function(ev) {
						var delta = startX<0 ? 0 : ev.pageX-startX;
						if( M.fabs(delta)>=threshold ) {
							var v = displayAsPct
								? M.round( startVal + delta*0.8 )
								: startVal + delta*0.008;
							jInput.val( applyStep(v) );
							jInput.val( parseInputValue() ); // Force clamping
							jInput.addClass("editing");
						}
					})
					.on("mouseup.slider", function(ev) {
						App.ME.jDoc.off(".slider");
						jInput.removeClass("editing");

						var delta = startX<0 ? 0 : ev.pageX-startX;
						if( M.fabs(delta)<=threshold )
							jInput.focus().select();
						else
							onInputChange();
					});
			});
	}

	public function enablePercentageMode(slider=true) {
		displayAsPct = true;
		writeValueToInput();
		if( slider )
			enableSlider();
	}

	function applyStep(v:Float) {
		if( valueStep<=0 )
			return v;
		else {
			var step = displayAsPct ? valueStep*100 : valueStep;
			return M.round( v/step ) * step;
		}
	}

	function floatGetter(def:Void->Float) : Float {
		return applyStep( def() * ( displayAsPct ? 100 : 1 ) );
	}

	function floatSetter(def:Float->Void, v:Float) {
		def( applyStep(v) / ( displayAsPct ? 100 : 1) );
	}

	public function setBounds(min:Float, max:Float) {
		this.min = min;
		this.max = max;
	}

	override function parseInputValue() : Float {
		var v = Std.parseFloat( jInput.val() );
		if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
			v = 0;

		return M.fclamp( v, min * (displayAsPct?100:1), max * (displayAsPct?100:1) );
	}
}
