package ui.modal.panel;

class EditEnums extends ui.modal.Panel {
	var curEnum : Null<led.def.EnumDef>;

	public function new() {
		super();

		loadTemplate( "editEnums", "editEnums" );
		linkToButton("button.editEnums");

		// Add enum
		jContent.find("button.createEnum").click( function(_) {
			var ed = project.defs.createEnumDef();
			editor.ge.emit(EnumDefAdded);
			selectEnum(ed);
			jContent.find("ul.enumForm input:first").focus();
		});

		// Delete enum
		jContent.find("button.deleteEnum").click( function(ev) {
			if( curEnum==null ) {
				N.error(L.t._("No enum selected."));
				return;
			}

			new ui.modal.dialog.Confirm(ev.getThis(), function() {
				new ui.LastChance( L.t._("Enum ::name:: deleted", { name: curEnum.identifier}), project );
				project.defs.removeEnumDef(curEnum);
				editor.ge.emit(EnumDefRemoved);
				selectEnum( project.defs.enums[0] );
			});
		});

		// Import HX
		jContent.find("button.importHx").click( function(_) {
			JsTools.loadDialog(["hx"], editor.getProjectDir(), function(path:String) {
				var file = JsTools.readFileString(path);
				var reg = ~/^[ \t]*enum[ \t]+([a-z0-9_]+)[ \t]*{/gim;
				if( !reg.match(file) ) {
					N.error("Couldn't find any simple Enum in this source file.");
					return;
				}

				var limit = 10;
				while( limit-->0 && reg.match(file) ) {
					var brackets = 1;
					var pos = reg.matchedPos().pos + reg.matchedPos().len;
					var start = pos;
					while( pos < file.length && brackets>=1 ) {
						if( file.charAt(pos)=="{" )
							brackets++;
						else if( file.charAt(pos)=="}" )
							brackets--;
						pos++;
					}
					trace("-- FOUND "+reg.matched(1)+" ---");
					trace(file.substring(start,pos));

					file = reg.matchedRight();
				}
			});
		});

		// Default enum selection
		if( project.defs.enums.length>0 )
			selectEnum( project.defs.enums[0] );

		updateEnumList();
		updateEnumForm();
	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch(ge) {
			case ProjectSelected:
				close();

			case _:
		}

		updateEnumList();
		updateEnumForm();
	}

	function selectEnum(ed:led.def.EnumDef) {
		curEnum = ed;
		updateEnumList();
		updateEnumForm();
	}

	function updateEnumList() {
		var jList = jContent.find(".enumList ul");
		jList.empty();

		for(ed in project.defs.enums) {
			var e = new J("<li/>");
			e.appendTo(jList);
			if( ed==curEnum )
				e.addClass("active");
			e.append('<span class="name">'+ed.identifier+'</span>');
			e.click( function(_) {
				selectEnum(ed);
			});
		}

		// Make list sortable
		JsTools.makeSortable(".window .enumList ul", function(from, to) {
			var moved = project.defs.sortEnumDef(from,to);
			selectEnum(moved);
			editor.ge.emit(EnumDefSorted);
		});
	}



	function updateEnumForm() {
		var jForm = jContent.find("ul.enumForm");
		jForm.find("*").off();

		if( curEnum==null ) {
			jForm.hide();
			return;
		}
		jForm.show();

		var i = Input.linkToHtmlInput( curEnum.identifier, jForm.find("[name=id]") );
		i.validityCheck = function(v) {
			return project.defs.isEnumIdentifierUnique(v);
		}
		i.linkEvent(EnumDefChanged);

		// Tilesets
		var jSelect = jForm.find("select#icons");
		jSelect.empty();
		if( curEnum.iconTilesetUid==null )
			jSelect.addClass("gray");
		else
			jSelect.removeClass("gray");

		var opt = new J('<option value="-1">-- Select a tileset --</option>');
		opt.appendTo(jSelect);

		for(td in project.defs.tilesets) {
			var opt = new J('<option value="${td.uid}"/>');
			opt.appendTo(jSelect);
			opt.text( td.identifier );
		}

		jSelect.val( curEnum.iconTilesetUid==null ? "-1" : Std.string(curEnum.iconTilesetUid) );
		jSelect.change( function(ev) {
			var tid = Std.parseInt( jSelect.val() );
			if( tid==curEnum.iconTilesetUid )
				return;

			// Check if this change will break something
			if( curEnum.iconTilesetUid!=null )
				for( v in curEnum.values )
					if( v.tileId!=null ) {
						new LastChance(Lang.t._("Enum icons changed"), project);
						break;
					}

			// Update tileset link
			if( tid<0 )
				curEnum.iconTilesetUid = null;
			else
				curEnum.iconTilesetUid = tid;
			curEnum.clearAllTileIds();
			editor.ge.emit(EnumDefChanged);
		});


		// Values
		var jList = jForm.find("ul.enumValues");
		jList.empty();
		var xml = jForm.find("xml").children();
		for(eValue in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append( xml.clone() );

			// Identifier
			var i = new form.input.StringInput(li.find(".name"),
				function() return eValue.id,
				function(newV) {
					if( curEnum.renameValue(eValue.id, newV) ) {
						project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
							if( fi.getEnumValue()==eValue.id )
								fi.parseValue(newV);
						});
					}
					else
						N.invalidIdentifier(eValue.id);
				}
			);
			i.linkEvent(EnumDefChanged);

			// Tile preview
			var previewCanvas = li.find(".tile");
			if( curEnum.iconTilesetUid!=null ) {
				var td = project.defs.getTilesetDef(curEnum.iconTilesetUid);
				previewCanvas.addClass("active");

				// Pick a tile
				previewCanvas.click( function(_) {
					var m = new Modal();
					m.jModalAndMask.addClass("singleTilePicker");
					var tp = new ui.TilesetPicker(m.jContent, td);
					tp.singleSelectedTileId = eValue.tileId;
					tp.onSingleTileSelect = function(tileId) {
						N.debug(tileId);
						m.close();
						eValue.tileId = tileId;
						editor.ge.emit(EnumDefChanged);
					}
				});

				// Render preview
				if( eValue.tileId!=null ) {
					td.drawTileToCanvas( previewCanvas, eValue.tileId, 0, 0 );
					previewCanvas.attr("width", td.tileGridSize);
					previewCanvas.attr("height", td.tileGridSize);
					// previewCanvas.css("zoom", 32/td.tileGridSize);
				}
			}

			// Remove value button
			li.find(".delete").click( function(ev) {
				new ui.modal.dialog.Confirm(ev.getThis(), Lang.t._("Warning! This operation will affect any Entity using this Enum in ALL LEVELS!"), function() {
					new LastChance(L.t._("Enum value ::name:: deleted", { name:curEnum.identifier+"."+eValue.id }), project);

					project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
						if( fi.getEnumValue()==eValue.id )
							fi.parseValue(null);
					});
					project.defs.removeEnumDefValue(curEnum, eValue.id);
					editor.ge.emit(EnumDefValueRemoved);
				});
			});
		}

		jForm.find(".createEnumValue").click( function(_) {
			var uid = 0;
			while( !curEnum.addValue(curEnum.identifier+uid) )
				uid++;
			editor.ge.emit(EnumDefChanged);
			jContent.find("ul.enumValues li:last input[type=text]").select();
		});

		// Make fields list sortable
		JsTools.makeSortable(".window ul.enumValues", function(from, to) {
			var v = curEnum.values.splice(from,1)[0];
			curEnum.values.insert(to, v);
			editor.ge.emit(EnumDefChanged);
		});
	}
}
