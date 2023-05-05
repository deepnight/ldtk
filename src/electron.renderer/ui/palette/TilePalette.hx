package ui.palette;

class TilePalette extends ui.ToolPalette {

	// NOTE: the picker is re-created on every render!
	public var picker : Null<ui.ts.TileToolPicker>;

	public function new(t) {
		super(t);
	}

	override function needToPopOut():Bool {
		return super.needToPopOut() || picker!=null && !picker.isViewFitted();
	}


	override function doRender() {
		super.doRender();

		var tool : tool.lt.TileTool = cast tool;
		if( tool.curTilesetDef==null ) {
			jContent.addClass("invalid");
			jContent.append('<div class="warning">'+Lang.t._("This tile layer has no Tileset.")+'</div>');
			return;
		}

		jContent.removeClass("invalid");

		// Picker
		var old = picker;
		picker = new ui.ts.TileToolPicker(jContent, tool.curTilesetDef, tool, true);
		if( old!=null )
			picker.useOldTilesetPos(old);
		picker.onSelectAnything = ()->updateOptions();

		updateOptions();
	}


	function updateOptions() {
		var tool : tool.lt.TileTool = cast tool;
		jPaletteOptions.empty();

		// Random mode
		var jRandom = new J('<button class="toggle"> <span class="icon random"></span> </button>');
		jRandom.appendTo(jPaletteOptions);
		Tip.attach(jRandom, "Enable random mode for current selection of tiles", [K.R]);
		if( tool.isRandomMode() )
			jRandom.addClass("on");
		jRandom.click(_->{
			tool.setMode( tool.isRandomMode() ? Stamp : Random );
			Editor.ME.ge.emit(ToolOptionChanged);
			render();
		});

		// Save selection
		var jSave = new J('<button class="gray"> <span class="icon save"></span> </button>');
		jSave.appendTo(jPaletteOptions);
		Tip.attach(jSave, "Memorize current selection of tiles", [K.S, K.SHIFT]);
		jSave.click( function(_) {
			tool.saveSelection();
		});

		// Fit view
		var jFit = new J('<button class="toggle"> <span class="icon fit"></span> </button>');
		jFit.appendTo(jPaletteOptions);
		Tip.attach(jFit, "Fit tileset view in the interface panel");
		if( picker.isViewFitted() )
			jFit.addClass("on");
		jFit.click(_->{
			if( picker==null )
				return;
			picker.setViewFit(!picker.isViewFitted());
			render();
		});
	}


	override function onNavigateSelection(dx:Int, dy:Int, pressed:Bool):Bool {
		if( picker!=null )
			picker.navigate(dx,dy);
		return true;
	}

	override function focusOnSelection(immediate=false) {
		super.focusOnSelection();
		if( picker!=null )
			picker.focusOnSelection(immediate);
	}

	override function update() {
		super.update();

		if( picker!=null )
			picker.update();
	}
}