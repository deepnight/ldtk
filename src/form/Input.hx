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

	private function new(jElement:js.jquery.JQuery, getter, setter) {
		if( jElement.length==0 )
			trace("Empty jQuery object");

		this.getter = getter;
		this.setter = setter;
		input = jElement;
		input.off();
		input.val( Std.string( getter() ) );

		input.change( function(_) {
			onInputChange();
		});
	}

	function onInputChange() {
		setter( parseFormValue() );
		input.val( Std.string( getter() ) );
		onChange();
		onValueChange( getter() );
	}

	public dynamic function onChange() {}
	public dynamic function onValueChange(v:T) {}

	function parseFormValue() : T {
		return null;
	}

	#end



	public static macro function linkToField(jQuery:ExprOf<js.jquery.JQuery>, field:Expr) {
		var t = Context.typeof(field);
		switch t {
			case TInst(t, params):
				switch t.toString() {
					case "String":
						return macro {
							new form.input.StringInput(
								$jQuery,
								function() return $field,
								function(v) $field = v
							);
						}
					case _: Context.fatalError("Unsupported type "+t, field.pos);
				}

			case TEnum(eRef,_):
				var enumType = haxe.macro.TypeTools.getEnum(t);
				var enumExpr : Expr = {
					expr: EConst( CIdent(enumType.name) ), // TODO might need to add package+module here, one day
					pos: enumType.pos,
				}

				return macro {
					new form.input.EnumSelect(
						$jQuery,
						$enumExpr,
						function() return cast $field,
						function(v) $field = cast v
					);
				}

			case TAbstract(t, params):
				switch t.toString() {
					case "Int":
						return macro {
							new form.input.IntInput(
								$jQuery,
								function() return $field,
								function(v) $field = v
							);
						}

					case _:
						Context.fatalError("Unsupported type "+t, field.pos);
				}

			case _ :
				Context.fatalError("Unsupported type "+t, field.pos);
		}
		return macro {}
		// return macro {
		// 	var i = @:privateAccess new FormInput( $jQuery );
		// 	// @:privateAccess i.realValueSetter = function(v:Dynamic) {
		// 		// $field = v;
		// 	// }
		// 	i;
		// }
	}
}