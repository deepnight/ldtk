package form;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class Input<T> {
	#if !macro
	public var jInput : js.jquery.JQuery;
	var rawGetter : Void->T;
	var rawSetter : T->Void;

	var lastValidValue : T;
	public var validityCheck : Null<T->Bool>;
	public var validityError : Null<T->Void>;
	var linkedEvents : Map<GlobalEvent,Bool> = new Map();
	public var customConfirm: (oldValue:T,newValue:T)->Null<LocaleString>;
	var autoClasses : Array<{ className:String, cond:T->Bool}> = [];

	private function new(jElement:js.jquery.JQuery, rawGetter:Void->T, rawSetter:T->Void) {
		if( jElement.length==0 )
			throw "Empty jQuery object";

		this.rawGetter = rawGetter;
		this.rawSetter = rawSetter;
		jInput = jElement;
		jInput.off(".input");
		writeValueToInput();
		lastValidValue = getter();

		jInput.on("focus.input", function(ev) {
			jInput.select();
			checkGuide();
		});
		jInput.on("blur.input", function(ev) {
			checkGuide();
		});
		jInput.on("change.input", function(_) {
			onInputChange();
		});
		jInput.on("keydown.input", function(ev:js.jquery.Event) {
			if( ev.key=="Enter" )
				onEnterKey();
		});
		jInput.on("mousedown.input", function(ev:js.jquery.Event) {
			if( ev.button==1 )
				resetToDefault();
		});
	}

	function onEnterKey() {
		jInput.blur();
	}

	dynamic function resetToDefault() {
		setter(null);
	}

	function checkGuide() {
		if( jInput.is("[type=checkbox], [type=radio]") )
			return;

		var jGuide = jInput.nextAll(".guide");
		if( jGuide.length==0 )
			jInput.prev(".guide");

		if( jInput.is(":focus") ) {
			jGuide.show();
			jGuide.css("margin-top", (-jGuide.outerHeight() - 4)+"px");
		}
		else
			jGuide.hide();
	}

	function getter() {
		return rawGetter();
	}
	function setter(v:T) {
		return rawSetter(v);
	}

	function getSlideDisplayValue(v:Float) : String {
		return null;
	}

	function enableIncrementControls() {
		function _inc(i:Float) {
			var v = Std.parseFloat( jInput.val() );
			if( !M.isValidNumber(v) )
				v = 0;
			jInput.val( Std.string(v+i) );
			onInputChange();
		}
		jInput
			.off(".increment")
			.on("keydown.increment", (ev:js.jquery.Event)->{
				switch ev.key {
					case "ArrowUp":
						_inc(1);
						ev.preventDefault();

					case "ArrowDown":
						_inc(-1);
						ev.preventDefault();

					case _:
				}
			});
	}

	public function addAutoClass(className:String, cond:T->Bool) {
		autoClasses.push({ className:className, cond:cond });
		checkAutoClasses();
	}

	function checkAutoClasses() {
		for( ac in autoClasses )
			if( ac.cond( getter() ) )
				jInput.addClass(ac.className);
			else
				jInput.removeClass(ac.className);
	}

	public function enableSlider(speed=1.0, showIcon=true) {
		if( getSlideDisplayValue(0)==null )
			throw "Slider is not supported for this Input type";

		jInput.addClass("slider");
		if( !showIcon )
			jInput.addClass("hideSliderIcon");

		var startX = -1.;
		var threshold = 3;

		jInput
			.off(".slider")
			.on("mousedown.slider", function(ev:js.jquery.Event) {
				if( ev.button!=0 )
					return;

				startX = ev.pageX;
				ev.preventDefault();

				var startVal : Float = cast getter();
				App.ME.jDoc
					.off(".slider")
					.on("mousemove.slider", function(ev) {
						if( ev.button!=0 )
							return;

						var delta = startX<0 ? 0 : ev.pageX-startX;
						if( M.fabs(delta)>=threshold ) {
							var v = getSlideDisplayValue( startVal + delta*0.008*speed );
							jInput.val( v );
							jInput.val( Std.string( parseInputValue() ) ); // Force clamping
							jInput.addClass("editing");
						}
					})
					.on("mouseup.slider", function(ev) {
						if( ev.button!=0 )
							return;

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


	function onInputChange(bypassConfirm=false) {
		var newValue = parseInputValue();
		newValue = fixValue(newValue);

		if( !bypassConfirm && customConfirm!=null ) {
			var msg = customConfirm(lastValidValue, newValue);
			if( msg!=null ) {
				new ui.modal.dialog.Confirm(
					jInput,
					msg,
					true,
					onInputChange.bind(true),
					()->{
						setter(lastValidValue);
						writeValueToInput();
					}
				);
				return;
			}
		}

		if( validityCheck!=null && !validityCheck(parseInputValue()) ) {
			var err = parseInputValue();
			setter( lastValidValue );
			writeValueToInput();
			if( validityError==null )
				N.error("This value isn't valid.");
			else
				validityError(err);
			return;
		}

		onBeforeSetter(newValue);
		setter(newValue);
		writeValueToInput();
		lastValidValue = getter();
		onChange();
		onValueChange( getter() );
		checkAutoClasses();
		for(e in linkedEvents.keys())
			Editor.ME.ge.emit(e);
	}

	public function linkEvent(eid:GlobalEvent) {
		linkedEvents.set(eid,true);
	}

	public dynamic function onBeforeSetter(v:T) {}
	public dynamic function fixValue(v:T) : T { return v; }
	public dynamic function onChange() {}
	public dynamic function onValueChange(v:T) {}

	function parseInputValue() : T {
		return jInput.val();
	}

	function writeValueToInput() {
		jInput.val( cleanInputString( getter() ) );
	}

	function cleanInputString(v:T) : String {
		return v==null ? "" : Std.string(v);
	}


	public function setEnabled(v:Bool) {
		jInput.prop("disabled", !v);
	}

	public function setVisibility(v:Bool) {
		if( v )
			jInput.show();
		else
			jInput.hide();

		// Related label
		if( jInput.attr("id")!=null ) {
			var jForm = jInput.closest(".form, form");
			var jLabel = jForm.find('label[for="'+jInput.attr('id')+'"]');
			if( v )
				jLabel.show();
			else
				jLabel.hide();
		}
	}

	public function enable() {
		jInput.prop("disabled",false);
	}

	public function disable() {
		jInput.prop("disabled",true);
	}

	public function setPlaceholder(v:Dynamic) {
		if( !jInput.is("[type=text]") )
			throw "Not compatible with this input type";
		jInput.attr("placeholder", Std.string(v));
	}

	#end


	public static macro function linkToHtmlInput(variable:Expr, formInput:ExprOf<js.jquery.JQuery>) {
		var t = Context.typeof(variable);
		switch t {
			case TInst(_.toString()=>"String", _):
				return macro {
					new form.input.StringInput(
						$formInput,
						function() return $variable,
						function(v) $variable = v
					);
				}

			case TAbstract(_.toString()=>"Null", [ TInst(_.toString()=>"String", params) ]) :
				return macro {
					var i = new form.input.StringInput(
						$formInput,
						function() return $variable,
						function(v) $variable = v
					);
					i.allowNull = true;
					i;
				}

			case TAbstract(_.toString()=>"Null", [ TAbstract(_.toString()=>"Int", params) ]) :
				return macro {
					var i = new form.input.IntInput(
						$formInput,
						function() return $variable,
						function(v) $variable = v
					);
					i.allowNull = true;
					i;
				}


			case TAbstract(t, params):
				switch t.toString() {
					case "Int", "UInt":
						return macro {
							new form.input.IntInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}

					case "Float":
						return macro {
							new form.input.FloatInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}

					case "Bool":
						return macro {
							if( $formInput.length==0 || !$formInput.is("[type=checkbox], select") )
								null;
							else
								new form.input.BoolInput(
									$formInput,
									function() return $variable,
									function(v) $variable = v
								);
						}

					case "Null":
						Context.fatalError("Unsupported nullable "+params, variable.pos);
						return macro {}

					case _:
						Context.fatalError("Unsupported abstract type "+t, variable.pos);
				}

			case _ :
				Context.fatalError("Unsupported type "+t, variable.pos);
		}
		return macro {}
	}
}