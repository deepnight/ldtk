import haxe.DynamicAccess;

class Castle {
    public var json:DynamicAccess<Dynamic>;

    public function new(project:data.Project) {
        var levelDir = project.getAbsExternalFilesDir();
		// this.json = cast(NT.readFileString(levelDir + "castle.cdb"), DynamicAccess);
    }
}