package ui.modal;

class DebugMenu extends ui.modal.ContextMenu {
	static var iidsProcess : Null<dn.Process>;

	public function new(?id:String) {
		super();


		switch id {
			case null:
				addTitle(L.t._("Debug menu"));

				addAction({
					label: L.untranslated("Toggle debug print"),
					cb: ()->{
						App.ME.clearDebug();
						App.ME.toggleDebugFlag(F_MainDebug);
					}
				});

				#if debug
				addAction({
					label: L.untranslated("Debug flags"),
					cb: ()->new DebugMenu("debugFlags"),
				});
				#end

				#if debug
				addAction({
					label: L.untranslated("Toggle timeline debug"),
					show: ()->Editor.exists(),
					cb: ()->LevelTimeline.toggleDebug(),
				});
				#end

				if( Editor.exists() ) {

					addTitle( L.untranslated("Internal data") );

					addAction({
						label: L.untranslated("Clear levels cache"),
						show: Editor.exists,
						cb: ()->{
							for(w in project.worlds)
							for(l in w.levels)
								editor.invalidateLevelCache(l);
						}
					});

					addAction({
						label: L.untranslated("Invalidate world render"),
						show: Editor.exists,
						cb: ()->editor.worldRender.invalidateAll(),
					});

					addAction({
						label: L.untranslated("Rebuild tilesets pixel cache"),
						show: Editor.exists,
						cb: ()->{
							for(td in project.defs.tilesets)
								td.buildPixelDataAndNotify();
						}
					});

					addAction({
						label: L.untranslated("Rebuild all auto-layers"),
						show: Editor.exists,
						cb: ()->{
							for(ld in project.defs.layers)
							for(rg in ld.autoRuleGroups)
							for(r in rg.rules)
								r.invalidated = true;
							editor.applyInvalidatedRulesInAllLevels();
						}
					});

					addAction({
						label: L.untranslated("Show IIDs"),
						show: ()->Editor.exists(),
						cb: ()->{
							if( iidsProcess!=null && !iidsProcess.destroyed ) {
								iidsProcess.destroy();
								iidsProcess = null;
							}
							else {
								iidsProcess = editor.createChildProcess(
									(p)->{
										App.ME.clearDebug();
										App.ME.debug('ALL IIDS');
										for(iid in @:privateAccess project.usedIids.keys())
											App.ME.debug(iid, 0xff6c3c);

										App.ME.debug("");
										App.ME.debug('REVERSE ENTITY IID REFS');
										for(r in @:privateAccess project.reverseIidRefsCache.keyValueIterator()) {
											var to = project.getEntityInstanceByIid(r.key);
											for(fromIid in r.value.keys()) {
												var from = project.getEntityInstanceByIid(fromIid);
												App.ME.debug(from+" => "+to, 0x62ff99);
												if( from==null )
													App.ME.debug("  Unknown FROM IID:"+fromIid, 0xff0000);
											}
											if( to==null )
												App.ME.debug("  Unknown TO IID:"+r.key, 0xff0000);
										}
									},
									(_)->App.ME.clearDebug()
								);
							}
						}
					});
				}


				addTitle(L.untranslated("Log"));

				addAction({
					label: L.untranslated("Print log"),
					cb: ()->{
						App.LOG.printAll();
						App.LOG.printOnAdd = true;
					}
				});

				addAction({
					label: L.untranslated("Flush log to disk"),
					cb: ()->{
						App.LOG.flushToFile();
						N.success("Flushed.");
					}
				});



				addTitle(L.untranslated("App"));

				addAction({
					label: L.untranslated("Locate dirs... >"),
					cb: ()->new DebugMenu("dirs")
				});

				#if debug
				addAction({
					label: L.untranslated("Gif mode="+ (Editor.exists() ? ""+editor.gifMode : "?")),
					show: Editor.exists,
					cb: ()->{
						editor.gifMode = !editor.gifMode;
						if( editor.gifMode ) {
							editor.setZenMode(true);
							N.success("GIF mode: ON");
						}
						else
							N.error("GIF mode: off");
						App.ME.jBody.find("#miniNotif").hide();
						App.ME.clearDebug();
						editor.updateBanners();
						editor.worldRender.invalidateAll();
					}
				});
				#end


				#if debug
				addAction({
					label: L.untranslated("Update sample maps"),
					cb: ()->{
						var path = JsTools.getSamplesDir();
						var files = NT.readDir(path);
						var log = new dn.Log();
						log.printOnAdd = true;
						var n = 0;
						for(f in files) {
							var fp = dn.FilePath.fromFile(path+"/"+f);
							if( fp.extension!="ldtk" )
								continue;

							n+=2;

							// Load project
							log.fileOp(fp.fileName+"...");
							log.general(" -> Loading...");
							new ui.ProjectLoader(
								fp.full,
								(p)->{
									MetaProgress.advance();

									// Flags
									@:privateAccess p.setFlag(PrependIndexToLevelFileNames, false);
									@:privateAccess p.setFlag(UseMultilinesType, true);

									// Break level caching
									for(w in p.worlds)
									for(l in w.levels)
										l.invalidateJsonCache();

									// Tilesets
									log.general(" -> Updating tileset data...");
									for(td in p.defs.tilesets) {
										td.importAtlasImage(td.relPath);
										td.buildPixelData(true);
									}

									// Auto layer rules
									log.general(" -> Updating auto-rules cache...");
									for(w in p.worlds)
									for(l in w.levels)
									for(li in l.layerInstances) {
										if( !li.def.isAutoLayer() )
											continue;
										li.applyAllRules();
									}

									// Final tidying
									p.tidy();

									// Save project
									log.general(" -> Saving "+fp.fileName+"...");
									var s = new ui.ProjectSaver( App.ME, p, (_)->MetaProgress.advance() );
								},
								(err)->{
									new ui.modal.dialog.Message( L.t._("Failed on ::file::", {file:fp.fileName}) );
									MetaProgress.advance(2);
								}
							);
						}
						ui.modal.MetaProgress.start("Updating all sample maps", n);
					}
				});
				#end


				#if debug
				addAction({
					label: L.untranslated("Emulate new update"),
					cb: ()->{
						App.ME.settings.v.lastKnownVersion = null;
						App.ME.settings.save();
						dn.js.ElectronUpdater.emulate();
					}
				});

				addAction({
					label: L.untranslated("Process profiling"),
					cb: ()->{
						dn.Process.clearProfilingTimes();
						dn.Process.PROFILING = !dn.Process.PROFILING;
						App.ME.clearDebug();
					}
				});

				addAction({
					label: L.untranslated("Crash app!"),
					className: "warning",
					cb: ()->{
						App.LOG.warning("Emulating crash...");
						var a : Dynamic = null;
						a.crash = 5;
					}
				});
				addAction({
					label: L.untranslated("Lose WebGL context"),
					className: "warning",
					cb: ()->{
						App.LOG.warning("Losing webGL context...");
						var canvas = Std.downcast(App.ME.jCanvas.get(0), js.html.CanvasElement);
						// Try on WebGL1
						var glCtx = canvas.getContextWebGL();
						if( glCtx!=null ) {
							App.LOG.warning("  -> WebGL1");
							glCtx.getExtension(WEBGL_lose_context).loseContext();
							return;
						}
						// Try on WebGL2
						var glCtx = canvas.getContextWebGL2();
						if( glCtx!=null ) {
							App.LOG.warning("  -> WebGL2");
							glCtx.getExtension(WEBGL_lose_context).loseContext();
						}
					}
				});
				#end // End of "if debug"


				addAction({
					label: L.untranslated("Open dev tools"),
					cb: ()->ET.openDevTools()
				});



			case "debugFlags":
				addTitle( L.untranslated("Debug flags") );
				for(k in DebugFlag.getConstructors()) {
					var f = DebugFlag.createByName(k);
					addAction({
						label: L.untranslated(k),
						iconId: App.ME.hasDebugFlag(f) ? "active" : "inactive",
						selectionTick: App.ME.hasDebugFlag(f),
						cb: ()->{
							App.ME.toggleDebugFlag(f);
							new DebugMenu(id);
						},
					});
				}



			case "dirs":

				addTitle( L.untranslated("Locate dir") );
				addAction({
					label: L.untranslated("LDtk exe"),
					cb: ()->JsTools.locateFile(JsTools.getExeDir(), false)
				});

				addAction({
					label: L.untranslated("Settings"),
					cb: ()->JsTools.locateFile(Settings.getDir(), false)
				});

				addAction({
					label: L.untranslated("Log file"),
					cb: ()->JsTools.locateFile(JsTools.getLogPath(), true)
				});
		}

	}
}