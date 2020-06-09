package data;

class LevelData implements data.IData {
	public var layerInstances : Array<LayerInstance> = [];

	public var uid(default,null) : Int;
	public var pxWid : Int = 512;
	public var pxHei : Int = 256;


	@:allow(data.ProjectData)
	private function new(uid:Int) {
		this.uid = uid;
	}

	@:allow(data.ProjectData)
	function initLayersUsingProject(p:ProjectData) {
		layerInstances = [];
		for(def in p.layerDefs)
			layerInstances.push( new LayerInstance(this, def) );
	}

	@:keep public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function clone() {
		var e = new LevelData(uid);
		return e;
	}

	public function toJson() {
		return {
		}
	}

	public function getLayerInstance(layerDefId:Int) : Null<LayerInstance> {
		for(li in layerInstances)
			if( li.layerDefId==layerDefId )
				return li;
		return null;
	}

	public function tidy(project:ProjectData) {
		// Remove layerInstances without layerDefs
		var i = 0;
		while( i<layerInstances.length ) {
			if( layerInstances[i].def==null )
				layerInstances.splice(i,1);
			else
				i++;
		}

		// Add missing layerInstances
		for(ld in project.layerDefs)
			if( getLayerInstance(ld.uid)==null )
				layerInstances.push( new LayerInstance(this, ld) );

		// Layer instances content
		for(li in layerInstances)
			li.tidy(project);
	}
}
