package ui.modal;

class DebugMenu extends ui.modal.ContextMenu {
	public function new() {
		super();

		if( editor!=null ) {

			add(L.untranslated("Toggle debug print"), ()->{
				if( App.ME.cd.has("debugTools") ) {
					App.ME.clearDebug();
					App.ME.cd.unset("debugTools");
				}
				else
					App.ME.cd.setS("debugTools", Const.INFINITE);
			});

			add(L.untranslated("Rebuild tilesets pixel cache"), ()->{
				for(td in project.defs.tilesets)
					td.buildPixelData( editor.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
			});

			add(L.untranslated("Rebuild auto-layers"), ()->{
				for(l in project.levels)
				for(li in l.layerInstances)
					li.autoTilesCache = null;
				editor.checkAutoLayersCache( (_)->{
					N.success("Done");
					editor.levelRender.invalidateAll();
					editor.worldRender.renderAll();
				});
			});
		}

		add(L.untranslated("Open settings dir"), ()->{
			JsTools.exploreToFile(Settings.getDir(), false);
		});

		add(L.untranslated("Emulate new update"), ()->{
			App.ME.settings.v.lastKnownVersion = null;
			App.ME.settings.save();
			dn.electron.ElectronUpdater.emulate();
		});

		add(L.untranslated("Print full log"), ()->{
			App.LOG.printAll();
		});

		add(L.untranslated("Use best GPU: "+settings.v.useBestGPU), ()->{
			settings.v.useBestGPU = !settings.v.useBestGPU;
			settings.save();
		});

		add(L.untranslated("Flush log to disk"), ()->{
			App.LOG.general( "\n"+dn.Process.rprintAll() );
			App.LOG.flushToFile();
			N.success("Flushed.");
		});

		add(L.untranslated("Update sample maps"), ()->{
			var path = JsTools.getSamplesDir();
			var files = js.node.Fs.readdirSync(path);
			var log = new dn.Log();
			log.printOnAdd = true;
			var ops = [];
			for(f in files) {
				var fp = dn.FilePath.fromFile(path+"/"+f);
				if( fp.extension!="ldtk" )
					continue;

				ops.push({
					label: fp.fileName,
					cb: ()->{
						// Loading
						log.fileOp(fp.fileName+"...");
						log.general(" -> Loading...");
						try {
							ui.ProjectLoader.load(fp.full, (?p,?err)->{
								if( p==null )
									throw "Failed on "+fp.full;
								// Tilesets
								log.general(" -> Updating tileset data...");
								for(td in p.defs.tilesets) {
									td.importAtlasImage(td.relPath);
									td.buildPixelData(()->{}, true);
								}

								// Auto layer rules
								log.general(" -> Updating auto-rules cache...");
								for(l in p.levels)
								for(li in l.layerInstances) {
									if( !li.def.isAutoLayer() )
										continue;
									li.applyAllAutoLayerRules();
								}

								// Write sample map
								log.general(" -> Saving "+fp.fileName+"...");
								var s = new ui.ProjectSaving(App.ME, p);
							});

						}
						catch(e:Dynamic) {
							new ui.modal.dialog.Message("Failed on "+fp.fileName);
						}
					}
				});
			}
			new ui.modal.Progress("Updating samples", 1, ops);
		});

		add(L.untranslated("Crash"), ()->{
			App.LOG.warning("Emulating crash...");
			var a : Dynamic = null;
			a.crash = 5;
		});
	}
}