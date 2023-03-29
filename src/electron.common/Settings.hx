import electron.renderer.IpcRenderer;
#if editor
import EditorTypes;
#end

typedef AppSettings = {
	var lastKnownVersion: Null<String>;

	var compactMode : Bool;
	var grid : Bool;
	var singleLayerMode : Bool;
	var emptySpaceSelection : Bool;
	var tileStacking : Bool;
	var tileEnumOverlays : Bool;
	var showDetails : Bool;
	var useBestGPU : Bool;
	var startFullScreen: Bool;
	var autoInstallUpdates : Bool;
	var colorBlind : Bool;
	var navigationKeys : NavigationKeys;

	var openLastProject : Bool;
	var lastProject : Null<{ filePath:String, levelUid:Int }>;

	var appUiScale : Float;
	var editorUiScale : Float;
	var mouseWheelSpeed : Float;
	var autoWorldModeSwitch : AutoWorldModeSwitch;
	var fieldsRender : FieldsRender;

	var recentProjects : Array<String>;
	var recentDirs : Array<String>;

	var uiStates : Array<{ id:String, val:Int }>;
	var lastUiDirs : Array<{ ?project:String, uiId:String, path:String }>;
	var projectTrusts : Array<{ iid:String, trusted:Bool }>;
}

enum abstract UiState(String) {
	var ShowProjectColors;
	var HideSamplesOnHome;
}

/* Notes: Settings related enums are stored in this file instead of EditorTypes to avoid Main compilation to reach unwanted classes, by importing EditorTypes. */

enum NavigationKeys {
	Arrows;
	Wasd;
	Zqsd;
}

enum AutoWorldModeSwitch {
	Never;
	ZoomOutOnly;
	ZoomInAndOut;
}

enum FieldsRender {
	FR_Outline;
	FR_Table;
}


class Settings {
	var defaults : AppSettings;
	public var v : AppSettings;
	var ls : dn.data.LocalStorage;

	public function new() {
		// Init storage
		ls = dn.data.LocalStorage.getJsonStorage("settings", Full);
		ls.setStorageFileDir( getDir() );

		// Init defaults
		defaults = {
			lastKnownVersion: null,
			recentProjects: [],
			recentDirs: null,

			compactMode: false,
			grid: true,
			singleLayerMode: false,
			emptySpaceSelection: true,
			tileStacking: true,
			tileEnumOverlays : false,
			showDetails: true,
			useBestGPU: true,
			startFullScreen: false,
			autoInstallUpdates: true,
			colorBlind: false,
			navigationKeys: null,

			openLastProject: false,
			lastProject: null,

			autoWorldModeSwitch: ZoomInAndOut,
			fieldsRender: FR_Outline,
			appUiScale: 1.0,
			editorUiScale: 1.0,
			mouseWheelSpeed: 1.0,

			uiStates: [],
			lastUiDirs: [],
			projectTrusts: [],
		}

		// Load
		v = ls.readObject(defaults, (obj)->{
			#if editor
			// Migrate old NavKeys string value
			if( obj.navKeys!=null ) {
				var e = try NavigationKeys.createByName( obj.navKeys ) catch(_) null;
				if( e!=null )
					obj.navigationKeys = e;
			}
			#end
		});

		// Try to guess Navigation keys
		#if editor

		if( v.navigationKeys==null ) {
			for(full in js.Browser.navigator.languages) {
				switch full {
					case "nl-be": v.navigationKeys = Zqsd; break;
				}

				var short = ( full.indexOf("-")<0 ? full : full.substr(0,full.indexOf("-")) ).toLowerCase();
				switch short {
					case "fr": v.navigationKeys = Zqsd; break;
					case "en": v.navigationKeys = Wasd; break;
					case _:
				}
			}
			if( v.navigationKeys==null )
				v.navigationKeys = Wasd;
		}
		#end


		if( !hasUiState(ShowProjectColors) )
			setUiStateBool(ShowProjectColors, true);
	}


