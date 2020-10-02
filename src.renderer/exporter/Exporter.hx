package exporter;

import led.Json;

class Exporter {
	var log : dn.Log;
	var p : led.Project;
	var projectPath : dn.FilePath;
	var outputPath : Null<dn.FilePath>;

	private function new() {
		log = new dn.Log(500);
	}

	public function run(p:led.Project, projectFilePath:String) {
		this.p = p;
		projectPath = dn.FilePath.fromFile(projectFilePath);

		if( outputPath==null ) {
			outputPath = projectPath.clone();
			outputPath.fileWithExt = null;
		}

		log.general("Converting project ("+Type.getClassName(Type.getClass(this))+")...");
		log.fileOp('Project: ${projectPath.full}');
		log.fileOp('Output: ${outputPath.full}');
	}

	public function setOutputPath(dirPath:String, removeAllFilesInDir:Bool) {
		outputPath = dn.FilePath.fromDir(dirPath);
		JsTools.createDir(outputPath.full);
		if( removeAllFilesInDir )
			JsTools.emptyDir(outputPath.full);
	}

	function remapRelativePath(relPath:String) : String {
		var fp = dn.FilePath.fromFile(relPath);
		if( fp.hasDriveLetter() )
			return relPath; // it's actually an absolute path

		var abs = dn.FilePath.fromFile( projectPath.directory + "/" + relPath );
		return abs.makeRelativeTo( outputPath.full ).full;
	}

}
