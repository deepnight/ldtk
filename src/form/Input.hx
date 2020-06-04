package form;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class Input<T> {
	#if !macro
	var input : js.jquery.JQuery;
	var getter : Void->T;
	var setter : T->Void;

	public function new(jElement:js.jquery.JQuery, getter, setter) {
		if( jElement.length==0 )
			trace("Empty jQuery object");

		this.getter = getter;
		this.setter = setter;
		input = jElement;
		input.off();
		writeValueToInput();

		input.change( function(_) {
			onInputChange();
		});
	}

	function onInputChange() {
		setter( parseInputValue() );
		writeValueToInput();
		onChange();
		onValueChange( getter() );
	}

	public dynamic function onChange() {}
	public dynamic function onValueChange(v:T) {}

	function parseInputValue() : T {
		return null;
	}

	function writeValueToInput() {
		input.val( Std.string( getter() ) );
	}

	#end

	/**
		Test
	**/
	public static macro function linkToHtmlInput(variable:Expr, formInput:ExprOf<js.jquery.JQuery>) {
		var t = Context.typeof(variable);
		switch t {
			case TInst(t, params):
				switch t.toString() {
					case "String":
						return macro {
							new form.input.StringInput(
								$formInput,
								function() return $variable,
								function(v) $variable = v
							);
						}
					case _: Context.fatalError("Unsupported instance type "+t, variable.pos);
				}

			case TEnum(eRef,_):
				var enumType = haxe.macro.TypeTools.getEnum(t);
				var enumExpr : Expr = {
					expr: EConst( CIdent(enumType.name) ), // TODO might need to add package+module here, one day
					pos: enumType.pos,
				}

				return macro {
					new form.input.EnumSelect(
						$formInput,
						$enumExpr,
						function() return cast $variable,
						function(v) $variable = cast v
					);
				}

			case TAbstract(t, params):
				switch t.toString() {
					case "Int":
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

					case _:
						Context.fatalError("Unsupported abstract type "+t, variable.pos);
				}

			case _ :
				Context.fatalError("Unsupported type "+t, variable.pos);
		}
		return macro {}
	}
}