package ui;

class EntityInstanceEditor extends ui.InstanceEditor<data.inst.EntityInstance> {

	private function new(ei:data.inst.EntityInstance) {
		super(ei);
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);
		switch ge {
			case ProjectSettingsChanged, EntityDefChanged, EntityFieldDefChanged(_), EntityFieldSorted:
				if( inst==null || inst.def==null )
					destroy();
				else
					updateForm();

			case EnumDefRemoved, EnumDefChanged, EnumDefSorted, EnumDefValueRemoved:
				updateForm();

			case EntityInstanceRemoved(ei):
				if( ei==this.inst )
					close();

			case EntityInstanceChanged(ei):
				if( ei==this.inst )
					updateForm();

			case LayerInstanceRestoredFromHistory(_), LevelRestoredFromHistory(_):
				close(); // TODO do softer refresh


			case ViewportChanged :
				updateForm();

			case _:
		}
	}

	override function renderLink() {
		super.renderLink();
		drawLink( inst.def.color, inst.x, inst.y );
	}

	public static function openFor(ei:data.inst.EntityInstance) : EntityInstanceEditor {
		if( InstanceEditor.existsFor(ei) )
			return cast InstanceEditor.CURRENT;
		else
			return new EntityInstanceEditor(ei);
	}

	override function onFieldChange(keepCurrentSpecialTool=false) {
		super.onFieldChange(keepCurrentSpecialTool);

		var editor = Editor.ME;
		editor.curLevelHistory.saveLayerState( editor.curLayerInstance );
		editor.curLevelHistory.setLastStateBounds( inst.left, inst.top, inst.def.width, inst.def.height );
		editor.ge.emit( EntityInstanceFieldChanged(inst) );
	}


	override function getInstanceCx():Int {
		return inst.getCx( Editor.ME.curLayerDef );
	}

	override function getInstanceCy():Int {
		return inst.getCy( Editor.ME.curLayerDef );
	}

	override function getInstanceColor():UInt {
		return inst.def.color;
	}


	override function renderForm() {
		super.renderForm();

		if( inst==null || inst.def==null ) {
			close();
			return;
		}

		var jHeader = new J('<header/>');
		jHeader.appendTo(jPanel);
		jHeader.append('<div>${inst.def.identifier}</div>');
		var jEdit = new J('<a class="edit">Edit</a>');
		jEdit.click( function(ev) {
			ev.preventDefault();
			new ui.modal.panel.EditEntityDefs(inst.def);
		});
		jHeader.append(jEdit);

		if( inst.def.fieldDefs.length==0 )
			jPanel.append('<div class="empty">This entity has no custom field.</div>');
		else {
			var form = new J('<ul class="form"/>');
			form.appendTo(jPanel);
			for(fd in inst.def.fieldDefs) {
				var fi = inst.getFieldInstance(fd);
				var li = new J("<li/>");
				li.attr("defUid", fd.uid);
				li.appendTo(form);

				// Name
				if( !fd.isArray )
					li.append('<label>${fi.def.identifier}</label>');
				else
					li.append('<label>${fi.def.identifier} (${fi.getArrayLength()})</label>');

				if( !fd.isArray ) {
					// Single value
					createInputFor(fi, 0, li);
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

							createInputFor(fi, i, li);

							// "Remove" button
							var jRemove = new J('<button class="remove dark">x</button>');
							jRemove.appendTo(li);
							var idx = i;
							jRemove.click( function(_) {
								fi.removeArrayValue(idx);
								onFieldChange();
								updateForm();
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
								updateForm();
							}
							var jArray = jPanel.find('[defuid=${fd.uid}] .array');
							switch fi.def.type {
								case F_Int, F_Float, F_String, F_Text: jArray.find("a.usingDefault:last").click();
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
		}
	}
}