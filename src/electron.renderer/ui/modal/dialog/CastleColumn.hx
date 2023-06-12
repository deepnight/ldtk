package ui.modal.dialog;

import cdb.Sheet;
import cdb.Data;

class CastleColumn extends ui.modal.Dialog {
	var onConfirm : Null<Column->Void>;
	var sheet : Sheet;
	var column : Null<Column>;

	public function new(sheet:cdb.Sheet, ?column:Column, ?onConfirm:Column->Void) {
		super();
		this.onConfirm = onConfirm;
		this.sheet = sheet;
		this.column = column;
		loadTemplate("castleColumn");

		var jConfirm = jContent.find(".confirm");
		var jCancel = jContent.find(".cancel");

		jCancel.click( _-> {
			close();
		});

		if (column == null) {
			jConfirm.click( _-> {
				var c = getColumn();
				var result = sheet.addColumn(c);
				if (result != null) {
					Notification.error(result);
				}  else {
					Notification.success("Column created succesfully");
					close();
					onConfirm(c);
				}
			});
		} else {
			editColumn(column);
			jConfirm.click( _-> {
				var newColumn = getColumn();
				var result = sheet.base.updateColumn(sheet, column, newColumn);
				if (result != null) {
					Notification.error(result);
				}  else {
					Notification.success("Column edited succesfully");
					close();
					onConfirm(newColumn);
				}
			});
		}
	}

	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);
		switch keyCode {
			case K.ENTER:
				//column == null ? createColumn() : close();

			case _:
		}
	}

	override function onClickMask() {
		super.onClickMask();

		// if( onCancel!=null )
		// 	onCancel();
	}

	function editColumn(c:Column) {
		jContent.find("input[name=name]").val(c.name);
		jContent.find("select[name=type]").val(c.type.getName().substr(1).toLowerCase());
		jContent.find("input[name=required]").prop("checked", !column.opt);
	}

	function createColumn() {
		var c = getColumn();
		var result = sheet.addColumn(c);
		if (result != null) {
			Notification.error(result);
		}  else {
			Notification.success("Column created succesfully");
			close();
		}
	}
	function getColumn() {
		var name = jContent.find("input[name=name]").val();
		var type = getType(jContent.find("select[name=type]").val());
		var c:Column = {
			name: name,
			type: type,
			typeStr: null
		};
		c.opt = !jContent.find("input[name=required]").prop("checked");

		return c;
	}

	function getType(type:String) {
		// TODO implement all types
		var type:ColumnType = switch(type) {
			case "id": TId;
			case "int": TInt;
			case "float": TFloat;
			case "string": TString;
			case "bool": TBool;
			case "enum":
				TImage;
				// var vals = StringTools.trim(v.values).split("\n");
				// vals = [for ( v in vals) for (e in v.split(",")) e];
				// vals.removeIf(function(e) {
				// 	return StringTools.trim(e) == "";
				// });
				// if( vals.length == 0 ) {
				// 	error("Missing value list");
				// 	return null;
				// }
				// TEnum([for( f in vals ) StringTools.trim(f)]);
			case "flags":
				TImage;
				// var vals = StringTools.trim(v.values).split("\n");
				// vals = [for ( v in vals) for (e in v.split(",")) e];
				// vals.removeIf(function(e) {
				// 	return StringTools.trim(e) == "";
				// });
				// if( vals.length == 0 ) {
				// 	error("Missing value list");
				// 	return null;
				// }
				// if( vals.length > 30 ) {
				// 	error("Too many possible values");
				// 	return null;
				// }
				// TFlags([for( f in vals ) StringTools.trim(f)]);
			case "ref":
				TImage;
				// var s = base.sheets[Std.parseInt(v.sheet)];
				// if( s == null ) {
				// 	error("Sheet not found");
				// 	return null;
				// }
				// TRef(s.name);
			case "image":
				TImage;
			case "list":
				TList;
			case "custom":
				TList;
				// var t = base.getCustomType(v.ctype);
				// if( t == null ) {
				// 	error("Type not found");
				// 	return null;
				// }
				// TCustom(t.name);
			case "color":
				TColor;
			case "layer":
				TColor;
				// var s = base.sheets[Std.parseInt(v.sheet)];
				// if( s == null ) {
				// 	error("Sheet not found");
				// 	return null;
				// }
				// TLayer(s.name);
			case "file":
				TFile;
			case "tilepos":
				TTilePos;
			case "tilelayer":
				TTileLayer;
			case "dynamic":
				TDynamic;
			case "properties":
				TProperties;
			case _:
				null;
		};
		return type;
	}
}