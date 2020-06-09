package data;

interface ISerializable {
	public function clone() : ISerializable;
	public function toJson() : Dynamic;
}