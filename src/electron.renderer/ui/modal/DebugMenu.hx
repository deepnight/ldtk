package ui.modal;

class DebugMenu extends ui.modal.ContextMenu {
	public function new() {
		super();

		addTitle(L.t._("Debug menu"));

		#if debug
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
		#end

		if( editor!=null ) {

			add({
				label: L.untranslated("Clear levels cache"),
				cb: ()->{
					for(l in project.levels)
						editor.invalidateLevelCache(l);
				}
			});

			add({
				label: L.untranslated("Invalidate world render"),
				cb: editor.worldRender.invalidateAll,
			});

			add({
				label: L.untranslated("Rebuild tilesets pixel cache"),
				cb: ()->{
					for(td in project.defs.tilesets)
						td.buildPixelData( editor.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(td)) );
				}
			});

			add({
				label: L.untranslated("Rebuild all auto-layers"),
				cb: ()->{
					for(l in project.levels)
					for(li in l.layerInstances)
						li.autoTilesCache = null;
					editor.checkAutoLayersCache( (_)->{
						N.success("Done");
						editor.levelRender.invalidateAll();
						editor.worldRender.invalidateAll();
					});
				}
			});
		}

		add({
			label: L.untranslated("Check IIDs"),
			show: ()->Editor.exists(),
			cb: ()->{
				editor.createChildProcess( (p)->{
					App.ME.debug('IIDS', true);
					for(cr in @:privateAccess project.iidsCache.keyValueIterator()) {
						var kind =
							cr.value.ei!=null ? "ENTITY "+cr.value.ei.def.identifier
							: cr.value.li!=null ? "LAYER "+cr.value.li.def.identifier
							: "LEVEL "+cr.value.level.identifier;
						var color = cr.value.ei!=null ? 0x4bdfff :
							cr.value.li!=null ? 0x4bff5d : 0xff4b4b;
						App.ME.debug(kind+" -- "+cr.key, color);
					}
				}, (_)->{
					App.ME.debug("",true);
				});
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
							new ui.ProjectLoader(
								fp.full,
								(p)->{
									// Break level caching
									for(l in p.levels)
										l.invalidateJsonCache();

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
									var s = new ui.ProjectSaver(App.ME, p);
								},
								(err)->new ui.modal.dialog.Message( L.t._("Failed on ::file::", {file:fp.fileName}) )
							);
							return;
						}
					});
				}
				new ui.modal.Progress("Updating samples", 1, ops);
			}
		});

		addTitle(L.untranslated("App"));
		add({
			label: L.untranslated("Open settings dir"),
			cb: ()->ET.locate(Settings.getDir(), false)
		});


		#if debug
		add({
			label: L.untranslated("Emulate new update"),
			cb: ()->{
				App.ME.settings.v.lastKnownVersion = null;
				App.ME.settings.save();
				dn.js.ElectronUpdater.emulate();
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
			label: L.untranslated("Test UUID function"),
			cb: ()->{
				var uniques = 0;
				var total = 0;
				var checkMap = new Map();
				var duplicates = [];
				App.ME.createChildProcess( (p)->{
					App.ME.debug('UUIDs: $uniques/$total (${M.pretty(100*uniques/total,3)}%, dups=${duplicates.length}) \n${duplicates.join("\n")}', true);
					for(i in 0...10000) {
						var u = project.generateUniqueId_UUID();
						if( checkMap.exists(u) )
							duplicates.push(u);
						else
							uniques++;
						checkMap.set(u,true);
						total++;
					}
				});
			}
		});

		add({
			label: L.untranslated("Crash app!"),
			className: "warning",
			cb: ()->{
				App.LOG.warning("Emulating crash...");
				var a : Dynamic = null;
				a.crash = 5;
			}
		});
		#end // End of "if debug"


		add({
			label: L.untranslated("Open dev tools"),
			cb: ()->ET.openDevTools()
		});



		addTitle(L.untranslated("Log"));

		add({
			label: L.untranslated("Locate log file"),
			cb: ()->ET.locate(JsTools.getLogPath(), true)
		});

		add({
			label: L.untranslated("Print log"),
			cb: ()->{
				App.LOG.printAll();
				App.LOG.printOnAdd = true;
			}
		});

		add({
			label: L.untranslated("Flush log to disk"),
			cb: ()->{
				App.LOG.flushToFile();
				N.success("Flushed.");
			}
		});

	}
}