package data;

interface IData {
	public function clone() : IData;
	public function toJson() : Dynamic;
}