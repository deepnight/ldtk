package ui.modal.panel;

class EditEnums extends ui.modal.Panel {
	var curEnum : Null<data.def.EnumDef>;

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

			if( curEnum.isExternal() ) {
				// Extern enum removal
				new ui.modal.dialog.Confirm(
					ev.getThis(),
					L.t._("WARNING: removing this external enum will also remove ALL the external enums from the same source! Please note that this will also affect all Entities using any of these enums in ALL levels."),
					true,
					function() {
						var name = dn.FilePath.fromFile(curEnum.externalRelPath).fileWithExt;
						new ui.LastChance( L.t._("::file:: enums deleted", { file:name }), project );
						project.defs.removeExternalEnumSource(curEnum.externalRelPath);
						editor.ge.emit(EnumDefRemoved);
						selectEnum( project.defs.enums[0] );
					}
				);
			}
			else {
				// Local enum removal
				var isUsed = project.isEnumDefUsed(curEnum);
				new ui.modal.dialog.Confirm(
					ev.getThis(),
					isUsed
						? Lang.t._("WARNING! This ENUM is used in one or more entity fields. These fields will also be removed!")
						: Lang.t._("This enum is not used and can be safely removed."),
					isUsed,
					function() {
						new ui.LastChance( L.t._("Enum ::name:: deleted", { name: curEnum.identifier}), project );
						project.defs.removeEnumDef(curEnum);
						editor.ge.emit(EnumDefRemoved);
						selectEnum( project.defs.enums[0] );
					}
				);
			}

		});

		// Import HX
		jContent.find("button.importHx").click( function(_) {
			dn.electron.Dialogs.open([".hx"], editor.getProjectDir(), function(absPath:String) {
				absPath = StringTools.replace(absPath,"\\","/");
				if( dn.FilePath.extractExtension(absPath)!="hx" )
					N.error("The file must have the HX extension.");
				else
					importer.HxEnum.load( editor.makeRelativeFilePath(absPath), false );
			});
		});

		// Import CastleDB
		jContent.find("button.importCdb").click( function(_) {
			N.notImplemented();
		});

		// Import ExpDB
		jContent.find("button.importEdb").click( function(_) {
			N.notImplemented();
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
				if( curEnum==null || project.defs.getEnumDef(curEnum.identifier)==null )
					selectEnum(project.defs.enums[0]);
				else
					selectEnum( project.defs.getEnumDef(curEnum.identifier) );

			case _:
		}

		updateEnumList();
		updateEnumForm();
	}


	function selectEnum(ed:data.def.EnumDef) {
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

		var grouped = project.defs.getGroupedExternalEnums();
		for( group in grouped.keyValueIterator() ) {
			var fullPath = editor.makeAbsoluteFilePath(group.key);

			// Source name
			var e = new J("<li/>");
			e.addClass("title fixed");
			e.appendTo(jList);
			var name = dn.FilePath.fromFile(group.key).fileWithExt;
			e.html('<span>$name</span>');

			// Check file
			var fileExists = JsTools.fileExists(fullPath);
			if( !fileExists )
				e.append('<div class="error">File not found!</div>');
			else {
				var checksum = haxe.crypto.Md5.encode( JsTools.readFileString(fullPath) );
				for( ed in group.value )
					if( ed.externalFileChecksum!=checksum ) {
						e.append('<div class="error">File was modified, please use sync.</div>');
						break;
					}
			}

			var links = new J('<div class="links"/>');
			links.appendTo(e);

			// Explore button
			if( fileExists ) {
				var a = JsTools.makeExploreLink(fullPath);
				a.appendTo(links);
			}

			// Sync button
			var sync = new J('<a/>');
			sync.appendTo(links);
			sync.text("⟳");
			sync.click( function(ev) {
				importer.HxEnum.load(group.key, true);
			});
			Tip.attach(sync, Lang.t._("Reload and synchronize Enums"));

			// Values
			for(ed in group.value) {
				var e = new J("<li/>");
				e.addClass("fixed");
				e.appendTo(jList);
				if( ed==curEnum )
					e.addClass("active");
				e.append('<span class="name">'+ed.identifier+'</span>');
				e.click( function(_) {
					selectEnum(ed);
				});
			}
		}

		// Make list sortable
		JsTools.makeSortable(jList, function(ev) {
			var moved = project.defs.sortEnumDef(ev.oldIndex, ev.newIndex);
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
		jForm.find("input").not("xml input").removeAttr("readonly");

		if( curEnum.isExternal() )
			jForm.addClass("externalEnum");
		else
			jForm.removeClass("externalEnum");


		// Enum ID
		var i = Input.linkToHtmlInput( curEnum.identifier, jForm.find("[name=id]") );
		i.validityCheck = function(v) {
			return project.defs.isEnumIdentifierUnique(v);
		}
		i.linkEvent(EnumDefChanged);

		// Source path
		if( curEnum.isExternal() ) {
			jForm.find(".source .path, .source .exploreTo").remove();
			jForm.find(".source")
				.show()
				.append( JsTools.makePath(curEnum.externalRelPath) )
				.append( JsTools.makeExploreLink( editor.makeAbsoluteFilePath(curEnum.externalRelPath) ) );
		}
		else
			jForm.find(".source").hide();

		// Tilesets
		var jSelect = jForm.find("select#icons");
		if( !curEnum.isExternal() ) {
			jSelect.show();
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
		}


		// Values
		var jList = jForm.find("ul.enumValues");
		jList.empty();
		var xml = jForm.find("xml.enum").children();
		for(eValue in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append( xml.clone() );

			// Identifier
			var i = new form.input.StringInput(li.find(".name"),
				function() return eValue.id,
				function(newV) {
					var oldV = eValue.id;
					if( curEnum.renameValue(oldV, newV) ) {
						project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
							for(i in 0...fi.getArrayLength())
								if( fi.getEnumValue(i)==oldV )
									fi.parseValue(i, newV);
						});
					}
					else
						N.invalidIdentifier(newV);
				}
			);
			i.linkEvent(EnumDefChanged);

			if( curEnum.isExternal() )
				li.find(".sortHandle").hide();

			// Tile preview
			if( !curEnum.isExternal() ) {
				var jPicker = JsTools.createTilePicker(curEnum.iconTilesetUid, SingleTile, [eValue.tileId], function(tileIds) {
					eValue.tileId = tileIds[0];
					editor.ge.emit(EnumDefChanged);
				});
				jPicker.insertAfter( li.find(".sortHandle") );
			}

			// Remove value button
			if( !curEnum.isExternal() ) {
				li.find(".delete").click( function(ev) {
					var isUsed = project.isEnumValueUsed(curEnum, eValue.id );
					new ui.modal.dialog.Confirm(
						ev.getThis(),
						isUsed
							? Lang.t._("WARNING! This enum value is USED in one or more entity instances. These values will also be removed!")
							: Lang.t._("This enum value is not used and can be safely removed."),
						isUsed,
						function() {
							new LastChance(L.t._("Enum value ::name:: deleted", { name:curEnum.identifier+"."+eValue.id }), project);

							project.iterateAllFieldInstances(F_Enum(curEnum.uid), function(fi) {
								for(i in 0...fi.getArrayLength())
									if( fi.getEnumValue(i)==eValue.id )
										fi.parseValue(i, null);
							});
							project.defs.removeEnumDefValue(curEnum, eValue.id);
							editor.ge.emit(EnumDefValueRemoved);
						}
					);
				});
			}
		}

		jForm.find(".createEnumValue").click( function(_) {
			var uid = 0;
			while( !curEnum.addValue(curEnum.identifier+uid) )
				uid++;
			editor.ge.emit(EnumDefChanged);
			jContent.find("ul.enumValues li:last input[type=text]").select();
		});

		if( curEnum.isExternal() )
			jForm.find("input").not("xml input").attr("readonly", "readonly");

		// Make fields list sortable
		if( !curEnum.isExternal() )
			JsTools.makeSortable(jList, function(ev) {
				var v = curEnum.values.splice(ev.oldIndex,1)[0];
				curEnum.values.insert(ev.newIndex, v);
				editor.ge.emit(EnumDefChanged);
			});
	}
}
