package ui.modal.panel;

class EditEnumDefs extends ui.modal.Panel {
	var curEnum : Null<data.def.EnumDef>;
	var search : QuickSearch;

	public function new() {
		super();

		loadTemplate("editEnumDefs");
		linkToButton("button.editEnums");

		// Add enum
		jContent.find("button.createEnum").click( function(_) {
			var ed = project.defs.createEnumDef();
			editor.ge.emit(EnumDefAdded);
			selectEnum(ed);
			jContent.find("dl.enumForm input:first").focus();
		});

		// Import
		jContent.find("button.import").click( ev->{
			var ctx = new ContextMenu(ev);
			ctx.addAction({
				label: L.t._("Text file"),
				subText: L.t._('Expected format:\n - One enum per line\n - Each line: "MyEnumId : value1, value2, value3"'),
				cb: ()->{
					var path = settings.getUiDir(project, "ImportEnumText", project.getProjectDir());
					dn.js.ElectronDialogs.openFile([".txt"], path, function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						settings.storeUiDir(project, "ImportEnumText", dn.FilePath.extractDirectoryWithoutSlash(absPath, true));
						switch dn.FilePath.extractExtension(absPath,true) {
							case "txt":
								var i = new importer.enu.TextFileEnum();
								i.load( project.makeRelativeFilePath(absPath) );

							case _:
								N.error('The file must have the ".txt" extension.');
						}
					});
				},
			});

			ctx.addAction({
				label: L.t._("JSON"),
				subText: L.t._('Accepted formats:\n {\n  "MyEnum1": "a,b,c",\n  "MyEnum2": "a b c",\n  "MyEnum3": ["a","b","c"]\n }'),
				cb: ()->{
					var path = settings.getUiDir(project, "ImportEnumText", project.getProjectDir());
					dn.js.ElectronDialogs.openFile([".json"], path, function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						settings.storeUiDir(project, "ImportEnumText", dn.FilePath.extractDirectoryWithoutSlash(absPath, true));
						switch dn.FilePath.extractExtension(absPath,true) {
							case "json":
								var i = new importer.enu.JsonEnum();
								i.load( project.makeRelativeFilePath(absPath) );

							case _:
								N.error('The file must have the ".json" extension.');
						}
					});
				},
			});

			ctx.addAction({
				label:L.t._("Haxe source code"),
				cb: ()->{
					var path = settings.getUiDir(project, "ImportEnumHaxe", project.getProjectDir());
					dn.js.ElectronDialogs.openFile([".hx"], path, function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						settings.storeUiDir(project, "ImportEnumHaxe", dn.FilePath.extractDirectoryWithoutSlash(absPath, true));
						if( dn.FilePath.extractExtension(absPath,true) != "hx" )
							N.error("The file must have the HX extension.");
						else {
							var i = new importer.enu.HxEnum();
							i.load( project.makeRelativeFilePath(absPath) );
						}
					});
				}
			});

