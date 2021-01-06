package ui;

import data.def.FieldDef;
import data.inst.FieldInstance;

enum FormRelatedInstance {
	Entity(ei:data.inst.EntityInstance);
}

class FieldInstancesForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var relatedInstance : FormRelatedInstance;
	public var jWrapper: js.jquery.JQuery;
	var fieldDefs : Array<data.def.FieldDef>;
	var fieldInstGetter : (fd:FieldDef)->FieldInstance;


	public function new(
		elementInstance: FormRelatedInstance,
		fieldDefs: Array<FieldDef>,
		fieldInstGetter: (fd:FieldDef)->FieldInstance
	) {
		this.relatedInstance = elementInstance;
		jWrapper = new J('<ul class="form"/>');
		this.fieldDefs = fieldDefs;
		this.fieldInstGetter = fieldInstGetter;
		renderForm();
	}

	public function dispose() {
		jWrapper.remove();
		jWrapper = null;
	}

	public inline function isDestroyed() return jWrapper==null || jWrapper.parents("body").length==0;


	function hideInputIfDefault(arrayIdx:Int, input:js.jquery.JQuery, fi:data.inst.FieldInstance, isRequired=false) {
		input.off(".def").removeClass("usingDefault");

		if( fi.isUsingDefault(arrayIdx) ) {
			if( input.is("button") ) {
				// Button input
				if( fi.def.type!=F_Point || fi.def.canBeNull )
					input.addClass("gray usingDefault");
			}
			else if( input.is("[type=color]") ) {
				// Color input
				input.addClass("usingDefault");
				input.text("default");
			}
			else if( input.is(".colorWrapper") ) {
				// Wrapped color input
				input.addClass("usingDefault");
			}
			else if( !input.is("select") ) {
				// General INPUT
				var jRep = new J('<a class="usingDefault" href="#"/>');

				if( input.is("[type=checkbox]") ) {
					var chk = new J('<input type="checkbox"/>');
					chk.prop("checked", fi.getBool(arrayIdx));
					jRep.append( chk.wrap('<span class="value"/>').parent() );
					jRep.addClass("checkbox");
				}
				else
					jRep.append('<span class="value">${fi.getForDisplay(arrayIdx)}</span>');

				if( isRequired )
					jRep.append('<span class="label">Required!</span>');
				else
					jRep.append('<span class="label">Default</span>');

				jRep.on("click.def", function(ev) {
					ev.preventDefault();
					jRep.remove();
					input.show().focus();
					if( input.is("[type=checkbox]") ) {
						input.prop("checked", !fi.getBool(arrayIdx));
						input.change();
					}
				});
				jRep.insertBefore(input);
				input.hide();

				if( isRequired )
					jRep.addClass("required");

				input.on("blur.def", function(ev) {
					jRep.remove();
					hideInputIfDefault(arrayIdx, input, fi, isRequired);
				});
			}
			else if( input.is("select") && ( fi.getEnumValue(arrayIdx)!=null || fi.def.canBeNull ) ) {
				// SELECT case
				input.addClass("usingDefault");
				input.on("click.def", function(ev) {
					input.removeClass("usingDefault");
				});
				input.on("blur.def", function(ev) {
					hideInputIfDefault(arrayIdx, input, fi, isRequired);
				});
			}
		}
		else if( fi.def.type==F_Color || fi.def.type==F_Bool || fi.def.type==F_Point && fi.def.canBeNull ) {
			// Require a "Reset to default" link
			var span = input.wrap('<span class="inputWithDefaultOption"/>').parent();
			span.find("input").wrap('<span class="value"/>');
			var defLink = new J('<a class="reset" href="#">[ Reset ]</a>');
			defLink.appendTo(span);
			defLink.on("click.def", function(ev) {
				fi.parseValue(arrayIdx, null);
				onFieldChange();
				ev.preventDefault();
			});
		}
	}


	function createFieldInput(fi:data.inst.FieldInstance, arrayIdx:Int, jTarget:js.jquery.JQuery) {
		switch fi.def.type {
			case F_Int:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","text");
				input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( Std.string(fi.getInt(arrayIdx)) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

			case F_Color:
				var cHex = fi.getColorAsHexStr(arrayIdx);

				var jWrapper = new J('<label class="colorWrapper"/>');
				jWrapper.appendTo(jTarget);
				jWrapper.css({
					backgroundColor: cHex,
					borderColor: C.intToHex( C.toWhite( C.hexToInt(cHex), 0.2 ) ),
				});
				if( fi.isUsingDefault(arrayIdx) )
					jWrapper.append("(default)");

				var input = new J("<input/>");
				input.appendTo(jWrapper);
				input.attr("type","color");
				input.addClass("advanced");
				input.val(cHex);
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});

				hideInputIfDefault(arrayIdx, jWrapper, fi);

			case F_Float:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","text");
				input.attr("placeholder", fi.def.getDefault()==null ? "(null)" : fi.def.getDefault());
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( Std.string(fi.getFloat(arrayIdx)) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, input, fi);

			case F_String, F_Text:
				var input = if( fi.def.type==F_Text ) {
					var input = new J("<textarea/>");
					input.appendTo(jTarget);
					input.keyup( (ev)-> {
						input.css("height","auto");
						if( input.height() < input.get(0).scrollHeight ) {
							var padding = input.innerHeight() - input.height();
							input.height( input.get(0).scrollHeight+3 - padding );
						}
					});
					input;
				}
				else {
					var input = new J("<input/>");
					input.appendTo(jTarget);
					input.attr("type","text");
					input;
				}
				var def = fi.def.getStringDefault();
				input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( fi.getString(arrayIdx) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});
				if( fi.def.type==F_Text )
					input.keyup();
				hideInputIfDefault(arrayIdx, input, fi);

			case F_Point:
				if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull || !fi.def.isArray ) {
					// Button mode
					var jPick = new J('<button/>');
					if( !fi.valueIsNull(arrayIdx) )
						jPick.addClass("gray");
					jPick.appendTo(jTarget);
					jPick.addClass("point");
					if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull ) {
						jPick.addClass("required");
						jPick.text( "Point required!" );
					}
					else
						jPick.text( fi.valueIsNull(arrayIdx) ? "--none--" : fi.getPointStr(arrayIdx) );
					jPick.click( function(_) {
						if( Editor.ME.isSpecialToolActive(tool.PickPoint) ) {
							// Cancel
							Editor.ME.clearSpecialTool();
							renderForm();
						}
						else {
							// Start picking
							jPick.text("Cancel");
							startPointsEditing(fi, arrayIdx);
						}
					});

					if( fi.def.canBeNull && !fi.valueIsNull(arrayIdx) ) {
						var jRem = new J('<button class="dark removePoint">x</button>');
						jRem.appendTo(jTarget);
						jRem.click( (_)->{
							fi.parseValue(arrayIdx,null);
							onFieldChange();
						});
					}
				}
				else {
					// Text mode
					var jPoint = new J('<span class="point"/>');
					jPoint.appendTo(jTarget);
					jPoint.text( fi.getPointStr(arrayIdx) );
				}


			case F_Enum(name):
				var ed = Editor.ME.project.defs.getEnumDef(name);
				var select = new J("<select/>");
				select.appendTo(jTarget);

				// Null value
				if( fi.def.canBeNull || fi.getEnumValue(arrayIdx)==null ) {
					var opt = new J('<option/>');
					opt.appendTo(select);
					opt.attr("value","");
					if( fi.def.canBeNull )
						opt.text("-- null --");
					else {
						// SELECT shouldn't be null
						select.addClass("required");
						opt.text("[ Value required ]");
						select.click( function(ev) {
							select.removeClass("required");
							select.blur( function(ev) renderForm() );
						});
					}
					if( fi.getEnumValue(arrayIdx)==null )
						opt.attr("selected","selected");
				}

				for(v in ed.values) {
					var opt = new J('<option/>');
					opt.appendTo(select);
					opt.attr("value",v.id);
					opt.text(v.id);
					if( fi.getEnumValue(arrayIdx)==v.id && !fi.isUsingDefault(arrayIdx) )
						opt.attr("selected","selected");
				}

				select.change( function(ev) {
					var v = select.val()=="" ? null : select.val();
					fi.parseValue(arrayIdx, v);
					onFieldChange();
				});
				hideInputIfDefault(arrayIdx, select, fi);

			case F_Bool:
				var input = new J("<input/>");
				input.appendTo(jTarget);
				input.attr("type","checkbox");
				input.prop("checked",fi.getBool(arrayIdx));
				input.change( function(ev) {
					fi.parseValue( arrayIdx, Std.string( input.prop("checked") ) );
					onFieldChange();
				});

				hideInputIfDefault(arrayIdx, input, fi);

			case F_Path:
				var isRequired = fi.valueIsNull(arrayIdx) && !fi.def.canBeNull;
				var input = new J('<input class="fileInput" type="text"/>');
				input.appendTo(jTarget);
				input.attr("placeholder", "(null)");
				if( isRequired )
					input.addClass("required");

				if( !fi.isUsingDefault(arrayIdx) )
					input.val( fi.getFilePath(arrayIdx) );

				var jLocate = new J('<button class="locate gray"> <span class="icon locate"/> </button>');
				jLocate.appendTo(jTarget);
				jLocate.click( (_)->{
					if( !fi.valueIsNull(arrayIdx) ) {
						var path = project.makeAbsoluteFilePath( fi.getFilePath(arrayIdx) );
						JsTools.exploreToFile(path, true);
					}
				});

				var fileSelect = new J('<button class="fileSelectButton"> <span class="icon open"/> </button>');
				fileSelect.appendTo(jTarget);

				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange();
				});

				if( !fi.valueIsNull(arrayIdx) && !JsTools.fileExists( project.makeAbsoluteFilePath(fi.getFilePath(arrayIdx)) ) )
					input.addClass("fileNotFound");

				fileSelect.click( function(ev) {
					dn.electron.Dialogs.open(fi.def.acceptFileTypes, project.getProjectDir(), function( absPath ) {
						var fp = dn.FilePath.fromFile(absPath);
						fp.useSlashes();
						var relPath = project.makeRelativeFilePath(fp.full);
						input.val(relPath);
						fi.parseValue( arrayIdx, relPath );
						onFieldChange();
					});
				});

				hideInputIfDefault(arrayIdx, input, fi, isRequired);
		}
	}

	function getInstanceCx() {
		return switch relatedInstance {
			case Entity(ei): return ei.getCx( editor.curLayerDef );
		}
	}

	function getInstanceCy() {
		return switch relatedInstance {
			case Entity(ei): return ei.getCy( editor.curLayerDef );
		}
	}

	function getInstanceColor() {
		return switch relatedInstance {
			case Entity(ei): return ei.getSmartColor(true);
		}
	}

	function startPointsEditing(fi:data.inst.FieldInstance, editIdx:Int) {
		var t = new tool.PickPoint();

		t.pickOrigin = { cx:getInstanceCx(), cy:getInstanceCy(), color:getInstanceColor() }

		// Connect to last of path
		if( fi.def.isArray && fi.def.editorDisplayMode==PointPath ) {
			var pt = fi.getPointGrid( editIdx-1 );
			if( pt!=null )
				t.pickOrigin = { cx:pt.cx, cy:pt.cy, color:getInstanceColor() }
		}

		// Picking of a point
		t.onPick = function(m) {
			if( fi.def.isArray && editIdx>=fi.getArrayLength()-1 ) {
				// Append points in an array
				fi.parseValue(editIdx, m.cx+Const.POINT_SEPARATOR+m.cy);
				editIdx = fi.getArrayLength(); // continue after

				// Connect to path previous
				if( fi.def.editorDisplayMode==PointPath ) {
					var pt = fi.getPointGrid( editIdx-1 );
					if( pt!=null )
						t.pickOrigin = { cx:pt.cx, cy:pt.cy, color:getInstanceColor() }
				}
			}
			else {
				// Edit a single point
				Editor.ME.clearSpecialTool();
				fi.parseValue(editIdx, m.cx+Const.POINT_SEPARATOR+m.cy);
			}
			onFieldChange(true);
		}

		// Tool stopped
		t.onDisposeCb = function() {
			if( !isDestroyed() )
				renderForm();
		}

		Editor.ME.setSpecialTool(t);
	}



	function onFieldChange(keepCurrentSpecialTool=false) {
		if( !keepCurrentSpecialTool )
			Editor.ME.clearSpecialTool();

		onBeforeRender();
		renderForm();
		onChange();
	}

	public dynamic function onBeforeRender() {}
	public dynamic function onChange() {}


	function renderForm() {
		jWrapper.empty();

		if( fieldDefs.length==0 ) {
			jWrapper.append('<div class="empty">This element has no custom field.</div>');
			return;
		}

		// Fields
		for(fd in fieldDefs) {
			var fi = fieldInstGetter(fd);
			var li = new J("<li/>");
			li.attr("defUid", fd.uid);
			li.appendTo(jWrapper);

			// Identifier
			if( !fd.isArray )
				li.append('<label>${fi.def.identifier}</label>');
			else
				li.append('<label>${fi.def.identifier} (${fi.getArrayLength()})</label>');

			if( !fd.isArray ) {
				// Single value
				createFieldInput(fi, 0, li);
			}
			else {
				// Array
				var jArray = new J('<div class="array"/>');
				jArray.appendTo(li);
				if( fd.arrayMinLength!=null && fi.getArrayLength()<fd.arrayMinLength
					|| fd.arrayMaxLength!=null && fi.getArrayLength()>fd.arrayMaxLength ) {
					var bounds : String =
						fd.arrayMinLength==fd.arrayMaxLength ? Std.string(fd.arrayMinLength)
						: fd.arrayMaxLength==null ? fd.arrayMinLength+"+"
						: fd.arrayMinLength+"-"+fd.arrayMaxLength;
					jArray.append('<div class="warning">Array should have $bounds value(s)</div>');
				}

				var jArrayInputs = new J('<ul class="values"/>');
				jArrayInputs.appendTo(jArray);

				if( fi.def.type==F_Point && ( fi.def.editorDisplayMode==PointPath || fi.def.editorDisplayMode==PointStar ) ) {
					// No points listing if displayed as path
					var jLi = new J('<li class="compact"/>');
					var vals = [];
					for(i in 0...fi.getArrayLength())
						vals.push('<${fi.getPointStr(i)}>');
					jArrayInputs.append('<li class="compact">${vals.join(", ")}</li>');
					// jArrayInputs.append('<li class="compact">${fi.getArrayLength()} value(s)</li>');
				}
				else {
					var sortable = fi.def.type!=F_Point;
					for(i in 0...fi.getArrayLength()) {
						var li = new J('<li/>');
						li.appendTo(jArrayInputs);

						if( sortable )
							li.append('<div class="sortHandle"/>');

						createFieldInput(fi, i, li);

						// "Remove" button
						var jRemove = new J('<button class="remove dark">x</button>');
						jRemove.appendTo(li);
						var idx = i;
						jRemove.click( function(_) {
							fi.removeArrayValue(idx);
							onFieldChange();
						});
					}
					if( sortable )
						JsTools.makeSortable(jArrayInputs, function(ev:sortablejs.Sortable.SortableDragEvent) {
							fi.sortArrayValues(ev.oldIndex, ev.newIndex);
							onFieldChange();
						});
				}

				// "Add" button
				if( fi.def.arrayMaxLength==null || fi.getArrayLength()<fi.def.arrayMaxLength ) {
					var jAdd = new J('<button class="add"/>');
					jAdd.text("Add "+fi.def.getShortDescription(false) );
					jAdd.appendTo(jArray);
					jAdd.click( function(_) {
						if( fi.def.type==F_Point ) {
							startPointsEditing(fi, fi.getArrayLength());
						}
						else {
							fi.addArrayValue();
							onFieldChange();
						}
						var jArray = jWrapper.find('[defuid=${fd.uid}] .array');
						switch fi.def.type {
							case F_Int, F_Float, F_String, F_Text, F_Path: jArray.find("a.usingDefault:last").click();
							case F_Bool:
							case F_Color:
							case F_Enum(enumDefUid):
								// see: https://stackoverflow.com/a/10453874
								// var select = jArray.find("select:last").get(0);
								// var ev : js.html.MouseEvent = cast js.Browser.document.createEvent("MouseEvents");
								// ev.initMouseEvent("mousedown", true, true, js.Browser.window, 0, 5, 5, 5, 5, false, false, false, false, 0, null);
								// var ok = select.dispatchEvent(ev);

							case F_Point:
						}
					});
				}
			}
		}

		JsTools.parseComponents(jWrapper);
	}
}