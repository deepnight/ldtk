package ui.modal.dialog;

/**
 * Lets the user choose which Aseprite leaf layers are flattened into a new
 * LDtk spritesheet. Layer paths use Aseprite's group/layer CLI syntax.
 */
class AsepriteLayerPicker extends ui.Modal {
	var allLayers : Array<String>;
	var selected : Map<String,Bool> = new Map();
	var jRows : js.jquery.JQuery;
	var jImport : js.jquery.JQuery;
	var onImport : Array<String>->Void;

	public function new(sourceRelPath:String, layers:Array<String>, onImport:Array<String>->Void) {
		super();
		this.allLayers = layers.copy();
		this.onImport = onImport;
		addClass("asepriteLayerPicker");
		setAnchor(MA_Centered);

		jContent.append('<h2><span class="icon layer"></span> Choose Aseprite layers</h2>');
		var jHelp = new J('<p class="help"></p>');
		jHelp.text("Select the layers that should become the LDtk spritesheet. Normal maps, emission maps, guides, masks, and other helper layers can be left unchecked. The Aseprite source file is not modified.");
		jHelp.appendTo(jContent);

		var jSource = new J('<p class="sub" style="margin-bottom:10px"></p>');
		jSource.text("Source: "+sourceRelPath);
		jSource.appendTo(jContent);

		var jTopActions = new J('<div style="display:flex; gap:6px; margin-bottom:8px"></div>');
		jTopActions.appendTo(jContent);
		var jAll = new J('<button class="gray">Select all</button>');
		var jNone = new J('<button class="gray">Select none</button>');
		jAll.appendTo(jTopActions);
		jNone.appendTo(jTopActions);

		jRows = new J('<div style="min-width:420px; max-height:420px; overflow:auto; border-top:1px solid rgba(255,255,255,.08); border-bottom:1px solid rgba(255,255,255,.08)"></div>');
		jRows.appendTo(jContent);

		for(layerPath in allLayers) {
			selected.set(layerPath,true);
			var parts = layerPath.split("/");
			var name = parts.pop();
			var depth = parts.length;

			var jRow = new J('<label style="display:flex; align-items:center; gap:8px; padding:6px 8px; cursor:pointer"></label>');
			jRow.css("padding-left", (8+depth*18)+"px");
			jRow.appendTo(jRows);

			var jCheck = new J('<input type="checkbox" checked="checked"/>');
			jCheck.appendTo(jRow);
			var jName = new J('<span style="flex:1"></span>');
			jName.text(name);
			jName.appendTo(jRow);
			if( parts.length>0 ) {
				var jGroup = new J('<span class="sub"></span>');
				jGroup.text(parts.join(" / "));
				jGroup.appendTo(jRow);
			}

			jCheck.change(_->{
				selected.set(layerPath, jCheck.prop("checked")==true);
				updateState();
			});
		}

		var jActions = new J('<div class="buttons" style="margin-top:14px; display:flex; gap:8px"></div>');
		jActions.appendTo(jContent);
		jImport = new J('<button class="positive"><span class="icon layer"></span> Import selected layers</button>');
		jImport.appendTo(jActions);
		var jCancel = new J('<button class="gray">Cancel</button>');
		jCancel.appendTo(jActions);

		jAll.click(_->setAll(true));
		jNone.click(_->setAll(false));
		jCancel.click(_->close());
		jImport.click(_->{
			var picked = getSelectedLayers();
			if( picked.length==0 )
				return;
			close();
			onImport(picked);
		});

		updateState();
		JsTools.parseComponents(jContent);
	}

	function setAll(v:Bool) {
		for(layer in allLayers)
			selected.set(layer,v);
		jRows.find("input[type=checkbox]").prop("checked",v);
		updateState();
	}

	function getSelectedLayers() : Array<String> {
		var out : Array<String> = [];
		for(layer in allLayers)
			if( selected.exists(layer) && selected.get(layer)==true )
				out.push(layer);
		return out;
	}

	function updateState() {
		if( jImport==null )
			return;
		var n = getSelectedLayers().length;
		jImport.prop("disabled",n<=0);
		jImport.text(n<=0 ? "Choose at least one layer" : 'Import $n selected layer${n==1 ? "" : "s"}');
	}
}
