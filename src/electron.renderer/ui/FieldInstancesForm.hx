package ui;

import data.def.FieldDef;
import data.inst.FieldInstance;

enum FormRelatedInstance {
	Entity(ei:data.inst.EntityInstance);
	Level(l:data.Level);
}

class FieldInstancesForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var relatedInstance : FormRelatedInstance;
	public var jWrapper: js.jquery.JQuery;
	var fieldDefs : Array<data.def.FieldDef>;
	var fieldInstGetter : (fd:FieldDef)->FieldInstance;


	public function new() {
		jWrapper = new J('<dl class="form fieldInstanceEditor"/>');
	}

	public function use(elementInstance: FormRelatedInstance, fieldDefs: Array<FieldDef>, fieldInstGetter: (fd:FieldDef)->FieldInstance ) {
		this.relatedInstance = elementInstance;
		this.fieldInstGetter = fieldInstGetter;
		this.fieldDefs = fieldDefs;
		renderForm();
	}


	public function dispose() {
		jWrapper.remove();
		jWrapper = null;
		fieldDefs = null;
		fieldInstGetter = null;
	}

	public inline function isDestroyed() return jWrapper==null || jWrapper.parents("body").length==0;


	function hideInputIfDefault(arrayIdx:Int, jElements:js.jquery.JQuery, fi:data.inst.FieldInstance, isRequired=false) {
		// NOTE: jElements can be a single DOM element, or multiple ones (eg. an Int value with prefix/suffix)

		jElements.off(".def").removeClass("usingDefault");

		if( fi.isUsingDefault(arrayIdx) ) {
			if( jElements.is("button") ) {
				// Button input
				if( fi.def.type!=F_Point || fi.def.canBeNull )
					jElements.addClass("gray usingDefault");
			}
			else if( jElements.is("[type=color]") ) {
				// Color input
				jElements.addClass("usingDefault");
				jElements.text("default");
			}
			else if( jElements.is(".colorWrapper") ) {
				// Wrapped color input
				jElements.addClass("usingDefault");
			}
			else if( !jElements.is("select") ) {
				// General INPUT
				var jRep = new J('<a class="usingDefault" href="#"/>');

				if( jElements.is("[type=checkbox]") ) {
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
					if( jElements.is("[type=checkbox]") ) {
						jElements.prop("checked", !fi.getBool(arrayIdx));
						jElements.change();
					}
					if( jElements.is("[readonly],[disabled]") )
						jElements.click();
					else
						jElements.show().focus();
				});
				jRep.insertBefore( jElements.first() );
				jElements.hide();

				if( isRequired )
					markError(jRep);

				jElements.on("blur.def", function(ev) {
					jRep.remove();
					hideInputIfDefault(arrayIdx, jElements, fi, isRequired);
				});
			}
			else if( jElements.is("select") && ( fi.getEnumValue(arrayIdx)!=null || fi.def.canBeNull ) ) {
				// SELECT case
				jElements.addClass("usingDefault");
				jElements.on("click.def", function(ev) {
					jElements.removeClass("usingDefault");
				});
				jElements.on("blur.def", function(ev) {
					hideInputIfDefault(arrayIdx, jElements, fi, isRequired);
				});
			}
		}
		else if( fi.def.type!=F_Path && ( fi.def.getDefault()!=null || fi.def.canBeNull ) ) {
			// Require a "Reset to default" link
			var span = jElements.wrapAll('<span class="inputWithDefaultOption"/>').parent();
			span.find("input").wrap('<span class="value"/>');
			var defLink = new J('<button class="transparent reset"> <span class="icon reset"></span> </button>');
			defLink.appendTo(span);
			defLink.on("click.def", function(ev) {
				fi.parseValue(arrayIdx, null);
				onFieldChange(fi);
				ev.preventDefault();
			});
		}
	}

	function markError(e:js.jquery.JQuery, ?customClass="required") {
		final a = "error";
		e.attr(a,a);
		e.closest("dd").attr(a,a).prev("dt").attr(a,a);
		if( customClass!=null )
			e.addClass(customClass);
	}

	function createFieldInput(domId:String, fi:data.inst.FieldInstance, arrayIdx:Int, jTarget:js.jquery.JQuery) {
		jTarget.addClass( fi.def.type.getName() );

		// Prefix
		// if( ( fi.def.type==F_Int || fi.def.type==F_Float ) && fi.def.editorTextPrefix!=null && !fi.isUsingDefault(arrayIdx) )
		// 	jTarget.append('<span class="prefix">${fi.def.editorTextPrefix}</span>');

		switch fi.def.type {
			case F_Int:
				// Prefix
				if( fi.def.editorTextPrefix!=null && !fi.isUsingDefault(arrayIdx) )
					jTarget.append('<span class="prefix">${fi.def.editorTextPrefix}</span>');

				var jInput = new J("<input/>");
				jInput.attr("id",domId);
				jInput.appendTo(jTarget);
				jInput.attr("type","text");

				var i = new form.input.IntInput(
					jInput,
					()->fi.isUsingDefault(arrayIdx) ? null : fi.getInt(arrayIdx),
					(v)->{
						fi.parseValue(arrayIdx, Std.string(v));
						onFieldChange(fi);
					}
				);
				i.allowNull = true;
				i.setBounds(fi.def.min, fi.def.max);
				var speed = fi.def.min!=null && fi.def.max!=null ? (fi.def.max-fi.def.min) / 50 : 2;
				i.enableSlider(speed);
				i.setPlaceholder( fi.def.getDefault()==null ? "(null)" : fi.def.getDefault() );

				// Suffix
				if( fi.def.editorTextSuffix!=null && !fi.isUsingDefault(arrayIdx) )
					jTarget.append('<span class="suffix">${fi.def.editorTextSuffix}</span>');

				hideInputIfDefault(arrayIdx, jTarget.children(), fi);

			case F_Float:
				// Prefix
				if( fi.def.editorTextPrefix!=null && !fi.isUsingDefault(arrayIdx) )
					jTarget.append('<span class="prefix">${fi.def.editorTextPrefix}</span>');

				var jInput = new J("<input/>");
				jInput.attr("id",domId);
				jInput.appendTo(jTarget);
				jInput.attr("type","text");

				var i = new form.input.FloatInput(
					jInput,
					()->fi.isUsingDefault(arrayIdx) ? null : fi.getFloat(arrayIdx),
					(v)->{
						fi.parseValue(arrayIdx, Std.string(v));
						onFieldChange(fi);
					}
				);
				i.allowNull = true;
				i.setBounds(fi.def.min, fi.def.max);
				var speed = fi.def.min!=null && fi.def.max!=null ? (fi.def.max-fi.def.min) / 3 : 2;
				i.enableSlider(speed);
				i.setPlaceholder( fi.def.getDefault()==null ? "(null)" : fi.def.getDefault() );

				// Suffix
				if( fi.def.editorTextSuffix!=null && !fi.isUsingDefault(arrayIdx) )
					jTarget.append('<span class="suffix">${fi.def.editorTextSuffix}</span>');

				hideInputIfDefault(arrayIdx, jTarget.children(), fi);

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
				input.attr("id",domId);
				input.appendTo(jWrapper);
				input.attr("type","color");
				input.attr("colorTag", "e_"+fi.def.identifier);
				input.addClass("advanced");
				input.val(cHex);
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange(fi);
				});

				hideInputIfDefault(arrayIdx, jWrapper, fi);

			case F_String:
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
				input.attr("id",domId);
				input.attr("placeholder", def==null ? "(null)" : def=="" ? "(empty string)" : def);
				if( !fi.isUsingDefault(arrayIdx) )
					input.val( fi.getString(arrayIdx) );
				input.change( function(ev) {
					fi.parseValue( arrayIdx, input.val() );
					onFieldChange(fi);
				});
				if( fi.def.type==F_Text )
					input.keyup();
				hideInputIfDefault(arrayIdx, input, fi);

			case F_Text:
				var jText = new J('<div class="multiLines"/>');
				jText.appendTo(jTarget);
				if( fi.isUsingDefault(arrayIdx) ) {
					var def = fi.def.getStringDefault();
					jText.text(def==null ? "(null)" : def=="" ? "(empty string)" : def);
					jText.addClass("usingDefault");
				}
				else {
					var str = fi.getString(arrayIdx);
					if( str.length>256 )
						str = str.substr(0,256)+"[...]";
					jText.text(str);
				}
				jText.click( _->{
					new ui.modal.dialog.TextEditor(
						fi.getString(arrayIdx),
						getInstanceName()+"."+fi.def.identifier,
						fi.def.textLanguageMode,
						(v)->{
							fi.parseValue(arrayIdx, v);
							onFieldChange(fi);
						},
						()->{
							onFieldChange(fi);
						}
					);
				});
				hideInputIfDefault(arrayIdx, jText, fi);

			case F_Point:
				if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull || !fi.def.isArray ) {
					// Button mode
					var jPick = new J('<button/>');
					jPick.attr("id",domId);
					if( !fi.valueIsNull(arrayIdx) )
						jPick.addClass("gray");
					jPick.appendTo(jTarget);
					jPick.addClass("point");
					if( fi.valueIsNull(arrayIdx) && !fi.def.canBeNull ) {
						markError(jPick);
						jPick.text( "Point required!" );
					}
					else {
						jPick.addClass("dark");
						jPick.text( fi.valueIsNull(arrayIdx) ? "<No point>" : fi.getPointStr(arrayIdx) );
					}
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
						var jRem = new J('<button class="transparent removePoint">x</button>');
						jRem.appendTo(jTarget);
						jRem.click( (_)->{
							fi.parseValue(arrayIdx,null);
							onFieldChange(fi);
						});
					}
				}
				else {
					// Text mode
					var jPoint = new J('<span class="point"/>');
					jPoint.appendTo(jTarget);
					jPoint.text( fi.getPointStr(arrayIdx) );
				}


			case F_Enum(defUid):
				var ed = Editor.ME.project.defs.getEnumDef(defUid);
				var jSelect = new J('<select class="advanced" id="fieldInstance_${defUid}"/>');
				jSelect.appendTo(jTarget);
				jSelect.attr("tdUid", ed.iconTilesetUid);

				// Null value
				if( fi.def.canBeNull || fi.getEnumValue(arrayIdx)==null ) {
					var jOpt = new J('<option/>');
					jOpt.appendTo(jSelect);
					jOpt.attr("value","");
					if( fi.def.canBeNull )
						jOpt.text("-- null --");
					else {
						// SELECT shouldn't be null
						markError(jSelect);
						jOpt.text("[ Value required ]");
						jSelect.click( function(ev) {
							jSelect.removeAttr("error").removeClass("required");
							jSelect.blur( function(ev) renderForm() );
						});
					}
					if( fi.getEnumValue(arrayIdx)==null )
						jOpt.attr("selected","selected");
				}

				if( fi.def.getEnumDefault()!=null ) {
					var v = fi.def.getEnumDefinition().getValue(fi.def.getEnumDefault());
					var jOpt = new J('<option/>');
					jOpt.appendTo(jSelect);
					jOpt.attr("value","_default");
					jOpt.addClass("default");
					jOpt.text(v.id+" (default)");
					if( v.tileRect!=null )
						jOpt.attr("tile", haxe.Json.stringify(v.tileRect));
					jOpt.css({
						color: C.intToHex( C.toWhite(v.color,0.7) ),
						backgroundColor: C.intToHex( C.toBlack(v.color,0.5) ),
					});
					if( fi.isUsingDefault(arrayIdx) )
						jOpt.attr("selected","selected");
				}

				for(v in ed.values) {
					var jOpt = new J('<option/>');
					jOpt.appendTo(jSelect);
					jOpt.attr("value",v.id);
					jOpt.attr("color", C.intToHex(v.color));
					if( v.tileRect!=null )
						jOpt.attr("tile", haxe.Json.stringify(v.tileRect));
					jOpt.text(v.id);
					jOpt.css({
						color: C.intToHex( C.toWhite(v.color,0.7) ),
						backgroundColor: C.intToHex( C.toBlack(v.color,0.5) ),
					});
					if( fi.getEnumValue(arrayIdx)==v.id && !fi.isUsingDefault(arrayIdx) ) {
						jSelect.css({
							color: C.intToHex( C.toWhite(v.color,0.7) ),
							backgroundColor: C.intToHex( C.toBlack(v.color,0.5) ),
						});
						jOpt.attr("selected","selected");
					}
				}

				jSelect.change( function(ev) {
					var v = jSelect.val()=="" ? null : jSelect.val();
					if( v=="_default" )
						fi.parseValue(arrayIdx, null);
					else
						fi.parseValue(arrayIdx, v);
					onFieldChange(fi);
				});
				hideInputIfDefault(arrayIdx, jSelect, fi);

			case F_Bool:
				var jCheck = new J("<input/>");
				jCheck.attr("type","checkbox");
				jCheck.attr("id",domId);
				jCheck.appendTo(jTarget);

				var b = new form.input.BoolInput(
					jCheck,
					()->fi.getBool(arrayIdx),
					(v)->{
						fi.parseValue( arrayIdx, Std.string(v) );
						onFieldChange(fi);
					}
				);

				hideInputIfDefault(arrayIdx, jCheck, fi);

			case F_Path:
				var isRequired = fi.valueIsNull(arrayIdx) && !fi.def.canBeNull;

				// Text input
				var input = new J('<input class="fileInput" type="text"/>');
				input.appendTo(jTarget);
				input.attr("id",domId);
				input.attr("placeholder", "(null)");
				input.prop("readonly",true);

				if( isRequired )
					markError(input);

				if( !fi.isUsingDefault(arrayIdx) ) {
					var fp = dn.FilePath.fromFile( fi.getFilePath(arrayIdx) );
					input.val( fp.fileWithExt );
					input.attr("title", fp.full);
				}

				input.focus( ev->{
					input.blur();
				});
				input.click( ev->{
					var uiDirId = "field_"+fi.def.identifier+"_"+fi.def.uid;
					var defaultDir = App.ME.settings.getUiDir(project, uiDirId, project.getProjectDir());
					dn.js.ElectronDialogs.openFile(fi.def.acceptFileTypes, defaultDir, function( absPath ) {
						var fp = dn.FilePath.fromFile(absPath);
						fp.useSlashes();
						var relPath = project.makeRelativeFilePath(fp.full);
						input.val(relPath);
						fi.parseValue( arrayIdx, relPath );
						onFieldChange(fi);
						N.debug(fp.directory);
						App.ME.settings.storeUiDir(project, uiDirId, fp.directory);
					});
					input.blur();
				});

				// Edit
				if( !fi.isUsingDefault(arrayIdx) ) {
					var jEdit = new J('<button class="edit gray" title="Edit file content"> <span class="icon edit"></span> </button>');
					jEdit.appendTo(jTarget);
					jEdit.click( (_)->{
						if( !fi.valueIsNull(arrayIdx) ) {
							ui.modal.dialog.TextEditor.editExternalFile( project.makeAbsoluteFilePath(fi.getFilePath(arrayIdx)) );
						}
					});
				}

				// Locate
				if( !fi.isUsingDefault(arrayIdx) ) {
					var jLocate = new J('<button class="locate gray" title="Locate this file"> <span class="icon locate"/> </button>');
					jLocate.appendTo(jTarget);
					jLocate.click( (_)->{
						if( !fi.valueIsNull(arrayIdx) ) {
							var path = project.makeAbsoluteFilePath( fi.getFilePath(arrayIdx) );
							JsTools.locateFile(path, true);
						}
					});
				}

				// Clear
				if( !fi.isUsingDefault(arrayIdx) ) {
					var jClear = new J('<button class="red"> <span class="icon clear"/> </button>');
					jClear.appendTo(jTarget);
					jClear.click( ev->{
						fi.parseValue(arrayIdx,null);
						onFieldChange(fi);
					});
				}

				// Error
				if( !fi.valueIsNull(arrayIdx) && !NT.fileExists( project.makeAbsoluteFilePath(fi.getFilePath(arrayIdx)) ) )
					input.addClass("fileNotFound");

				hideInputIfDefault(arrayIdx, input, fi, isRequired);

			case F_EntityRef:
				function _pickRef() {
					var sourceEi = getEntityInstance();
					var vp = new ui.vp.EntityRefPicker(sourceEi, fi.def);
					vp.onPickValue = (targetEi)->{
						tool.lt.EntityTool.cancelRefChaining();
						fi.setEntityRefTo(arrayIdx, sourceEi, targetEi);

						// Save history properly (only if both entities are in the same level)
						if( sourceEi._li.levelId==targetEi._li.levelId ) {
							editor.curLevelTimeline.markEntityChange(sourceEi);
							editor.curLevelTimeline.saveLayerState(sourceEi._li);
						}

						LOG.userAction('Picked ref $sourceEi => $targetEi in $fi');
						editor.ge.emit( EntityInstanceChanged(sourceEi) );
						editor.ge.emit( EntityInstanceChanged(targetEi) ); // also trigger event for the target ei
					}
				}

				if( fi.valueIsNull(arrayIdx) ) {
					var jPick = new J('<button class="red missingRef">Missing reference</button>');
					jPick.appendTo(jTarget);
					jPick.click( _->_pickRef() );
				}
				else {
					// Text input
					var tei = fi.getEntityRefInstance(arrayIdx);
					var jRef = JsTools.createEntityRef( tei, jTarget );
					jRef.attr("id",domId);

					// Follow ref
					jRef.click( (_)->{
						if( fi.valueIsNull(arrayIdx) )
							return;

						if( tei==null ) {
							N.error("Invalid reference");
							return;
						}

						editor.followEntityRef(tei);
					});

					jRef.mouseenter( _->{
						// Mouse over a ref
						if( fi.valueIsNull(arrayIdx) || ui.ValuePicker.exists() )
							return;

						if( tei==null )
							return;

						if( tei._li.level==editor.curLevel ) {
							editor.levelRender.clearTemp();
							editor.levelRender.temp.lineStyle(2, 0xff00ff);
							editor.levelRender.temp.drawCircle(tei.centerX, tei.centerY, M.fmax(tei.width,tei.height)*0.5 + 8);
							var b = editor.levelRender.bleepEntity(tei,0xff00ff);
							b.remainCount = 2;
						}
					});
					jRef.mouseleave( _->{
						if( !ui.ValuePicker.exists() )
							editor.levelRender.clearTemp();
					});


					if( fi.hasAnyErrorInValues(getEntityInstance()) )
						markError(jRef);

					if( !fi.isUsingDefault(arrayIdx) ) {
						// jInput.val( fi.getEntityRefForDisplay(arrayIdx, editor.curLevel) );
						// jInput.attr("title", fi.getEntityRefIid(arrayIdx));
					}

					// Pick ref
					var jPick = new J('<button class="small pickRef"> <span class="icon edit"/> </button>');
					jPick.appendTo(jTarget);
					jPick.click( _->_pickRef() );
				}

				// Clear ref
				if( !fi.valueIsNull(arrayIdx) && fi.def.canBeNull ) {
					var jRemove = new J('<button class="small red removeRef"> <span class="icon clear"/> </button>');
					jRemove.appendTo(jTarget);
					jRemove.click(_->{
						var oldTargetEi = fi.getEntityRefInstance(arrayIdx);
						project.unregisterReverseIidRef(getEntityInstance(), oldTargetEi);
						fi.parseValue(arrayIdx, null);
						if( oldTargetEi!=null )
							oldTargetEi.tidyLostSymmetricalEntityRefs(fi.def);
						ValuePicker.cancelCurrent();
						onFieldChange(fi);
					});
				}

			case F_Tile:
				var td = project.defs.getTilesetDef(fi.def.tilesetUid);
				if( td==null || !td.isAtlasLoaded() ) {
					// Tileset error
					jTarget.append('<div class="warning">Invalid tileset in field definition.</div>');
				}
				else {
					// Picker
					var jPicker = JsTools.createTileRectPicker(
						fi.def.tilesetUid,
						fi.valueIsNull(arrayIdx) ? fi.def.getTileRectDefaultObj() : fi.getTileRectObj(arrayIdx),
						(r)->{
							if( r==null )
								return;
							fi.parseValue(arrayIdx, '${r.x},${r.y},${r.w},${r.h}');
							onFieldChange(fi);
						}
					);
					jPicker.appendTo(jTarget);

					// Clear button
					if( fi.def.canBeNull && !fi.isUsingDefault(arrayIdx) ) {
						var jClear = new J('<button class="red clearTile"> <span class="icon clear"/> </button>');
						jClear.appendTo(jTarget);
						jClear.click(_->{
							fi.parseValue(arrayIdx,null);
							onFieldChange(fi);
						});
					}
				}
		}

		// // Suffix
		// if( ( fi.def.type==F_Int || fi.def.type==F_Float ) && fi.def.editorTextSuffix!=null && !fi.isUsingDefault(arrayIdx) )
		// 	jTarget.append('<span class="suffix">${fi.def.editorTextSuffix}</span>');
	}


	function getEntityInstance() : Null<data.inst.EntityInstance> {
		return switch relatedInstance {
			case Entity(ei): ei;
			case Level(l): null;
		}
	}

	function getInstanceName() {
		return switch relatedInstance {
			case Entity(ei): ei.def.identifier;
			case Level(l): l.identifier;
		}
	}

	function getInstanceCx() {
		return switch relatedInstance {
			case Entity(ei): ei.getCx( editor.curLayerDef );
			case Level(l): 0; // N/A
		}
	}

	function getInstanceCy() {
		return switch relatedInstance {
			case Entity(ei): ei.getCy( editor.curLayerDef );
			case Level(l): 0; // N/A
		}
	}

	function getInstanceColor() {
		return switch relatedInstance {
			case Entity(ei): ei.getSmartColor(true);
			case Level(l): l.getBgColor();
		}
	}

	function startPointsEditing(fi:data.inst.FieldInstance, editIdx:Int) {
		var t = new tool.PickPoint();

		t.pickOrigin = { cx:getInstanceCx(), cy:getInstanceCy(), color:getInstanceColor() }
		t.canPick = (m:Coords)->{
			if( !fi.def.isArray )
				return true;
			for(i in 0...fi.getArrayLength())
				if( fi.getPointGrid(i).cx==m.cx && fi.getPointGrid(i).cy==m.cy )
					return false;
			return true;
		}

		// Connect to last point of existing path
		if( fi.def.isArray )
			switch fi.def.editorDisplayMode {
				case Hidden, ValueOnly, NameAndValue, LevelTile, EntityTile, RadiusPx, RadiusGrid, ArrayCountNoLabel, ArrayCountWithLabel:
				case Points, PointStar:
				case RefLinkBetweenCenters:
				case RefLinkBetweenPivots:
				case PointPath, PointPathLoop:
					var pt = fi.getPointGrid( editIdx-1 );
					if( pt!=null )
						t.pickOrigin = { cx:pt.cx, cy:pt.cy, color:getInstanceColor() }
			}

		// Picking of a point
		t.onPick = function(m) {
			editor.cursor.set(None);

			if( fi.def.isArray && editIdx>=fi.getArrayLength()-1 ) {
				// Append points in an array
				fi.parseValue(editIdx, m.cx+Const.POINT_SEPARATOR+m.cy);
				editIdx = fi.getArrayLength(); // continue after

				// Connect to previous point in path mode
				switch fi.def.editorDisplayMode {
					case Hidden, ValueOnly, NameAndValue, LevelTile, EntityTile, RadiusPx, RadiusGrid, ArrayCountNoLabel, ArrayCountWithLabel:
					case Points, PointStar:
					case RefLinkBetweenPivots:
					case RefLinkBetweenCenters:
					case PointPath, PointPathLoop:
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
			onFieldChange(fi, true);
		}

		// Tool stopped
		t.onDisposeCb = function() {
			if( !isDestroyed() )
				renderForm();
		}

		Editor.ME.setSpecialTool(t);
	}



	function activateLastArrayEntry(fd:FieldDef) {
		var jArray = jWrapper.find('[defuid=${fd.uid}] .array');
		var jEntry = jArray.find("ul.values >li:last");

		switch fd.type {
			case F_Int, F_Float, F_String, F_Text, F_Path:
				jEntry.find("a.usingDefault").click();

			case F_EntityRef:
				jEntry.find("button:first").click();

			case F_Tile:
				N.debug("TODO"); // TODO

			case F_Bool:
			case F_Color:
			case F_Enum(enumDefUid):
				// see: https://stackoverflow.com/a/10453874
				// var select = jArray.find("select:last").get(0);
				// var ev : js.html.MouseEvent = cast js.Browser.document.createEvent("MouseEvents");
				// ev.initMouseEvent("mousedown", true, true, js.Browser.window, 0, 5, 5, 5, 5, false, false, false, false, 0, null);
				// var ok = select.dispatchEvent(ev);

			case F_Point:
				// Not done here
		}

	}


	function onFieldChange(fi:FieldInstance, keepCurrentSpecialTool=false) {
		if( !keepCurrentSpecialTool )
			Editor.ME.clearSpecialTool();

		var jPrevFocus = jWrapper.find("input:focus");

		onBeforeRender();
		renderForm();
		switch relatedInstance {
			case Entity(ei): editor.ge.emit( EntityFieldInstanceChanged(ei,fi) );
			case Level(l): editor.ge.emit( LevelFieldInstanceChanged(l,fi) );
		}
		onChange();

		LOG.userAction('Changed field: $fi');

		// Re-focus input
		if( jPrevFocus.length>0 ) {
			if( jPrevFocus.attr("id")!=null )
				jWrapper.find("#"+jPrevFocus.attr("id")).focus();
			else if( jPrevFocus.attr("name")!=null )
				jWrapper.find("[name="+jPrevFocus.attr("id")+"]").focus();
		}
	}

	public dynamic function onBeforeRender() {}
	public dynamic function onChange() {}


	function renderForm() {
		ui.Tip.clear();
		jWrapper.empty();

		if( fieldDefs.length==0 )
			return;

		// Fields
		for(fd in fieldDefs) {
			var fi = fieldInstGetter(fd);
			var domId = "field_"+fd.identifier+"_"+fd.uid;

			var jDt = new J("<dt/>");
			jDt.appendTo(jWrapper);

			// Context menu
			var actions : Array<ui.modal.ContextMenu.ContextAction> = [
				{
					label: L.t._("Edit field definition"),
					cb: ()->{
						switch relatedInstance {
							case Entity(ei):
								var p = new ui.modal.panel.EditEntityDefs(ei.def);
								p.fieldsForm.selectField(fd);
							case Level(l):
								var p = new ui.modal.panel.EditLevelFieldDefs();
								p.selectField(fd);
						}
					},
				}
			];
			ui.modal.ContextMenu.attachTo(jDt, false, actions);

			var jDd = new J("<dd/>");
			jDd.attr("defUid", fd.uid);
			jDd.appendTo(jWrapper);

			// Identifier
			if( !fd.isArray )
				jDt.append('<label for="$domId">${fi.def.identifier}</label>');
			else {
				var jLabel = new J('<label for="$domId">${fi.def.identifier}</label>');
				if( fi.def.isArray ) {
					jLabel.append('&nbsp;${fi.getArrayLength()}');
					if( fi.getArrayMaxLength()>0 )
						jLabel.append('/${fi.getArrayMaxLength()}');
				}
				jDt.append(jLabel);
			}
			jDt.attr("title", jDt.find("label").text());
			jDt.attr("noTip", "noTip");

			// Field is not manually defined
			if( !fd.isArray && fi.isUsingDefault(0) || fd.isArray && fi.getArrayLength()==0 ) {
				jDt.addClass("isDefault");
				jDd.addClass("isDefault");
			}

			// Doc
			if( fi.def.doc!=null )
				jDt.append('<info>${fi.def.doc}</info>');


			if( !fd.isArray ) {
				// Single value
				createFieldInput(domId, fi, 0, jDd);
			}
			else {
				// Array
				var jArray = new J('<div class="array"/>');
				jArray.appendTo(jDd);
				if( fi.getArrayLength()==0 )
					jArray.addClass("empty");
				if( fd.arrayMinLength!=null && fi.getArrayLength()<fd.arrayMinLength
					|| fd.arrayMaxLength!=null && fi.getArrayLength()>fd.arrayMaxLength ) {
					var bounds : String =
						fd.arrayMinLength==fd.arrayMaxLength ? Std.string(fd.arrayMinLength)
						: fd.arrayMaxLength==null ? fd.arrayMinLength+"+"
						: fd.arrayMinLength+"-"+fd.arrayMaxLength;
					jArray.append('<div class="warning">Array should have $bounds value(s)</div>');
					markError(jArray);
				}

				var jArrayInputs = new J('<ul class="values"/>');
				jArrayInputs.appendTo(jArray);

				if( fi.def.type==F_Point && ( fi.def.editorDisplayMode==Points || fi.def.editorDisplayMode==PointPath || fi.def.editorDisplayMode==PointStar ) ) {
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

						// if( sortable ) {
							// jArrayInputs.addClass("customHandle");
							// li.append('<div class="sortHandle"/>');
						// }

						createFieldInput(domId, fi, i, li);

						// Remove array entry
						var jRemove = new J('<button class="remove transparent"> <span class="icon delete"/> </button>');
						jRemove.appendTo(li);
						var idx = i;
						jRemove.click( function(_) {
							var oldTargetEi = fi.getEntityRefInstance(idx);
							if( fi.def.type==F_EntityRef )
								project.unregisterReverseIidRef(getEntityInstance(), oldTargetEi);
							fi.removeArrayValue(idx);
							if( oldTargetEi!=null )
								oldTargetEi.tidyLostSymmetricalEntityRefs(fi.def);
							ValuePicker.cancelCurrent();
							onFieldChange(fi);
						});
					}
					if( sortable )
						JsTools.makeSortable(jArrayInputs, function(ev:sortablejs.Sortable.SortableDragEvent) {
							fi.sortArrayValues(ev.oldIndex, ev.newIndex);
							onFieldChange(fi);
						});
				}

				// "Add" button
				if( fi.def.arrayMaxLength==null || fi.getArrayLength()<fi.def.arrayMaxLength ) {
					var jAdd = new J('<button class="add dark"/>');
					jAdd.append('<span class="icon add"/>');
					jAdd.appendTo(jArray);
					jAdd.click( function(_) {
						if( fi.def.type==F_Point ) {
							startPointsEditing(fi, fi.getArrayLength());
						}
						else {
							fi.addArrayValue();
							ValuePicker.cancelCurrent();
							onFieldChange(fi);
							activateLastArrayEntry(fd);
						}
					});
				}
			}
		}

		JsTools.parseComponents(jWrapper);
	}
}