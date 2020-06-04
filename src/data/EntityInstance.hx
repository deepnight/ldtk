package data;

class EntityInstance {
	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return Client.ME.project.getEntityDef(defId);

	public var x : Int;
	public var y : Int;


	public function new(def:EntityDef) {
		defId = def.uid;
	}
}