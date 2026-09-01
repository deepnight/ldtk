package misc;

/**
 * Hooks LDtk's existing image file dialog so choosing .aseprite/.ase opens the
 * layer picker before the normal image-picker callback receives a path.
 * Non-Aseprite image picking is untouched.
 */
class AsepriteImportInterceptor {
	static var installed = false;

	public static function install() {
		if( installed )
			return;
		installed = true;

		var originalOpenFile:Dynamic = untyped dn.js.ElectronDialogs.openFile;
		untyped dn.js.ElectronDialogs.openFile = function(extensions:Array<String>, initialPath:String, onPick:Dynamic) {
			var acceptsAseprite = extensions!=null && (extensions.contains(".aseprite") || extensions.contains(".ase"));
			if( !acceptsAseprite ) {
				originalOpenFile(extensions, initialPath, onPick);
				return;
			}

			originalOpenFile(extensions, initialPath, function(absPath:String) {
				if( absPath==null || !AsepriteTools.isAsepritePath(absPath) ) {
					onPick(absPath);
					return;
				}

				var project = try Editor.ME.project catch(_) null;
				if( project==null ) {
					onPick(absPath);
					return;
				}

				var layers = AsepriteTools.listLayers(absPath);
				if( layers==null || layers.length==0 ) {
					new ui.modal.dialog.Warning(Lang.untranslated(
						"LDtk could not read the Aseprite layer list. Layer-selective importing requires the Aseprite application/CLI to be installed and accessible."
					));
					return;
				}

				var relSourcePath = project.makeRelativeFilePath(absPath);
				new ui.modal.dialog.AsepriteLayerPicker(relSourcePath, layers, selectedLayers->{
					try {
						var generatedRelPath = AsepriteTools.exportSelectedLayers(project, relSourcePath, selectedLayers);
						var generatedAbsPath = project.makeAbsoluteFilePath(generatedRelPath);
						onPick(generatedAbsPath);

						// createImagePicker stores the directory of the path passed to its
						// callback. Restore the artist source directory so the next import
						// doesn't open inside .ldtk-aseprite.
						App.ME.settings.storeUiDir(
							project,
							"PickImage",
							dn.FilePath.extractDirectoryWithoutSlash(absPath,true)
						);
						N.success('Imported ${selectedLayers.length} Aseprite layer${selectedLayers.length==1 ? "" : "s"}.');
					}
					catch(e:Dynamic) {
						App.LOG.error(e);
						new ui.modal.dialog.Warning(Lang.untranslated("Aseprite layer import failed:\n\n"+Std.string(e)));
					}
				});
			});
		};
	}
}
