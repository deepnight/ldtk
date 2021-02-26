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
	public var confirmMessage: Null<LocaleString>;

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
		});
		jInput.on("change.input", function(_) {
			onInputChange();
		});
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

	public function enableSlider(speed=1.0) {
		if( getSlideDisplayValue(0)==null )
			throw "Slider is not supported for this Input type";

		jInput.addClass("slider");
		var startX = -1.;
		var threshold = 3;

		jInput
			.off(".slider")
			.on("mousedown.slider", function(ev:js.jquery.Event) {
				startX = ev.pageX;
				ev.preventDefault();

				var startVal : Float = cast getter();
				App.ME.jDoc
					.off(".slider")
					.on("mousemove.slider", function(ev) {
						var delta = startX<0 ? 0 : ev.pageX-startX;
						if( M.fabs(delta)>=threshold ) {
							var v = getSlideDisplayValue( startVal + delta*0.008*speed );
							jInput.val( v );
							jInput.val( Std.string( parseInputValue() ) ); // Force clamping
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


	function onInputChange(bypassConfirm=false) {
		if( !bypassConfirm && confirmMessage!=null ) {
			new ui.modal.dialog.Confirm(
				jInput,
				confirmMessage,
				true,
				onInputChange.bind(true),
				()->{
					setter(lastValidValue);
					writeValueToInput();
				}
			);
			return;
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

		onBeforeSetter();
		var v = parseInputValue();
		v = fixValue(v);
		setter(v);
		writeValueToInput();
		lastValidValue = getter();
		onChange();
		onValueChange( getter() );
		for(e in linkedEvents.keys())
			Editor.ME.ge.emit(e);
	}

	public function linkEvent(eid:GlobalEvent) {
		linkedEvents.set(eid,true);
	}

	public dynamic function onBeforeSetter() {}
	public dynamic function fixValue(v:T) : T { return v; }
	public dynamic function onChange() {}
	public dynamic function onValueChange(v:T) {}

	function parseInputValue() : T {
		return jInput.val();
	}

	function writeValueToInput() {
		var v = getter();
		if( v==null )
			jInput.val("");
		else
			jInput.val( Std.string( getter() ) );
	}


	public function setEnabled(v:Bool) {
		jInput.prop("disabled", !v);
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

			// case TEnum(eRef,params):
			// 	var type = eRef.get();
			// 	var fullPath = type.module.length==0 ? type.name : type.module+"."+type.name;
			// 	var packExpr : Expr = {
			// 		expr: EConst( CIdent(type.module) ),
			// 		// expr: EConst( CIdent(type.pack.join(".")) ),
			// 		pos: variable.pos,
			// 	}
			// 	var enumExpr : Expr = {
			// 		expr: EField( packExpr, type.name ),
			// 		pos: variable.pos,
			// 	}

			// 	return macro {
			// 		new form.input.EnumSelect(
			// 			$formInput,
			// 			$enumExpr,
			// 			function() return cast $variable,
			// 			function(v) $variable = cast v
			// 		);
			// 	}


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