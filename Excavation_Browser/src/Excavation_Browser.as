/*

Terrain creation using height maps and splat maps

Demonstrates:

How to create a 3D terrain out of a hieght map
How to enhance the detail of a material close-up by applying splat maps.
How to create a realistic lake effect.
How to create first-person camera motion using the FirstPersonController.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

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
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.extrusions.*;
	import away3d.materials.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	
	[SWF(backgroundColor="#000000", width="1280", height="720", frameRate="30", quality="LOW")]
	
	public class Excavation_Browser extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		// Environment map.
		//skybox textures
		[Embed(source="/../embeds/skybox/sky_posX.jpg")]
		private var PosX:Class;
		[Embed(source="/../embeds/skybox/sky_negX.jpg")]
		private var NegX:Class;
		[Embed(source="/../embeds/skybox/sky_posY.jpg")]
		private var PosY:Class;
		[Embed(source="/../embeds/skybox/sky_negY.jpg")]
		private var NegY:Class;
		[Embed(source="/../embeds/skybox/sky_posZ.jpg")]
		private var PosZ:Class;
		[Embed(source="/../embeds/skybox/sky_negZ.jpg")]
		private var NegZ:Class;
		
		[Embed(source="/../embeds/object_coin.png")]
		private var Coin:Class;
		
		[Embed(source="/../embeds/object_pottery_2.png")]
		private var Pottery:Class;
		
		[Embed(source="/../embeds/object_pottery_3.png")]
		private var Pottery2:Class;
		
		[Embed(source="/../embeds/object_person.png")]
		private var Person:Class;
		
		// terrain height map
		[Embed(source="/../embeds/terrain/excavation_elevation.jpg")]
		private var HeightMap:Class;
		
		// terrain texture map
		[Embed(source="/../embeds/terrain/excavation.jpg")]
		private var Albedo:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:FirstPersonController;
		private var awayStats:AwayStats;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		//private var sunLight:DirectionalLight;
		//private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var terrainMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//scene objects
		private var text:TextField;
		private var terrain:Elevation;
		private var coinSprite:Sprite3D;
		private var personSprite:Mesh;
		private var potterySprite:Sprite3D;
		private var plane:Mesh;
		
		//rotation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		//movement variables
		private var drag:Number = 0.5;
		private var walkIncrement:Number = 20;
		private var strafeIncrement:Number = 20;
		private var walkSpeed:Number = 0;
		private var strafeSpeed:Number = 0;
		private var walkAcceleration:Number = 0;
		private var strafeAcceleration:Number = 0;
		private var potterySprite2:Sprite3D;
		
		/**
		 * Constructor
		 */
		public function Excavation_Browser()
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
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			view = new View3D();
			scene = view.scene;
			camera = view.camera;
			
			camera.lens.far = 4000;
			camera.lens.near = 1;
			camera.y = 300;
			camera.x = 392;
			camera.z = -1391;
			
			//setup controller to be used on the camera
			cameraController = new FirstPersonController(camera, -20, 30, -80, 80);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			//view.filters3d = [ new BloomFilter3D(200, 200, .85, 15, 2) ];
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			awayStats = new AwayStats(view);
			addChild(awayStats);
		}
		
		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Mouse click and drag - rotate\n" + 
				"Cursor keys / WSAD - move\n";
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			//sunLight = new DirectionalLight(-300, -300, -5000);
			//sunLight.color = 0xfffdc5;
			//sunLight.ambient = 1;
			//scene.addChild(sunLight);
			
			//lightPicker = new StaticLightPicker([sunLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(0, 8000, 0xcfd9de);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(PosX), Cast.bitmapData(NegX), Cast.bitmapData(PosY), Cast.bitmapData(NegY), Cast.bitmapData(PosZ), Cast.bitmapData(NegZ));
			
			terrainMaterial = new TextureMaterial(Cast.bitmapTexture(Albedo));
			//terrainMaterial.lightPicker = lightPicker;
			//terrainMaterial.ambientColor = 0x303040;
			terrainMaterial.ambient = 0;
			terrainMaterial.specular = .2;
			//terrainMaterial.addMethod(fogMethod);
		}
		
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));
			
			//create mountain like terrain
			terrain = new Elevation(terrainMaterial, Cast.bitmapData(HeightMap), 5000, 600, 5000, 250, 250);
			scene.addChild(terrain);
			
			//create coin billboard
			var coinTexture:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(Coin));
			coinTexture.alphaThreshold = 0.5;
			
			coinSprite = new Sprite3D(coinTexture, 100, 100);
			coinSprite.x = 400;
			coinSprite.z = 400;
			coinSprite.addEventListener(MouseEvent3D.MOUSE_UP, onCoinInfo);
			scene.addChild(coinSprite);
			
			//create person billboard
			var personTexture:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(Person));
			personTexture.alphaThreshold = 0.5;
			
			personSprite = new Mesh(new PlaneGeometry(300, 300, 1, 1, false), personTexture);
			personSprite.rotationY = -45;
			personSprite.x = -1000;
			personSprite.y = 350;
			personSprite.z = 800;
			scene.addChild(personSprite);
			
			
			//create pttery billboard
			var potteryTexture:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(Pottery));
			potteryTexture.alphaThreshold = 0.5;
			
			potterySprite = new Sprite3D(potteryTexture, 100, 100);
			potterySprite.x = -1400;
			potterySprite.z = 400;
			potterySprite.addEventListener(MouseEvent3D.MOUSE_UP, onPotteryInfo);
			scene.addChild(potterySprite);
			
			
			//create pttery billboard
			var potteryTexture2:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(Pottery2));
			potteryTexture2.alphaThreshold = 0.5;
			
			potterySprite2 = new Sprite3D(potteryTexture2, 100, 100);
			potterySprite2.x = 700;
			potterySprite2.z = -500;
			potterySprite2.addEventListener(MouseEvent3D.MOUSE_UP, onPottery2Info);
			scene.addChild(potterySprite2);
			
			
		}
		
		protected function onPottery2Info(event:MouseEvent3D):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function onCoinInfo(event:MouseEvent3D):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function onPotteryInfo(event:MouseEvent3D):void
		{
			// TODO Auto-generated method stub
			
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			//set the camera height based on the terrain (with smoothing)
			camera.y += 0.2*(terrain.getHeightAt(camera.x, camera.z) + 400 - camera.y);
			
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
				
			}
			
			if (walkSpeed || walkAcceleration) {
				walkSpeed = (walkSpeed + walkAcceleration)*drag;
				if (Math.abs(walkSpeed) < 0.01)
					walkSpeed = 0;
				cameraController.incrementWalk(walkSpeed);
			}
			
			if (strafeSpeed || strafeAcceleration) {
				strafeSpeed = (strafeSpeed + strafeAcceleration)*drag;
				if (Math.abs(strafeSpeed) < 0.01)
					strafeSpeed = 0;
				cameraController.incrementStrafe(strafeSpeed);
			}
			
			coinSprite.y = Math.sin(getTimer()/100)*10 + 400;
			potterySprite.y = Math.sin(getTimer()/100)*10 + 400;
			potterySprite2.y = Math.sin(getTimer()/100)*10 + 400;
			
			view.render();
		}
		
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
					walkAcceleration = walkIncrement;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = -walkIncrement;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					strafeAcceleration = -strafeIncrement;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = strafeIncrement;
					break;
			}
		}
		
		/**
		 * Key up listener for camera control
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = 0;
					break;
			}
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}
}
import away3d.cameras.*;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.extrusions.*;
import away3d.materials.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.utils.*;

import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.text.*;
import flash.ui.*;
import flash.utils.*;

