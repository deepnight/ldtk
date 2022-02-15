package electronUpdater;

typedef UpdateInfo = {
	/**
	* The version.
	*/
	var version: String;
	var files: Array<Dynamic>;

	/**
	* The release name.
	*/
	var ?releaseName: Null<String>;

	/**
	* The release notes. List if `updater.fullChangelog` is set to `true`, `string` otherwise.
	*/
	var ?releaseNotes: Null< haxe.extern.EitherType<String, Array<Dynamic>> >;

	/**
	* The release date.
	*/
	var releaseDate: String;

	/**
	* The [staged rollout](/auto-update#staged-rollouts) percentage, 0-100.
	*/
	var ?stagingPercentage: Int;
}

extern class AutoUpdater {
	public function checkForUpdates() : Dynamic;
	public function on(eventId:String, onEvent:UpdateInfo->Void) : Dynamic;
	public function quitAndInstall(isSilent:Bool=false, isForceRunAfter:Bool=false) : Dynamic;

	/** Expected values: latest/null, beta or alpha **/
	public var channel : Null<String>;
}