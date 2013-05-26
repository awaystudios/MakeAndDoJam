/*

AWD file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal awd model.
How to create character interaction
How to set custom material on a model.

Code by Rob Bateman and LoTh
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

Model and Map by LoTH
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
package
{
	import away3d.cameras.lenses.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.loaders.*;
	import away3d.loaders.parsers.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	
	
	[SWF(backgroundColor="#333338", frameRate="60", quality="LOW")]
	public class GlobeTheatre_Demo extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//engine variables
		private var _view:View3D;
		private var _signature:Sprite;
		private var _stats:AwayStats;
		private var _cameraController:HoverController;
		
		//navigation
		private var _prevMouseX:Number;
		private var _prevMouseY:Number;
		private var _mouseMove:Boolean;
		private var _cameraHeight:Number = 0;
		
		private var _eyePosition:Vector3D;
		private var cloneActif:Boolean = false;
		private var _text:TextField;
		
		private var meshOffset:Number = 500;
		private var meshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var meshFloor:Number;
		private var ready:Boolean;
		private var done:Boolean;
		private var cameraReset:Boolean;
		
		/**
		 * Constructor
		 */
		public function GlobeTheatre_Demo()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initText();
			initListeners();
			
			AssetLibrary.enableParser(AWD2Parser);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			
			//kickoff asset loading
			var loader:Loader3D = new Loader3D();
			loader.y = -200;
			loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			loader.load(new URLRequest("assets/globe4.awd"));
			
			_view.scene.addChild(loader);
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//create the view
			_view = new View3D();
			_view.backgroundColor = 0x333338;
			addChild(_view);
			
			//create custom lens
			_view.camera.lens = new PerspectiveLens(70);
			_view.camera.lens.far = 30000;
			_view.camera.lens.near = 1;
			
			//setup controller to be used on the camera
			_cameraController = new HoverController(_view.camera, null, 45, 90, 1000, -90, 90);
			_cameraController.autoUpdate = false;
			
			//add signature
			addChild(_signature = new SignatureSwf());
			
			//add stats
			addChild(_stats = new AwayStats(_view, true, true));
		}
		
		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			_text = new TextField();
			_text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			_text.embedFonts = true;
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.PIXEL;
			_text.width = 300;
			_text.height = 250;
			_text.selectable = false;
			_text.mouseEnabled = true;
			_text.wordWrap = true;
			_text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			addChild(_text);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			//add render loop
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			//navigation
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseLeave);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onStageMouseWheel);
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
			
			//add resize event
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onResourceComplete(event:LoaderEvent):void
		{
			ready = true;
		}
		
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				trace(event.asset.name);
				meshes.push(event.asset);
				(event.asset as Mesh).visible = false;
				switch(event.asset.name) {
					case "mesh2_mesh2-geometry":
					case "mesh7_mesh7-geometry":
					case "mesh8_mesh8-geometry":
					case "mesh9_mesh9-geometry":
					case "mesh10_mesh10-geometry":
					case "mesh11_mesh11-geometry":
					case "mesh12_mesh12-geometry":
					case "mesh15_mesh15-geometry":
						(event.asset as Mesh).y = meshOffset*8;
						break;
					case "mesh3_mesh3-geometry":
					case "mesh4_mesh4-geometry":
					case "mesh5_mesh5-geometry":
					case "mesh6_mesh6-geometry":
						(event.asset as Mesh).y = meshOffset*7;
						break;
					case "mesh13_mesh13-geometry":
						(event.asset as Mesh).y = meshOffset*6;
						break;
					case "mesh1.002_mesh1-geometry":
						(event.asset as Mesh).y = meshOffset*5;
						break;
					case "mesh1.001_mesh1-geometry":
						(event.asset as Mesh).y = meshOffset*4;
						break;
					case "mesh13_mesh13-geometry":
						(event.asset as Mesh).y = meshOffset*3;
						break;
					case "mesh14_mesh14-geometry":
						(event.asset as Mesh).y = meshOffset*2;
						break;
					case "mesh16_mesh16-geometry":
						(event.asset as Mesh).y = meshOffset;
						break;
					case "Mesh1":
						meshFloor = 0;//(event.asset as Mesh).y;
						(event.asset as Mesh).visible = true;
						break;
					default:
				}
			}
		}
		
		/**
		 * Render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			_cameraController.update();
			
			if (_view.camera.y < 0)
				_view.camera.y = 0;
			//update view
			_view.render();
			
			if (ready) {
				if (!cameraReset) {
					cameraReset = true;
					_cameraController.panAngle = 5;
					_cameraController.tiltAngle = -10;
				}
				if (!done) {
					_cameraController.distance += (100 - _cameraController.distance)/20
					_cameraController.panAngle += 1;
					var mesh:Mesh;
					var isDone:Boolean = true;
					for each (mesh in meshes) {
						mesh.visible = true;
						if (mesh.y > meshFloor && mesh.name != "Mesh1") {
							mesh.y -= 10;
							isDone = false;
						}
						
						if (mesh.y < meshFloor)
							mesh.y = meshFloor;
					}
					
					done = isDone;
				}
			} else {
			}
		}
		
		
		/**
		 * stage listener and mouse control
		 */
		private function onResize(event:Event=null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
			_stats.x = stage.stageWidth - _stats.width;
			_signature.y = stage.stageHeight - _signature.height;
		}
		
		private function onStageMouseDown(ev:MouseEvent):void
		{
			_prevMouseX = ev.stageX;
			_prevMouseY = ev.stageY;
			_mouseMove = true;
		}
		
		private function onStageMouseLeave(event:Event):void
		{
			_mouseMove = false;
		}
		
		private function onStageMouseMove(ev:MouseEvent):void
		{
			if (_mouseMove) {
				_cameraController.panAngle += (ev.stageX - _prevMouseX);
				_cameraController.tiltAngle += (ev.stageY - _prevMouseY);
			}
			_prevMouseX = ev.stageX;
			_prevMouseY = ev.stageY;
		}
		
		/**
		 * mouseWheel listener
		 */
		private function onStageMouseWheel(ev:MouseEvent):void
		{
			_cameraController.distance -= ev.delta * 5;
			
			_cameraHeight = (_cameraController.distance < 600)? (600 - _cameraController.distance)/2 : 0;
			
			if (_cameraController.distance < 100)
				_cameraController.distance = 100;
			else if (_cameraController.distance > 4000)
				_cameraController.distance = 4000;
		}
	}
}
import away3d.cameras.lenses.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.loaders.*;
import away3d.loaders.parsers.*;
import away3d.materials.methods.*;

import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.geom.*;
import flash.net.*;
import flash.text.*;

