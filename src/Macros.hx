class Macros {
	#if macro
	public static function dumpVersionToFile() {
		sys.io.File.saveContent("buildVersion.txt", Const.getAppVersion());
	}
	#end
}