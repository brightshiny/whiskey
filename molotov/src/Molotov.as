package 
{
	import flare.data.DataSet;
	import flare.display.TextSprite;
	import flare.util.Filter;
	import flare.vis.Visualization;
	import flare.vis.controls.DragControl;
	import flare.vis.controls.PanZoomControl;
	import flare.vis.data.Data;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.layout.RadialTreeLayout;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.*;
	import flash.text.TextFormat;
	
	/**
	 * good luck 
	 */
	
	[SWF(width="600", height="400", backgroundColor="#ffffff", frameRate="30")]
	public class Molotov extends Sprite
	{
		
	 
		private var vis:Visualization;
				
		public function Molotov() {
			var gmr:GraphMLReader = new GraphMLReader(onLoaded);
			var meme_id:String = root.loaderInfo.parameters.meme_id;
			var url:String = "http://localhost:3000/meme/show/" + meme_id + ".xml";
			gmr.read(url);
		}
			
		
		private function onLoaded(data:Data):void {

			vis = new Visualization(data);
			
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			
			vis.bounds = new Rectangle(0, 0, w, h);
			
			var textFormat:TextFormat = new TextFormat();
			textFormat.color = 0xffffffff;
			textFormat.size  = 10;
			textFormat.font = "Arial";
			
			vis.data.nodes.visit(function(ns:NodeSprite):void { 
//				var ts:TextSprite = new TextSprite(ns.data.name,textFormat);	
//				ts.horizontalAnchor = TextSprite.CENTER; 
//				ts.verticalAnchor = TextSprite.MIDDLE; 
//				ts.textField.background  = true;
//				ts.textField.backgroundColor = 0xff990022;
//				ns.addChild(ts);
				var ts:TextSprite = new TextSprite(ns.data.item_id,textFormat);
				ts.horizontalAnchor = TextSprite.CENTER; 
				ts.verticalAnchor = TextSprite.MIDDLE; 
				ns.addChild(ts);	
				ns.size = 4;	
				ns.fillColor = 0xcccccccc;
				ns.lineColor = 0xcccccccc;
				ns.alpha = 1.0;
				ns.buttonMode = true;
				ns.doubleClickEnabled = true;
				ns.addEventListener(MouseEvent.DOUBLE_CLICK, function(evt:Event):void {
					var u:URLRequest = new URLRequest(ns.data.link);
					navigateToURL(u,"_blank");
				});
				ns.addEventListener(MouseEvent.MOUSE_OVER, function(evt:Event):void {
					ns.fillColor = 0xff990022;
					ns.lineColor = 0xff990022;
					ns.visitEdges(function(e:EdgeSprite):void {
						e.lineColor = 0xff990022;
						e.lineAlpha = 0.5;
					}, NodeSprite.ALL_LINKS);
				});
				ns.addEventListener(MouseEvent.MOUSE_OUT, function(evt:Event):void {
					ns.fillColor = 0xcccccccc;
					ns.lineColor = 0xcccccccc;
					ns.visitEdges(function(e:EdgeSprite):void {
						e.lineColor = 0xcccccccc;
						e.lineAlpha = 0.5;
					}, NodeSprite.ALL_LINKS);
				});
				
				ns.mouseChildren = false;
			});
			
		   	
		   var minWeight:Number = 1000000;
		   var maxWeight:Number = 0;
		
			vis.data.edges.visit(function(es:EdgeSprite):void {
				
				es.lineWidth = 2;
				es.lineColor = 0xefefefef;
				es.alpha = 0.5;
					
				if (es.data.weight > maxWeight) {
					maxWeight  = es.data.weight;
				}
				if (es.data.weight < minWeight) {
					minWeight = es.data.weight;
				}
			});
			
//			vis.marks.x = w / 2;
//			vis.marks.y = h / 2;
//			var fdl:ForceDirectedLayout = new ForceDirectedLayout();	
//			fdl.restLength = function(es:EdgeSprite):Number {
//				var minEdgeLength:int = 50;
//				var maxEdgeLength:int = 300;
//				return minEdgeLength + (maxEdgeLength - minEdgeLength) * (es.data.weight - minWeight)/(maxWeight - minWeight) ;
//			}	
//			vis.continuousUpdates = true;				

			vis.marks.x = 0;
			vis.marks.y = 0;
			var fdl:RadialTreeLayout = new RadialTreeLayout();
			fdl.autoScale = true;
			fdl.layoutBounds = new Rectangle(30, 30, w-30, h-30);
			fdl.layoutAnchor = new Point(w/2,h/2);
			vis.continuousUpdates = false;
			
//			vis.marks.x = 0;
//			vis.marks.y = 0;
//			var fdl:CircleLayout = new CircleLayout();
//			fdl.startRadius = 400;
//			fdl.startRadiusFraction = 1;
//			fdl.treeLayout = true;
//			vis.continuousUpdates = false;
//			vis.update();
			
			vis.controls.add(new DragControl(Filter.typeChecker(NodeSprite)));
			vis.controls.add(new PanZoomControl());
			
			vis.operators.add(fdl);
			
			addChild(vis);
			vis.update();
			
										
			
		}
	
	}
		
}	

/** 
 * simple graphml reader utility
 * 
 */ 
import flare.data.converters.GraphMLConverter;
import flare.data.DataSet;
import flash.events.*;
import flash.net.*;
import flare.vis.data.Data;
class GraphMLReader {
	public var onComplete:Function;

    public function GraphMLReader(onComplete:Function=null,file:String = null) {
        this.onComplete = onComplete;

		if(file != null) {
			read(file);
		}
    }
	public function read(file:String):void {
		if ( file != null) {
			var loader:URLLoader = new URLLoader();
			configureListeners(loader);
			var request:URLRequest = new URLRequest(file);
			try {
				loader.load(request);
			} catch (error:Error) {
				trace("Unable to load requested document.");
			
			}
		}
	}
    private function configureListeners(dispatcher:IEventDispatcher):void {
        dispatcher.addEventListener(Event.COMPLETE, completeHandler);
        dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
        dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
    }
    private function completeHandler(event:Event):void {  
		if (onComplete != null) {
			var loader:URLLoader = event.target as URLLoader;
			var dataSet:DataSet = new GraphMLConverter().parse(new XML(loader.data));
			onComplete(Data.fromDataSet(dataSet));
		} else {
			trace("No onComplete function specified.");
		}
    }
    private function securityErrorHandler(event:SecurityErrorEvent):void {
        trace("securityErrorHandler: " + event);
    }
    private function ioErrorHandler(event:IOErrorEvent):void {
        trace("ioErrorHandler: " + event);
    }
}


