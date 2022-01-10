package ui.modal.panel;

class EditEnumDefs extends ui.modal.Panel {
	var curEnum : Null<data.def.EnumDef>;

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
			ctx.add({
				label:L.t._("Haxe source code"),
				cb: ()->{
					dn.js.ElectronDialogs.openFile([".hx"], project.getProjectDir(), function(absPath:String) {
						absPath = StringTools.replace(absPath,"\\","/");
						if( dn.FilePath.extractExtension(absPath)!="hx" )
							N.error("The file must have the HX extension.");
						else
							importer.HxEnum.load( project.makeRelativeFilePath(absPath), false );
					});
				}
			});
			ctx.add({
				label:L.t._("CastleDB"),
				cb: ()->N.notImplemented()
			});
			ctx.add({
				label:L.t._("JSON"),
				cb: ()->N.notImplemented()
			});
		});

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

			case EnumDefChanged, EnumDefRemoved, EnumDefValueRemoved, EnumDefSorted:
				updateEnumList();
				updateEnumForm();

			case _:
		}

	}


	function selectEnum(ed:data.def.EnumDef) {
		curEnum = ed;
		updateEnumList();
		updateEnumForm();
	}

	function updateEnumList() {
		var jList = jContent.find(".enumList ul");
		jList.empty();

		// List context menu
		ContextMenu.addTo(jList, false, [
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

		for(ed in project.defs.enums) {
			var e = new J("<li/>");
			e.appendTo(jList);
			if( ed==curEnum )
				e.addClass("active");
			e.append('<span class="name">'+ed.identifier+'</span>');
			e.click( function(_) {
				selectEnum(ed);
			});

			ContextMenu.addTo(e, [
				{
					label: L._Copy(),
					cb: ()->App.ME.clipboard.copy(CEnumDef, ed.toJson(project)),
				},
				{
					label: L._Cut(),
					cb: ()->{
						App.ME.clipboard.copy(CEnumDef, ed.toJson(project));
						deleteEnumDef(ed, true);
					},
				},
				{
					label: L._PasteAfter(),
					cb: ()->{
						var copy = project.defs.pasteEnumDef(App.ME.clipboard, ed);
						editor.ge.emit(EnumDefAdded);
						selectEnum(copy);
					},
					enable: ()->App.ME.clipboard.is(CEnumDef),
				},
				{
					label: L._Duplicate(),
					cb: ()->{
						var copy = project.defs.duplicateEnumDef(ed);
						editor.ge.emit(EnumDefAdded);
						selectEnum(copy);
					},
				},
				{
					label: L._Delete(),
					cb: deleteEnumDef.bind(ed,true),
				}
			]);
		}

		var grouped = project.defs.getGroupedExternalEnums();
		for( group in grouped.keyValueIterator() ) {
			var fullPath = project.makeAbsoluteFilePath(group.key);

			// Source name
			var e = new J("<li/>");
			e.addClass("title fixed");
			e.appendTo(jList);
			var name = dn.FilePath.fromFile(group.key).fileWithExt;
			e.html('<span>$name</span>');

			// Check file
			var fileExists = NT.fileExists(fullPath);
			if( !fileExists ) {
				e.addClass("missing");
				e.append('<div class="error">File not found!</div>');
			}
			else {
				var checksum = haxe.crypto.Md5.encode( NT.readFileString(fullPath) );
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
				var a = JsTools.makeExploreLink(fullPath, true);
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
				if( !fileExists )
					e.addClass("missing");
				e.appendTo(jList);
				if( ed==curEnum )
					e.addClass("active");
				e.append('<span class="name">'+ed.identifier+'</span>');
				e.click( function(_) {
					selectEnum(ed);
				});


				ContextMenu.addTo(e, [
					{
						label: L.t._("Remove extern source"),
						cb: deleteEnumDef.bind(ed,true),
					}
				]);
			}
		}

		// Make list sortable
		JsTools.makeSortable(jList, function(ev) {
			var moved = project.defs.sortEnumDef(ev.oldIndex, ev.newIndex);
			selectEnum(moved);
			editor.ge.emit(EnumDefSorted);
		});

		checkBackup();
	}



	function updateEnumForm() {
		var jFormWrapper = jContent.find(".enumFormWrapper");
		jFormWrapper.find("*").off();

		var jDefForm = jContent.find("dl.enumForm");

		if( curEnum==null ) {
			jFormWrapper.hide();
			return;
		}
		jFormWrapper.show();
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
				.append( JsTools.makeExploreLink( project.makeAbsoluteFilePath(curEnum.externalRelPath), true ) );
		}
		else
			jDefForm.find(".source").hide();

		// Tilesets
		var jSelect = jDefForm.find("select#icons");
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


		// Values
		var jList = jFormWrapper.find("ul.enumValues");
		jList.empty().off();
		var xml = jContent.find("xml.enum").children();
		for(eValue in curEnum.values) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append( xml.clone() );

			// Identifier
			var i = new form.input.StringInput(li.find(".name"),
				function() return eValue.id,
				function(newV) {
					if( !curEnum.renameValue(project, eValue.id, newV) )
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

			if( curEnum.isExternal() )
				li.find(".sortHandle").hide();

			// Color
			var jColor = li.find("[type=color]");
			jColor.change( ev->{
				eValue.color = C.hexToInt( jColor.val() );
				editor.ge.emit(EnumDefChanged);
			});
			jColor.val( C.intToHex(eValue.color) );

			// Tile preview
			var jPicker = JsTools.createTilePicker(
				curEnum.iconTilesetUid,
				PickAndClose,
				eValue.tileId==null ? [] : [eValue.tileId],
				(tileIds)->{
					eValue.tileId = tileIds[0];
					eValue.color = -1;
					curEnum.tidy(project);
					editor.ge.emit(EnumDefChanged);
				}
			);
			jPicker.appendTo( li.find(".pickerWrapper") );

			// Remove value button
			if( !curEnum.isExternal() ) {
				li.find(".delete").click( function(ev) {
					var isUsed = project.isEnumValueUsed(curEnum, eValue.id );
					if( isUsed ) {
						new ui.modal.dialog.Confirm(
							ev.getThis(),
							Lang.t._("WARNING! This enum value is USED in one or more entity instances. These values will also be removed!"),
							isUsed,
							function() {
								new LastChance(L.t._("Enum value ::name:: deleted", { name:curEnum.identifier+"."+eValue.id }), project);
								project.defs.removeEnumDefValue(curEnum, eValue.id);
								editor.ge.emit(EnumDefValueRemoved);
							}
						);
					}
					else {
						project.defs.removeEnumDefValue(curEnum, eValue.id);
						editor.ge.emit(EnumDefValueRemoved);
					}
				});
			}
		}

		jFormWrapper.find(".createEnumValue").click( function(_) {
			var uid = 0;
			while( !curEnum.addValue(curEnum.identifier+uid) )
				uid++;
			editor.ge.emit(EnumDefChanged);
			var jElem = jFormWrapper.find("ul.enumValues li:last input[type=text]");
			jElem.select();
			JsTools.focusScrollableList( jFormWrapper.find("ul.enumValues"), jElem);
		});

		if( curEnum.isExternal() )
			jFormWrapper.find("input").not("xml input").attr("readonly", "readonly");

		// Make fields list sortable
		if( !curEnum.isExternal() )
			JsTools.makeSortable(jList, function(ev) {
				var v = curEnum.values.splice(ev.oldIndex,1)[0];
				curEnum.values.insert(ev.newIndex, v);
				editor.ge.emit(EnumDefChanged);
			});

		JsTools.parseComponents(jFormWrapper);
		checkBackup();
	}
}
