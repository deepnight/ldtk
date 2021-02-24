package ui.modal;

class DebugMenu extends ui.modal.ContextMenu {
	public function new() {
		super();

		if( editor!=null ) {

			add({
				label: L.untranslated("Toggle debug print"),
				cb: ()->{
					if( App.ME.cd.has("debugTools") ) {
						App.ME.clearDebug();
						App.ME.cd.unset("debugTools");
					}
					else
						App.ME.cd.setS("debugTools", Const.INFINITE);
				}
			});

			add({
				label: L.untranslated("Rebuild tilesets pixel cache"),
				cb: ()->{
					for(td in project.defs.tilesets)
						td.buildPixelData( editor.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
				}
			});

			add({
				label: L.untranslated("Rebuild auto-layers"),
				cb: ()->{
					for(l in project.levels)
					for(li in l.layerInstances)
						li.autoTilesCache = null;
					editor.checkAutoLayersCache( (_)->{
						N.success("Done");
						editor.levelRender.invalidateAll();
						editor.worldRender.renderAll();
					});
				}
			});
		}

		add({
			label: L.untranslated("Open settings dir"),
			cb: ()->JsTools.exploreToFile(Settings.getDir(), false)
		});

		add({
			label: L.untranslated("Emulate new update"),
			cb: ()->{
				App.ME.settings.v.lastKnownVersion = null;
				App.ME.settings.save();
				dn.electron.ElectronUpdater.emulate();
			}
		});

		add({
			label: L.untranslated("Print full log"),
			cb: ()->App.LOG.printAll()
		});

		add({
			label: L.untranslated("Flush log to disk"),
			cb: ()->{
				App.LOG.general( "\n"+dn.Process.rprintAll() );
				App.LOG.flushToFile();
				N.success("Flushed.");
			}
		});

		add({
			label: L.untranslated("Update sample maps"),
			cb: ()->{
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

									// IntGrid CSV change
									p.setFlag(DiscardPreCsvIntGrid, true);

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
			}
		});

		add({
			label: L.untranslated("Process profiling"),
			cb: ()->{
				dn.Process.clearProfilingTimes();
				dn.Process.PROFILING = !dn.Process.PROFILING;
				App.ME.clearDebug();
			}
		});

		// Pauses
		function _addPauseToggler(p:dn.Process) {
			add({ label: L.untranslated(p.toString()+" ("+p.isPaused()+")"), cb: ()->p.togglePause() });
		}
		_addPauseToggler(@:privateAccess App.ME.curPageProcess);
		if( editor!=null ) {
			_addPauseToggler(editor.levelRender);
			_addPauseToggler(editor.worldRender);
		}

		add({
			label: L.untranslated("Crash"),
			className: "warning",
			cb: ()->{
				App.LOG.warning("Emulating crash...");
				var a : Dynamic = null;
				a.crash = 5;
			}
		});
	}
}