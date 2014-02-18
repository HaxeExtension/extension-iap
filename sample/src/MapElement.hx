package ;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;

class MapElement extends Sprite
{
	var bmp:Bitmap;
	
	public var id(default, null):String;
	public var type(default, null):String;
	public var skin(default, set):BitmapData;
	public var skinId:String;
	public var empty:Bool = true;
	public var level:Int = 1;
	
	public function new(id:String, ty:String) 
	{
		super();
		bmp = new Bitmap();
		addChild(bmp);
		
		this.id = id;
		this.type = ty;
	}
	
	// Getter / Setter methods
	
	function set_skin(val:BitmapData):BitmapData {
		bmp.bitmapData = val;
		bmp.x = -bmp.width / 2;
		bmp.y = -bmp.height / 2;
		return val;
	}
	
}