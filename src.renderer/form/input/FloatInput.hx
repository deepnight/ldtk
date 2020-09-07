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
		jInput.val( Std.string( M.round(getter()) ) );

		if( displayAsPct ) {
			jInput.addClass("quickEdit");
			var startX = -1.;
			var threshold = 3;
			jInput.off(".quickEdit")
				.on("mousedown.quickEdit", function(ev:js.jquery.Event) {
					startX = ev.pageX;
					ev.preventDefault();

					var startVal = getter();
					App.ME.jDoc
						.off(".quickEdit")
						.on("mousemove.quickEdit", function(ev) {
							var delta = startX<0 ? 0 : ev.pageX-startX;
							if( M.fabs(delta)>=threshold ) {
								jInput.val( M.round(startVal + delta*0.8) );
								jInput.val( parseInputValue() ); // Force clamping
								jInput.addClass("editing");
							}
						})
						.on("mouseup.quickEdit", function(ev) {
							App.ME.jDoc.off(".quickEdit");
							jInput.removeClass("editing");

							var delta = startX<0 ? 0 : ev.pageX-startX;
							if( M.fabs(delta)<=threshold )
								jInput.focus().select();
							else
								onInputChange();
						});
				});
		}
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

	override function parseInputValue() : Float {
		var v = Std.parseFloat( jInput.val() );
		if( Math.isNaN(v) || !Math.isFinite(v) || v==null )
			v = 0;

		return M.fclamp( v, min * (displayAsPct?100:1), max * (displayAsPct?100:1) );
	}
}
