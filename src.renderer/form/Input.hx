package form;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class Input<T> {
	#if !macro
	public var jInput : js.jquery.JQuery;
	var getter : Void->T;
	var setter : T->Void;

	var lastValidValue : T;
	public var validityCheck : Null<T->Bool>;
	public var validityError : Null<T->Void>;
	var linkedEvents : Map<GlobalEvent,Bool> = new Map();

	private function new(jElement:js.jquery.JQuery, getter, setter) {
		if( jElement.length==0 )
			throw "Empty jQuery object";

		this.getter = getter;
		this.setter = setter;
		jInput = jElement;
		jInput.off();
		writeValueToInput();
		lastValidValue = getter();

		jInput.focus( function(ev) {
			jInput.select();
		});
		jInput.change( function(_) {
			onInputChange();
		});
	}

	function onInputChange() {
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

		setter( parseInputValue() );
		writeValueToInput();
		lastValidValue = getter();
		for(e in linkedEvents.keys())
			Editor.ME.ge.emit(e);
		onChange();
		onValueChange( getter() );
	}

	public function linkEvent(eid:GlobalEvent) {
		linkedEvents.set(eid,true);
	}

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

	public function setPlaceholder(v:T) {
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