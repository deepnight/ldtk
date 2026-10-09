package ui.modal.dialog;

import misc.TilesetAtlasComposer;
import misc.TilesetAtlasComposer.AtlasComposeSource;

/**
 * UI for selecting arbitrary tile cells from any normal image-backed LDtk
 * tileset (PNG/GIF/JPEG/Aseprite) and composing them into one generated atlas.
 */
class AtlasComposer extends ui.Modal {
	var selections : Map<Int,Array<Int>> = new Map();
	var jRows : js.jquery.JQuery;
	var jName : js.jquery.JQuery;
	var jCompose : js.jquery.JQuery;

	public function new() {
		super();
		addClass("atlasComposer");
		setAnchor(MA_Centered);

		jContent.append('<h2><span class="icon tile"></span> Atlas composer</h2>');
		jContent.append('<p class="help">Pick individual tile cells from any image-backed tileset. Selected cells are moved into one generated atlas, remaining cells are compacted into generated remainder atlases, and LDtk references are migrated automatically.</p>');
		jContent.append('<p class="warning"><strong>Safety:</strong> multi-cell Entity sprites, tile fields, enum icons, stamps and saved selections are kept together automatically. LDtk will refuse a composition that would split a single Tile/AutoLayer/Enum/Tile-field reference across two atlases.</p>');

		var jNameRow = new J('<div class="formRow"></div>');
		jNameRow.appendTo(jContent);
		jNameRow.append('<label style="display:inline-block; min-width:170px">New atlas identifier</label>');
		jName = new J('<input type="text" value="CombinedTileset" style="min-width:260px"/>');
		jName.appendTo(jNameRow);

		jContent.append('<h3>Source tilesets</h3>');
		jRows = new J('<div class="atlasComposerRows"></div>');
		jRows.appendTo(jContent);
		renderRows();

		var jActions = new J('<div class="buttons" style="margin-top:16px; display:flex; gap:8px"></div>');
		jActions.appendTo(jContent);
		jCompose = new J('<button class="positive"><span class="icon tile"></span> Compose selected tiles</button>');
		jCompose.appendTo(jActions);
		var jCancel = new J('<button class="gray">Cancel</button>');
		jCancel.appendTo(jActions);
		jCancel.click(_->close());
		jCompose.click(_->compose());

		JsTools.parseComponents(jContent);
	}

	function renderRows() {
		jRows.empty();
		var any = false;
		for(td in project.defs.tilesets) {
			if( td.isUsingEmbedAtlas() || td.relPath==null )
				continue;
			any = true;
			var jRow = new J('<div class="atlasComposerRow" style="display:flex; align-items:center; gap:8px; padding:6px 0; border-bottom:1px solid rgba(255,255,255,.08)"></div>');
			jRow.appendTo(jRows);

			var jPreview = td.createCanvasFromTileId(0,32);
			jPreview.appendTo(jRow);
			var jLabel = new J('<div style="min-width:250px; flex:1"></div>');
			jLabel.appendTo(jRow);
			jLabel.append('<strong>${td.identifier}</strong><br/>');
			jLabel.append('<span class="sub">${td.getFileName(true)} · ${td.tileGridSize}px · ${td.cWid}×${td.cHei} cells</span>');

			var current = selections.exists(td.uid) ? selections.get(td.uid) : [];
			var jCount = new J('<span class="count" style="min-width:90px; text-align:right">${current.length} selected</span>');
			jCount.appendTo(jRow);
			var jPick = new J('<button><span class="icon tile"></span> Choose tiles</button>');
			jPick.appendTo(jRow);
			jPick.click(_->{
				var cur = selections.exists(td.uid) ? selections.get(td.uid).copy() : [];
				JsTools.openTilePickerModal(td.uid, MultipleIndividuals, cur, false, ids->{
					selections.set(td.uid,ids.copy());
					jCount.text(ids.length+" selected");
					updateComposeState();
				});
			});
		}
		if( !any )
			jRows.append('<p>No editable image-backed tilesets are available.</p>');
		updateComposeState();
	}

	function selectedCount() {
		var n = 0;
		for(ids in selections)
			n += ids.length;
		return n;
	}

	function updateComposeState() {
		if( jCompose==null ) return;
		var n = selectedCount();
		jCompose.prop("disabled",n<=0);
		jCompose.attr("title", n<=0 ? "Choose at least one tile first" : 'Compose $n selected tile cells');
	}

	function compose() {
		var sources : Array<AtlasComposeSource> = [];
		for(uid in selections.keys()) {
			var ids = selections.get(uid);
			if( ids!=null && ids.length>0 )
				sources.push({tilesetUid:uid,tileIds:ids.copy()});
		}
		if( sources.length==0 ) {
			new Warning(L.t._("Choose at least one tile first."));
			return;
		}

		var requested = StringTools.trim(Std.string(jName.val()));
		if( requested.length==0 ) requested="CombinedTileset";

		try {
			new LastChance(L.t._("Compose tilesets"),project);
			var result = TilesetAtlasComposer.compose(project,requested,sources);
			var dest = project.defs.getTilesetDef(result.destinationUid);
			if( dest!=null ) {
				editor.ge.emit(TilesetDefAdded(dest));
				editor.ge.emit(TilesetImageLoaded(dest,false));
			}
			var parent = ui.Modal.getFirst(ui.modal.panel.EditTilesetDefs);
			if( parent!=null && dest!=null ) parent.selectTileset(dest);
			N.success('Created ${result.destinationIdentifier}: ${result.movedTileCount} tile cells moved and references migrated.');
			close();
		}
		catch(e:Dynamic) {
			App.LOG.error(e);
			new Warning(L.t._("Atlas composition stopped before source definitions were removed:\n\n::error::", {error:Std.string(e)}));
		}
	}
}