			ctx.addAction({
				label:L.t._("CastleDB"),
				cb: ()->{
					var path = settings.getUiDir(project, "ImportEnumCdb", project.getProjectDir());
					dn.js.ElectronDialogs.openFile([".cdb"], path, function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						settings.storeUiDir(project, "ImportEnumCdb", dn.FilePath.extractDirectoryWithoutSlash(absPath, true));
						if( dn.FilePath.extractExtension(absPath,true) != "cdb" )
							N.error("The file must have the CDB extension.");
						else {
							var i = new importer.enu.CastleDb();
							i.load( project.makeRelativeFilePath(absPath) );
						}
					});
				},
			});

		});

		// Create quick search
		search = new ui.QuickSearch( jContent.find(".enumList ul") );
		search.jWrapper.appendTo( jContent.find(".search") );

		// Default enum selection
		if( project.defs.enums.length>0 )
			selectEnum( project.defs.enums[0] );

		updateEnumList();
		updateEnumForm();
	}

	function deleteEnumDef(ed:data.def.EnumDef, fromContext:Bool) {
		if( ed.isExternal() ) {
			// Extern enum removal
			new ui.modal.dialog.Confirm(
				L.t._("WARNING: removing this external enum will also remove ALL the external enums from the same source! Please note that this will also affect all Entities using any of these enums in ALL levels."),
				true,
				function() {
					var name = dn.FilePath.fromFile(ed.externalRelPath).fileWithExt;
					new ui.LastChance( L.t._("::file:: enums deleted", { file:name }), project );
					editor.watcher.stopWatchingRel(ed.externalRelPath);
					project.defs.removeExternalEnumSource(ed.externalRelPath);
					editor.ge.emit(EnumDefRemoved);
					selectEnum( project.defs.enums[0] );
				}
			);
		}
		else {
			// Local enum removal
			function _delete() {
				new ui.LastChance( L.t._("Enum ::name:: deleted", { name: ed.identifier}), project );
				project.defs.removeEnumDef(ed);
				editor.ge.emit(EnumDefRemoved);
				selectEnum( project.defs.enums[0] );
			}
			var isUsed = project.isEnumDefUsed(ed);
			if( !isUsed && !fromContext )
				new ui.modal.dialog.Confirm(Lang.t._("This enum is not used and can be safely removed."), _delete);
			else if( isUsed )
				new ui.modal.dialog.Confirm(
					Lang.t._("WARNING! This ENUM is used in one or more entity fields. These fields will also be deleted!"),
					true,
					_delete
				);
			else
				_delete();
		}

	}

	override function onGlobalEvent(ge:GlobalEvent) {
		super.onGlobalEvent(ge);

		switch(ge) {
			case ProjectSelected:
				if( curEnum==null || project.defs.getEnumDef(curEnum.identifier)==null )
					selectEnum(project.defs.enums[0]);
				else
					selectEnum( project.defs.getEnumDef(curEnum.identifier) );

			case EnumDefChanged, EnumDefRemoved, EnumDefValueRemoved, EnumDefSorted, ExternalEnumsLoaded(_):
				updateEnumList();
				updateEnumForm();

			case _:
		}

	}


	public function selectEnum(ed:data.def.EnumDef) {
		curEnum = ed;
		updateEnumList();
		updateEnumForm();
	}

	function updateEnumList() {
		var jEnumList = jContent.find(".enumList>ul");
		jEnumList.empty();

		// List context menu
		ContextMenu.attachTo(jEnumList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = project.defs.pasteEnumDef(App.ME.clipboard);
					editor.ge.emit(EnumDefAdded);
					selectEnum(copy);
				},
				enable: ()->App.ME.clipboard.is(CEnumDef),
			},
		]);

		var tagGroups = project.defs.groupUsingTags(project.defs.enums, ed->ed.tags);
		for( group in tagGroups) {
			// Tag name
			if( tagGroups.length>1 ) {
				var jSep = new J('<li class="title collapser"/>');
				jSep.text( group.tag==null ? L._Untagged() : group.tag );
				jSep.appendTo(jEnumList);
				jSep.attr("id", project.iid+"_enum_tag_"+group.tag);
				jSep.attr("default", "open");
			}

			var jLi = new J('<li class="subList draggable"/>');
			jLi.appendTo(jEnumList);
			var jSubList = new J('<ul class="niceList compact"/>');
			jSubList.appendTo(jLi);

			for(ed in group.all) {
				var jLi = new J('<li class="draggable"/>');
				jLi.appendTo(jSubList);
				jLi.data("uid", ed.uid);
				if( ed==curEnum )
					jLi.addClass("active");
				jLi.append('<span class="name">'+ed.identifier+'</span>');
				jLi.click( function(_) {
					selectEnum(ed);
				});

				ContextMenu.attachTo_new(jLi, (ctx:ContextMenu)->{
					ctx.addElement( Ctx_CopyPaster({
						elementName: "enum",
						clipType: CLayerDef,

						copy: ()->App.ME.clipboard.copyData(CEnumDef, ed.toJson(project)),
						cut: ()->{
							App.ME.clipboard.copyData(CEnumDef, ed.toJson(project));
							deleteEnumDef(ed, true);
						},
						paste: ()->{
							var copy = project.defs.pasteEnumDef(App.ME.clipboard, ed);
							editor.ge.emit(EnumDefAdded);
							selectEnum(copy);
						},
						duplicate: ()->{
							var copy = project.defs.duplicateEnumDef(ed);
							editor.ge.emit(EnumDefAdded);
							selectEnum(copy);
						},
						delete: ()->deleteEnumDef(ed,true),
					}) );
				});
			}


			// Make sub list sortable
			JsTools.makeSortable(jSubList, function(ev) {
				var jItem = new J(ev.item);
				var fromIdx = project.defs.getInternalEnumIndex( jItem.data("uid") );
				var toIdx = ev.newIndex>ev.oldIndex
					? jItem.prev().length==0 ? 0 : project.defs.getInternalEnumIndex( jItem.prev().data("uid") )
					: jItem.next().length==0 ? project.defs.entities.length-1 : project.defs.getInternalEnumIndex( jItem.next().data("uid") );

				var moved = project.defs.sortEnumDef(fromIdx, toIdx);
				selectEnum(moved);
				editor.ge.emit(EnumDefSorted);
			}, { onlyDraggables:true });

		}

		var grouped = project.defs.getGroupedExternalEnums();
		for( group in grouped.keyValueIterator() ) {
			var fullPath = project.makeAbsoluteFilePath(group.key);

			// Source name
			var jSep = new J("<li/>");
			jSep.appendTo(jEnumList);
			jSep.addClass("title collapser");
			var name = dn.FilePath.fromFile(group.key).fileWithExt;
			jSep.html('<span>$name</span>');
			jSep.attr("id", project.iid+"_entity_tag_"+name);
			jSep.attr("default", "open");

			// Check file
			var fileExists = NT.fileExists(fullPath);
			if( !fileExists ) {
				jSep.addClass("missing");
				jSep.append('<div class="error">File not found!</div>');
			}
			else {
				var checksum = haxe.crypto.Md5.encode( NT.readFileString(fullPath) );
				for( ed in group.value )
					if( ed.externalFileChecksum!=checksum ) {
						jSep.append('<div class="error">File was modified, please use sync.</div>');
						break;
					}
			}

			var links = new J('<div class="links"/>');
			links.appendTo(jSep);

			// Sync button
			var jSync = new J('<a> <span class="icon refresh"/> </a>');
			jSync.appendTo(links);
			jSync.click( function(ev) {
				importer.ExternalEnum.sync(group.key);
			});
			Tip.attach(jSync, Lang.t._("Reload and synchronize Enums"));

			// Explore button
			if( fileExists ) {
				var a = JsTools.makeLocateLink(fullPath, true);
				a.appendTo(links);
			}

			// Delete button
			if( group.value.length>0 ) {
				var jDelete = new J('<a class="red"> <span class="icon delete"/> </a>');
				jDelete.appendTo(links);
				jDelete.click( function(ev) {
					deleteEnumDef(group.value[0], false);
				});
				Tip.attach(jDelete, Lang.t._("Remove this external Enum source"));
			}

			var jSubList = new J('<li class="subList"> <ul class="niceList compact"></ul> </li>');
			jSubList.appendTo(jEnumList);
			jSubList = jSubList.children("ul");

			// Values
			for(ed in group.value) {
				var jLi = new J("<li/>");
				jLi.appendTo(jSubList);
				if( !fileExists )
					jLi.addClass("missing");
				if( ed==curEnum )
					jLi.addClass("active");
				jLi.append('<span class="name">'+ed.identifier+'</span>');
				jLi.click( _->{
					selectEnum(ed);
				});


				ContextMenu.attachTo(jLi, [
					{
						label: L.t._("Remove extern source"),
						cb: deleteEnumDef.bind(ed,true),
					}
				]);
			}
		}

		// Make list sortable
		// JsTools.makeSortable(jEnumList, function(ev) {
		// 	var moved = project.defs.sortEnumDef(ev.oldIndex, ev.newIndex);
		// 	selectEnum(moved);
		// 	editor.ge.emit(EnumDefSorted);
		// });

		JsTools.parseComponents(jEnumList);
		checkBackup();
		search.run();
	}



	function updateEnumForm() {
		var jFormWrapper = jContent.find(".enumFormWrapper");
		jFormWrapper.find("*").off();

		var jDefForm = jContent.find("dl.enumForm");

		if( curEnum==null ) {
			jFormWrapper.hide();
			jContent.find(".none").show();
			return;
		}
		jFormWrapper.show();
		jContent.find(".none").hide();
		jFormWrapper.find("input").not("xml input").removeAttr("readonly");

		if( curEnum.isExternal() )
			jFormWrapper.addClass("externalEnum");
		else
			jFormWrapper.removeClass("externalEnum");



		// Enum ID
		var i = Input.linkToHtmlInput( curEnum.identifier, jDefForm.find("[name=id]") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isEnumIdentifierUnique(id, curEnum));
		i.linkEvent(EnumDefChanged);

		// Source path
		if( curEnum.isExternal() ) {
			jDefForm.find(".source .path, .source .exploreTo").remove();
			jDefForm.find(".source")
				.show()
				.append( JsTools.makePath(curEnum.externalRelPath) )
				.append( JsTools.makeLocateLink( project.makeAbsoluteFilePath(curEnum.externalRelPath), true ) );
		}
		else
			jDefForm.find(".source").hide();

		// Tags
		var ted = new TagEditor(
			curEnum.tags,
			()->editor.ge.emit(EnumDefChanged),
			()->project.defs.getRecallTags(project.defs.enums, ed->ed.tags),
			()->project.defs.enums.map( enumDef->enumDef.tags ),
			(oldT,newT)->{
				for(enumDef in project.defs.enums)
					enumDef.tags.rename(oldT,newT);
				editor.ge.emit( EnumDefChanged );
			}
		);
		jDefForm.find("#tags").empty().append(ted.jEditor);

		// Tilesets
		var jSelect = JsTools.createTilesetSelect(
			project,
			jDefForm.find("select#icons"),
			curEnum.iconTilesetUid,
			true,
			(uid)->{
				// Check if a LastChance is needed
				if( curEnum.iconTilesetUid!=null )
					for( v in curEnum.values )
						if( v.tileRect!=null ) {
							new LastChance(Lang.t._("Enum icons changed"), project);
							break;
						}

				// Update tileset link
				if( uid<0 )
					curEnum.iconTilesetUid = null;
				else
					curEnum.iconTilesetUid = uid;
				curEnum.clearAllTileIds();
				editor.ge.emit(EnumDefChanged);

			}
		);
		if( !curEnum.allowValueCustomization() )
			jSelect.attr("disabled","true");
		else
			jSelect.removeAttr("disabled");

		// Values
		var jValuesList = jFormWrapper.find("ul.enumValues");
		if( curEnum.isExternal() )
			jValuesList.addClass("external");
		else
			jValuesList.removeClass("external");
		jValuesList.empty().off();
		var xml = jContent.find("xml.enum").children();
		for(eValue in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jValuesList);
			li.append( xml.clone() );

			// Identifier
			var i = new form.input.StringInput(li.find(".name"),
				function() return eValue.id,
				function(newV) {
					if( !curEnum.renameValue(eValue.id, newV) )
						N.invalidIdentifier(newV);
				}
			);
			i.linkEvent(EnumDefChanged);
			if( eValue.color!=null )
				i.jInput.css({
					color: C.intToHex( C.toWhite(eValue.color,0.7) ),
					borderColor: C.intToHex( eValue.color ),
					backgroundColor: C.intToHex( C.toBlack(eValue.color,0.5) ),
				});

			// Color
			var jColor = li.find("[type=color]");
			jColor.change( ev->{
				eValue.color = C.hexToInt( jColor.val() );
				editor.ge.emit(EnumDefChanged);
			});
			jColor.val( C.intToHex(eValue.color) );
			if( !curEnum.allowValueCustomization() )
				jColor.attr("disabled","true");
			else
				jColor.removeAttr("disabled");

			// Tile preview
			var jPicker = JsTools.createTileRectPicker(
				curEnum.iconTilesetUid,
				eValue.tileRect,
				curEnum.allowValueCustomization(),
				(r)->{
					if( r==null )
						return;
					eValue.tileRect = r;
					curEnum.tidy(project);
					editor.ge.emit(EnumDefChanged);
				}
			);
			jPicker.appendTo( li.find(".pickerWrapper") );

			// Remove value button
			var jDelete = li.find(".delete");
			if( curEnum.isExternal() )
				jDelete.hide();
			else {
				jDelete.click( function(ev) {
					var isUsed = project.isEnumValueUsed(curEnum, eValue.id );
					if( isUsed ) {
						new ui.modal.dialog.Confirm(
							ev.getThis(),
							Lang.t._("WARNING! This enum value is USED in one or more entity instances. These values will also be removed!"),
							isUsed,
							function() {
								new LastChance(L.t._("Enum value ::name:: deleted", { name:curEnum.identifier+"."+eValue.id }), project);
								curEnum.removeValue(eValue.id);
								project.tidy();
								editor.ge.emit(EnumDefValueRemoved);
							}
						);
					}
					else {
						curEnum.removeValue(eValue.id);
						project.tidy();
						editor.ge.emit(EnumDefValueRemoved);
					}
				});
			}
		}

		var jAdd = jFormWrapper.find(".createEnumValue");
		if( curEnum.isExternal() )
			jAdd.hide();
		else
			jAdd.show();
		jAdd.click( function(_) {
			var uid = 0;
			while( curEnum.addValue(curEnum.identifier+uid)==null )
				uid++;
			editor.ge.emit(EnumDefChanged);
			var jElem = jFormWrapper.find("ul.enumValues li:last input[type=text]");
			jElem.select();
			JsTools.focusScrollableList( jFormWrapper.find("ul.enumValues"), jElem);
		});

		if( curEnum.isExternal() ) {
			jFormWrapper.find("input").not("xml input").attr("readonly", "readonly");
			jFormWrapper.find("select").not("xml select").attr("readonly", "readonly");
		}

		// Make fields list sortable
		if( !curEnum.isExternal() )
			JsTools.makeSortable(jValuesList, function(ev) {
				var v = curEnum.values.splice(ev.oldIndex,1)[0];
				curEnum.values.insert(ev.newIndex, v);
				editor.ge.emit(EnumDefChanged);
			});

		JsTools.parseComponents(jFormWrapper);
		checkBackup();
	}
}
