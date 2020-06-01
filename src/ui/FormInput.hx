package ui;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class FormInput {
	#if !macro
	var elem : js.jquery.JQuery;
	public var type : FormInputType;

	public var trimSpaces = true;
	var min : Float = -M.T_FLOAT_MIN;
	var max : Float = M.T_FLOAT_MAX;

	private function new(j:js.jquery.JQuery, value:Dynamic) {
		if( j.length==0 )
			trace("Empty jQuery object");

		elem = j;
		type = switch Type.typeof(value) {
			case TInt:
				IInt;

			case TClass(c):
				IText;

			case null, TNull, TFloat, TBool, TObject, TFunction, TEnum(_), TUnknown:
				throw "Unsupported value type "+Type.typeof(value);
		}
		elem.val(value);
		elem.off();
		elem.css("background","darkred");

		elem.change( function(_) {
			realValueSetter(switch type {
				case IText: getValueAsString();
				case IInt: getValueAsInt();
			});
			onChange();

			switch type {
				case IText: elem.val( getValueAsString() );
				case IInt: elem.val( getValueAsInt() );
			}
		});
	}

	function getTypedValue() : Dynamic {
		return switch type {
			case IText:
				var v = validateStr( elem.val() );
				return trimSpaces ? StringTools.trim(v) : v;

			case IInt:
				var v = Std.parseInt( elem.val() );
				if( !Math.isFinite(v) || Math.isNaN(v) || v==null )
					0;
				else
					M.iclamp(v, M.round(min), M.round(max));
		}
	}

	public function getValueAsInt() : Int {
		return getTypedValue();
	}

	public function getValueAsString() : String {
		var v = validateStr( elem.val() );
		return trimSpaces ? StringTools.trim(v) : v;
	}

	public function setIntBounds(min:Int,max:Int) {
		this.min = min;
		this.max = max;
	}


	dynamic function realValueSetter(v:Dynamic) {}

	public dynamic function validateInt(v:Int) : Int {
		return v;
	}

	public dynamic function validateStr(v:String) : String {
		return v;
	}


	public dynamic function onChange() {
		elem.css("background","orange");
	}

	#end

	public static macro function linkToField(jQuery:ExprOf<js.jquery.JQuery>, field:Expr) {
		return macro {
			var i = @:privateAccess new FormInput( $jQuery, $field );
			@:privateAccess i.realValueSetter = function(v:Dynamic) {
				$field = v;
			}
			i;
		}
	}
}