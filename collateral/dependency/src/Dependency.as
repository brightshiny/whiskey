package
{
	import flare.data.DataSet;
	import flare.display.DirtySprite;
	import flare.display.TextSprite;
	import flare.vis.Visualization;
	import flare.vis.controls.HoverControl;
	import flare.vis.data.Data;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.events.SelectionEvent;
	import flare.vis.legend.Legend;
	import flare.vis.operator.label.RadialLabeler;
	import flare.vis.operator.layout.BundledEdgeRouter;
	import flare.vis.operator.layout.CircleLayout;
	import flare.widgets.ProgressBar;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextFormat;
	
	[SWF(width="600", height="600", backgroundColor="#ffffff", frameRate="30")]
	public class Dependency extends Sprite 
	{
		/** We will be rotating text, so we embed the font. */
		[Embed(systemFont="Helvetica", fontName="Helvetica", advancedAntiAliasing="true", mimeType="application/x-font")]
		private static var _font:Class;
			
		private var _vis:Visualization;
		private var _bar:ProgressBar;
		private var _bounds:Rectangle;
		
		private var _fmt:TextFormat = new TextFormat("Helvetica", 10);
		private var _focus:NodeSprite;
		
		public function Dependency() {
		{	
			var gmr:GraphMLReader = new GraphMLReader(visualize);
			var url:String = "";
			if (root.loaderInfo.parameters.run_id) {
			    var run_id:String = root.loaderInfo.parameters.run_id;
			    // url = "http://localhost:3000/runs/show/" + run_id + ".xml";
			    url = "http://refinr.com/runs/show/" + run_id + ".xml";
			} else if (root.loaderInfo.parameters.meme_id) {
				var meme_id:String = root.loaderInfo.parameters.meme_id;
			    // url = "http://localhost:3000/meme/show/" + meme_id + ".xml";
			    url = "http://refinr.com/meme/show/" + meme_id + ".xml";
			}
			trace(url);
			gmr.read(url);
  		}
  		
  		function visualize(data:Data):void
		{
			data.nodes.visit(function(ns:NodeSprite):void {
				ns.size = 0;
				ns.buttonMode = true;
			});
			
			data.edges.visit(function(es:EdgeSprite):void {
				es.lineWidth = 0.25;
				es.lineColor = 0xff888899;
				es.lineAlpha = computeLineAlpha(es);
				es.mouseEnabled = false;
				es.visible = true;
			});
						
			_vis = new Visualization(data);
			
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			
			// place around circle by tree structure, radius mapped to depth
			var c:CircleLayout = new CircleLayout(null, null, false); 
			c.layoutAnchor = new Point(w/2.0,h/2.0);
			var padding:Number = 150;
			c.layoutBounds = new Rectangle(padding,padding,w-padding,h-padding);
			_vis.operators.add(c);
			
			// sets a base "height" for the curves to extend to the center of the graph
			_vis.operators.add(new BundledEdgeRouter(0.7));
			
			// add labels
			var rl:RadialLabeler = new RadialLabeler(function(ns:NodeSprite):String { var txt:String = ns.data.name; return txt; }, true, _fmt, null);	
			_vis.operators.add(rl); 
			_vis.operators.last.textMode = TextSprite.EMBED; // embed fonts!
			
			// update and add
			_vis.update();
			addChild(_vis);
			
			var hov:HoverControl = new HoverControl(NodeSprite, HoverControl.DONT_MOVE, highlight, unhighlight);
			_vis.controls.add(hov);

			// compute the layout
			if (_bounds) resize(_bounds);
		}
		
		
	    /** Add highlight to a node and connected edges/nodes */
		function highlight(evt:SelectionEvent):void
		{
			evt.node.size = 1.0;
			evt.node.alpha = 1.0;
			evt.node.lineAlpha = 0.0;
			evt.node.fillColor = 0xffcc0000;
			evt.node.visitEdges(function(e:EdgeSprite):void {
				e.lineColor = 0xffcc0000;
				e.lineAlpha = computeLineAlpha(e);
				if(e.target != evt.node) {
					e.target.size = 0.5;
					e.target.lineAlpha = 0.0;
				    e.target.fillColor = 0xffcc0000;
				    e.target.alpha = computeLineAlpha(e);
				}
			}, NodeSprite.ALL_LINKS);
		}
		
		function unhighlight(evt:SelectionEvent):void
		{
			evt.node.size = 0;
			evt.node.visitEdges(function(e:EdgeSprite):void {
				e.lineColor = 0xff888899;
				e.lineAlpha = computeLineAlpha(e);
				e.target.size = 0;
				e.target.alpha = 1.0;
			}, NodeSprite.ALL_LINKS);
		}
		
		/** Remove highlight from a node and connected edges/nodes */
		function clickUnnhighlight(n:*):void
		{
			var node:NodeSprite = n is NodeSprite ? NodeSprite(n) : SelectionEvent(n).node;
			n.visitEdges(function(e:EdgeSprite):void {
				e.lineColor = 0xff888899;
				e.lineAlpha = computeLineAlpha(e);
			}, NodeSprite.ALL_LINKS);
		}

		function computeLineAlpha(e:EdgeSprite):Number {
			return 1.0 / (Math.pow(e.data.weight, 8));
		}
		
		function resize(bounds:Rectangle):void
		{
			_bounds = bounds;
			if (_bar) {
				_bar.x = _bounds.width/2 - _bar.width/2;
				_bar.y = _bounds.height/2 - _bar.height/2;
			}
			if (_vis) {
				// automatically size labels based on bounds
				var d:Number = Math.min(_bounds.width, _bounds.height);
				
				// compute the visualization bounds
				_vis.bounds.x = _bounds.x;
				_vis.bounds.y = _bounds.y;
				_vis.bounds.width = _bounds.width;
				_vis.bounds.height = _bounds.height;
				// update
				_vis.update();
				
				// forcibly render to eliminate partial update bug, as
				// the standard RENDER event routing can get delayed.
				// remove this line for faster but unsynchronized resizes
				DirtySprite.renderDirty();
			}
		}
		
		}
	} // end of class DependencyGraph
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



