package
{
	import flare.data.DataSet;
	import flare.display.DirtySprite;
	import flare.display.TextSprite;
	import flare.query.methods.eq;
	import flare.vis.Visualization;
	import flare.vis.data.Data;
	import flare.vis.data.DataSprite;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.data.Tree;
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
	
	[SWF(width="1000", height="1000", backgroundColor="#ffffff", frameRate="30")]
	public class Dependency extends Sprite 
	{
		/** We will be rotating text, so we embed the font. */
		[Embed(systemFont="Helvetica", fontName="Helvetica", advancedAntiAliasing="true", mimeType="application/x-font")]
		private static var _font:Class;
			
		private var _vis:Visualization;
		private var _detail:TextSprite;
		private var _legend:Legend;
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
			    url = "http://localhost:3000/runs/show/" + run_id + ".xml";
			} else if (root.loaderInfo.parameters.meme_id) {
				var meme_id:String = root.loaderInfo.parameters.meme_id;
			    url = "http://localhost:3000/meme/show/" + meme_id + ".xml";
			}
			trace(url);
			gmr.read(url);
  		}
  		
  		function visualize(data:Data):void
		{
			// TODO: Sorting!
			data.nodes.visit(function(ns:NodeSprite):void {
				ns.size = 0;
			});
			
			data.edges.visit(function(es:EdgeSprite):void {
				es.lineWidth = 0.25;
				es.lineColor = 0xff990000;
				// es.lineAlpha = 0.25;
				es.lineAlpha = 1.0 / (Math.pow(es.data.weight, 10));
				trace(es.lineAlpha);
				es.mouseEnabled = false;
				es.visible = true;
			});
						
			// define the visualization
			_vis = new Visualization(data);
			
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			
			// place around circle by tree structure, radius mapped to depth
			// make a large inner radius so labels are closer to circumference
			// var c:CircleLayout = new CircleLayout("depth", null, true); 
			var c:CircleLayout = new CircleLayout(null, null, false); 
			_vis.operators.add(c);
			c.startRadiusFraction = 1;
			// c.startRadiusFraction = 1; // centers graph
			c.layoutAnchor = new Point(w/2.0,h/2.0);
			var padding:Number = 150;
			c.layoutBounds = new Rectangle(padding,padding,w-padding,h-padding);
			
			// bundle edges to route along the tree structure
			_vis.operators.add(new BundledEdgeRouter(0.6));
			
			// add labels	
			_vis.operators.add(new RadialLabeler(
				// custom label function removes package names
				function(d:DataSprite):String {
					var txt:String = d.data.name;
					return txt.substring(txt.lastIndexOf('.')+1);
				}, true, _fmt)); // leaf nodes only
			_vis.operators.last.textMode = TextSprite.EMBED; // embed fonts!
			
			// update and add
			_vis.update();
			addChild(_vis);
			
			// show all dependencies on single-click
			var linkType:int = NodeSprite.OUT_LINKS;
			// compute the layout
			if (_bounds) resize(_bounds);
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
				_vis.data.nodes.setProperty("props.label.size",
					(d <= 650 ? 7 : d <= 725 ? 8 : 9),
					null, eq("childDegree",0));
				
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
		
		// --------------------------------------------------------------------
		
		/**
		 * Creates the visualized data.
		 */
		function buildData(tuples:Array):Data
		{
			var data:Data = new Data();
			var tree:Tree = new Tree();
			var map:Object = {};
			
			tree.root = data.addNode({name:"flare", size:0});
			map.flare = tree.root;
			
			var t:Object, u:NodeSprite, v:NodeSprite;
			var path:Array, p:String, pp:String, i:uint;
			
			// build data set and tree edges
			tuples.sortOn("name");
			for each (t in tuples) {
				path = String(t.name).split(".");
				for (i=0, p=""; i<path.length-1; ++i) {
					pp = p;
					p += (i?".":"") + path[i];
					if (!map[p]) {
						u = data.addNode({name:p, size:0});
						tree.addChild(map[pp], u);
						map[p] = u;
					}
				}
				t["package"] = p;
				u = data.addNode(t);
				tree.addChild(map[p], u);
				map[t.name] = u;
			}
			
			// create graph links
			for each (t in tuples) {
				u = map[t.name];
				for each (var name:String in t.imports) {
					v = map[name];
					if (v) data.addEdgeFor(u, v);
					else trace ("Missing node: "+name);
				}
			}
			
			// sort the list of children alphabetically by name
			for each (u in tree.nodes) {
				u.sortEdgesBy(NodeSprite.CHILD_LINKS, "target.data.name");
			}
			
			data.tree = tree;
			return data;
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