	public function setProjectTrust(projectIid:String, trust:Bool) {
		clearProjectTrust(projectIid);
		v.projectTrusts.push({
			iid: projectIid,
			trusted: trust,
		});
		save();
	}


	public function clearProjectTrust(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid ) {
				v.projectTrusts.remove(tp);
				break;
			}
		save();
	}

	public function isProjectTrusted(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid && tp.trusted )
				return true;
		return false;
	}

	public function isProjectUntrusted(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid && !tp.trusted )
				return true;
		return false;
	}

	public function wasProjectTrustAsked(projectIid:String) {
		for(tp in v.projectTrusts)
			if( tp.iid==projectIid )
				return true;
		return false;
	}


	function getOrCreateUiState(id:UiState) {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s;
		v.uiStates.push({ id:Std.string(id), val:0 });
		return v.uiStates[v.uiStates.length-1];
	}

	public function hasUiState(id:UiState) {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return true;
		return false;
	}

	function deleteUiState(id:UiState) {
		var i = 0;
		while( i<v.uiStates.length )
			if( v.uiStates[i].id==Std.string(id) )
				v.uiStates.splice(i,1);
			else
				i++;
	}

	public inline function setUiStateInt(id:UiState, v:Int) {
		getOrCreateUiState(id).val = v;
		save();
	}

	public inline function setUiStateBool(id:UiState, v:Bool) {
		setUiStateInt(id, v==true ? 1 : 0);
		save();
	}

	public inline function toggleUiStateBool(id:UiState) {
		setUiStateBool(id, !getUiStateBool(id));
		save();
	}

	public function getUiStateInt(id:UiState) : Int {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s.val;
		return 0;
	}

	public function getUiStateBool(id:UiState) : Bool {
		for(s in v.uiStates)
			if( s.id==Std.string(id) )
				return s.val!=0;
		return false;
	}


	#if editor
	public function storeUiDir(?project:data.Project, uiId:String, path:String) {
		var projectPath = project==null ? null : dn.FilePath.convertToSlashes(project.filePath.full);
		path = dn.FilePath.convertToSlashes(path);
		for(dir in v.lastUiDirs)
			if( ( projectPath==null || dir.project==projectPath ) && dir.uiId==uiId ) {
				dir.path = path;
				save();
				return;
			}

		if( project==null )
			v.lastUiDirs.push({ uiId:uiId, path:path });
		else
			v.lastUiDirs.push({ project:projectPath, uiId:Std.string(uiId), path:path });
		save();
	}
	#end


	#if editor
	public function getUiDir(?project:data.Project, uiId:String, ?defaultIfNotSet:String) : Null<String> {
		var projectPath = project==null ? null : dn.FilePath.convertToSlashes(project.filePath.full);

		if( defaultIfNotSet==null && project!=null )
			defaultIfNotSet = dn.FilePath.convertToSlashes(project.filePath.directory);

		for(dir in v.lastUiDirs)
			if( ( projectPath==null || dir.project==projectPath ) && dir.uiId==uiId )
				return dir.path;

		return defaultIfNotSet;
	}
	#end

	static inline function isRenderer() {
		return electron.main.App==null;
	}

	public function getAppZoomFactor() : Float {
		// var w = dn.js.ElectronTools.getScreenWidth();
		// var h = dn.js.ElectronTools.getScreenHeight();
		// return v.appUiScale * dn.M.fmax(1, dn.M.fmin( w/1350, h/1024 ) );
		return v.appUiScale; // HACK disabled base scaling
	}


	public static function getDir() {
		var path = isRenderer()
			?	#if debug	dn.js.ElectronTools.getAppResourceDir()
				#else		dn.js.ElectronTools.getUserDataDir() #end
			:	#if debug	electron.main.App.getAppPath();
				#else		electron.main.App.getPath("userData"); #end
		return dn.FilePath.fromDir( path+"/settings" ).useSlashes().directory;
	}

	public function toString() {
		return Std.string( v );
	}

	public function save() {
		ls.writeObject(v);
	}
}