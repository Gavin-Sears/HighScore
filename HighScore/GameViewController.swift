//
//  GameViewController.swift
//  HighScore
//
//  Created by Stephen Sears on 11/15/24.
//

import Foundation
import UIKit
import SpriteKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate
{
    
    // Loading Screen info
    public var presentingController: UIViewController?
    public var goAgain: Bool = false
    public var levelName: String = ""
    public var height: Int = 2
    
    // Scenes and Views
    private var gameView: SCNView!
    private var gameScene: SCNScene!
    private var UIScene: SKScene!
    
    // Camera
    private var cameraNode: SCNNode = SCNNode()
    private var camTracks: Bool = false
    private let camPos: SCNVector3 = SCNVector3(x: 0.0, y: 24.0, z: 0.0)
    private let relCamPos: SCNVector3 = SCNVector3(x: 0, y: 24, z: -28)
    
    // Update loop
    private var curTime: TimeInterval = 0
    private var stillTime: TimeInterval = 0
    private var turnPhase: Bool = true
    private var stillPhase: Bool = true
    
    // Game State
    private var pause: Bool = false
    public var win: Bool = false
    public var lose: Bool = false
    
    public var mat: SCNMaterial = SCNMaterial()
    public var waterMat: SCNMaterial = SCNMaterial()
    public var modelMat: SCNMatrix4 = SCNMatrix4()
    public var inverseModelMat: SCNMatrix4 = SCNMatrix4()
    public var grassNode: SCNNode = SCNNode()
    public var globeNode: SCNNode = SCNNode()
    
    public var grassTile: grass = grass()
    public var waterTile: water = water()
    
    public var skyNode: SCNNode = SCNNode()
    
    // Beginning functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        print("game has loaded")
    }
    
    /// Setting up gameview, and creating game scene
    func setupScene()
    {
        
        gameView = self.view as? SCNView
        
        gameView.delegate = self
        gameView.isPlaying = true
        gameView.loops = true // if render loop stops again
        gameView.rendersContinuously = true // change if issues
        gameView.allowsCameraControl = true
        gameView.showsStatistics = true
        gameView.backgroundColor = UIColor.black
        
        // gameView.frame.size
        
        // add a tap gesture recognizer
        // let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        // gameView.addGestureRecognizer(tapGesture)
         
        // create a new scene
        
        setupNodes()
        
        // set the scene to the view
        gameView.scene = self.gameScene
    }
    
    // MOST IMPORTANT METHOD
    /// Populating game scene and UI scene with nodes
    func setupNodes()
    {
        setupCamera()
        
        self.gameScene = SCNScene()
        
        //setupGrass()
        grassTile = grass()
        grassTile.obj!.position += SCNVector3(3.0, 0.0, 0.0)
        self.gameScene.rootNode.addChildNode(grassTile.obj!)
        
        //setupWater()
        waterTile = water()
        self.gameScene.rootNode.addChildNode(waterTile.obj!)
        
        setupSky()
        setupLights()
        
        self.gameScene.rootNode.addChildNode(self.cameraNode)
    }
    
    func setupLights()
    {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.intensity = 1000
        // position and angle
        // this can be animated so that sun sets in west, rises in east,
        // and is stronger in the middle of the day
        lightNode.eulerAngles = SCNVector3(-.pi / 2, 0.0, 0.0)
        // shadow settings
        lightNode.light!.castsShadow = true
        lightNode.light!.shadowMapSize = CGSize(width:2048, height:2048)
        lightNode.light!.shadowMode = .forward
        lightNode.light!.shadowSampleCount = 128 * 2
        lightNode.light!.shadowRadius = 2
        lightNode.light!.shadowBias = 32 * 2
        
        self.gameScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        ambientLightNode.light!.intensity = 800
        self.gameScene.rootNode.addChildNode(ambientLightNode)
        
    }
    
    func setupCamera()
    {
        // create and add a camera to the scene
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.usesOrthographicProjection = false
        self.cameraNode.camera?.orthographicScale = 50.0
        self.cameraNode.camera?.zFar = 500
        self.cameraNode.camera?.zNear = 0.001
        //self.cameraNode.camera?.fieldOfView = 180
        // self.gameScene.rootNode.addChildNode(self.cameraNode)
        
        // place the camera
        self.cameraNode.position = self.camPos
        //globeNode.position = self.camPos
        self.cameraNode.eulerAngles = SCNVector3(x: -.pi / 2, y: .pi, z: 0.0)
    }
    
    func setupWater()
    {
        let waterModifier = """
            uniform sampler2D texture_UV1;
            uniform sampler2D texture_UV2;
            uniform float speed;
        
            #pragma transparent
            #pragma body
        
            vec2 newCoords = _surface.diffuseTexcoord * 2.0;
        
            vec2 newCoords1 = newCoords + u_time * speed;
            newCoords1 -= floor(newCoords1);
        
            vec2 newCoords2 = (newCoords * 1.5) - u_time * speed * 0.7;
            newCoords2 -= floor(newCoords2);
        
            vec4 source1 = texture2D(texture_UV1, newCoords1);
        
            vec4 source2 = texture2D(texture_UV2, newCoords2);
        
            vec2 newCoords3 = newCoords1 - vec2(source2.r) * 0.4;
            newCoords3 -= floor(newCoords3);
        
            vec4 source3 = texture2D(texture_UV1, newCoords3);
                    
            if (source3.r < 0.9)
                source3.r *= 0.1;
        
            _output.color.a = source3.r * 0.2;
            
            _output.color.rgb = vec3(1.0) * _output.color.a;
        """
        
        waterMat.blendMode = SCNBlendMode.alpha
        waterMat.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: waterModifier]
        waterMat.diffuse.minificationFilter = SCNFilterMode.none
        waterMat.diffuse.magnificationFilter = SCNFilterMode.none
        waterMat.roughness.contents = 0.0
        
        let seamlessNoise = SCNMaterialProperty(contents: UIImage(named: "seamlessNoiseBig.png")!)
        let darkWater = SCNMaterialProperty(contents: UIImage(named: "darkWaterBig.png")!)
        //let brightWater = SCNMaterialProperty(contents: UIImage(named: "brightWater.png")!)
        
        waterMat.setValue(darkWater, forKey: "texture_UV1")
        
        waterMat.setValue(seamlessNoise, forKey: "texture_UV2")
        waterMat.setValue(NSNumber(value: 0.015), forKey: "speed")
        
        let waterNode = SCNScene(named:"water.dae")!.rootNode.childNode(withName: "Water", recursively: true)
        waterNode!.geometry!.materials = [waterMat]
        waterNode?.position = SCNVector3(1.0, 0.0, 0.0)
        waterNode?.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        
        self.gameScene.rootNode.addChildNode(waterNode!)
        let dirtNode = SCNScene(named:"water.dae")!.rootNode.childNode(withName: "WaterDirt", recursively: true)
        dirtNode!.position = SCNVector3(1.0, 0.0, 0.0)
        dirtNode!.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        dirtNode!.geometry!.materials[0].diffuse.contents = UIColor(red: 61.0 / 255.0, green: 41.0 / 255.0, blue: 17.0 / 255.0, alpha: 1.0)
       
        self.gameScene.rootNode.addChildNode(dirtNode!)
        
        let waterCopy = deepCopyNode(waterNode!)
        waterCopy.position += SCNVector3(-1.0, 0.0, 0.0)

        self.gameScene.rootNode.addChildNode(waterCopy)
        
    }
    
    func setupGrass()
    {
        /*
        let planeNode = SCNNode()
        let testScene = SCNScene(named:"testWall.dae")
        let testNode = testScene!.rootNode.childNode(withName: "Wall", recursively: true)
        
        planeNode.scale = SCNVector3(100.0, 20.0, 100.0)
        planeNode.position = SCNVector3(0.0, 0.0, 0.0)
        //planeNode.eulerAngles = SCNVector3(-Double.pi / 2.0, 2.0 * Double.pi, 0.0)
         */
        mat = SCNMaterial()
        
        // amount: 0.015-0.005
        let globeShaderModifier = """
            uniform mat4 modelMat;
            uniform mat4 inverseModelMat;
            uniform float amount;
            uniform vec3 camPos;
            vec4 worldPos = (modelMat * vec4(_geometry.position.xyz, 1.0));
            vec3 diff = worldPos.xyz - camPos;
            float height = ((pow(diff.x, 2) * -amount) + (pow(diff.z, 2) * -amount));
            vec4 offset = vec4(0.0, height, 0.0, 1.0);
            vec4 newPos = inverseModelMat * (worldPos + offset);
            _geometry.position = newPos;
            """
        
        let grassWaveModifier = """
            uniform float zThresh;
            uniform vec3 xyOffset;
            uniform float magnitude;
            uniform float waveHeight;
            uniform float grassHeight;
            uniform float speed;
            if (_geometry.position.y > zThresh)
            {
               float intensity = (_geometry.position.y - zThresh) / waveHeight;
               _geometry.position.xz += (magnitude * 0.28 * sin(u_time * speed * 3.0) + magnitude * sin(u_time * speed) + xyOffset.xz) * intensity;
               _geometry.position.y += grassHeight * intensity;
            }
            """
        
        mat.diffuse.minificationFilter = SCNFilterMode.none
        mat.diffuse.magnificationFilter = SCNFilterMode.none
        mat.diffuse.contents = UIImage(named: "grass")
        mat.lightingModel = SCNMaterial.LightingModel.constant
        mat.blendMode = SCNBlendMode.alpha
        mat.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: grassWaveModifier]//[SCNShaderModifierEntryPoint.geometry: globeShaderModifier]
        
        mat.setValue(NSNumber(value: 2.0), forKey: "zThresh")
        
        mat.setValue(NSValue(scnVector3: SCNVector3(0.05, 0.05, 0.0)), forKey: "xyOffset")
        
        mat.setValue(NSNumber(value: 0.02), forKey: "magnitude")
        
        mat.setValue(NSNumber(value: 0.1), forKey: "waveHeight")
        
        mat.setValue(NSNumber(value: 0.06), forKey: "grassHeight")
        
        mat.setValue(NSNumber(value: 1.2), forKey: "speed")
        
        //planeNode.geometry = testNode?.geometry
        //planeNode.geometry?.materials = [mat]
        
        grassNode = SCNScene(named: "grass.dae")!.rootNode.childNode(withName: "Grass", recursively: true)!
        grassNode.geometry?.materials = [mat]
        
        /*
        for i in 1...20
        {
            let copyNode = deepCopyNode(grassNode!)
            copyNode.position.z += -Float(i) + 10.0
            self.gameScene.rootNode.addChildNode(copyNode)
        }
         */
        
        grassNode.position = SCNVector3(3.0, 0.0, 0.0)
        grassNode.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        grassNode.scale = SCNVector3(1.0, 1.0, 1.0)
        
        /*
        grassNode?.runAction(
            SCNAction.repeatForever(
                SCNAction.sequence(
                    [
                        SCNAction.move(by: SCNVector3(1.0, 0.0, 1.0), duration: 1.0),
                        SCNAction.move(by: SCNVector3(-1.0, 0.0, -1.0), duration: 1.0),
                    ]
                )
            )
        )
         */
        self.gameScene.rootNode.addChildNode(grassNode)
        
        let copyGrass = deepCopyNode(grassNode)
        copyGrass.position += SCNVector3(5.0, 0.0, 0.0)
        
       self.gameScene.rootNode.addChildNode(copyGrass)
    }
    
    // get revesed normals, make as skybox
    func setupSky()
    {
        self.skyNode = SCNNode()
        let starsScene = SCNScene(named:"stars.dae")
        let sphereNode = starsScene?.rootNode.childNode(withName: "Sky", recursively: true)
        skyNode.eulerAngles = SCNVector3(-.pi / 2, 0.0, 0.0)
        skyNode.scale = SCNVector3(100.0, 100.0, 100.0)
        
        skyNode.geometry = sphereNode?.geometry
        
        let sphereMat = SCNMaterial()
        sphereMat.diffuse.contents = UIImage(named: "stars.png")
        sphereMat.roughness.contents = 1.0
        sphereMat.lightingModel = SCNMaterial.LightingModel.constant
        
        skyNode.geometry?.materials = [sphereMat]
        
        //self.gameScene.rootNode.addChildNode(skyNode)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        //cameraNode.position = SCNVector3(cameraNode.position.x, cameraNode.position.y, cameraNode.position.z + 0.03 * sin(Float(time)))
        skyNode.position = cameraNode.position
        // mat4 modelMat
        mat.setValue(NSValue(scnMatrix4: grassNode.transform), forKey: "modelMat")
        // mat4 inverseModelMat
        mat.setValue(NSValue(scnMatrix4: SCNMatrix4Invert(grassNode.transform)), forKey: "inverseModelMat")
        // float amount
        mat.setValue(NSNumber(value: 1.0), forKey: "amount")
        // vec3 camPos
        mat.setValue(NSValue(scnVector3: cameraNode.position), forKey: "camPos")
        
        //grassTile.obj!.geometry!.firstMaterial!.setValue(NSNumber(value: Float((sin(time) + 1.0) / 2.0)), forKey: "freshness")
        //waterTile.obj!.childNode(withName: "Water", recursively: true)!.geometry!.firstMaterial!.setValue(NSNumber(value: Float((sin(time) + 1.0) / 2.0)), forKey: "freshness")
    }
    
    /// Movement logic for player to be used in update loop
    func updateMovement(time: TimeInterval)
    {
        /*
        if let player = self.player
        {
            if dpad.countFingers() == 1
            {
                let point = dpad.findFingerLocation()
                let vec = dpad.readInput(point: point)
                //dpad.lastMove = vec
                //print(dpad.lastMove)
                if self.turnPhase
                {
                    self.curTime = time
                    self.turnPhase = false
                }
                
                if !self.stillPhase
                {
                    self.stillPhase = true
                }
                
                if abs(time - self.curTime) > (4.0/60.0)
                {
                    DispatchQueue.main.asyncAfter(deadline: .now())
                    {
                        player.move(movement: vec, curLevel: self.curLevel!)
                    }
                }
                else
                {
                    DispatchQueue.main.asyncAfter(deadline: .now())
                    {
                        player.turn(turn: vec)
                    }
                }
            }
            else
            {
                if stillPhase
                {
                    self.stillTime = time
                    stillPhase = false
                }
                if abs(time - self.stillTime) > (10.0/60.0)
                {
                    self.turnPhase = true
                    if let plyr = self.player
                    {
                        if !plyr.isMoving
                        {
                            plyr.idleAnim()
                        }
                    }
                }
            }
        }
         */
    }
    
    func togglePause()
    {
        self.pause = !self.pause
        self.gameScene.isPaused = !self.gameScene.isPaused
        self.gameView.isPlaying = !self.gameView.isPlaying
        self.gameView.loops = !self.gameView.loops
    }
    
    /*
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        if isBeingDismissed
        {
            if let controller = self.presentingController as? LoadingScreenViewController
            {
                controller.dismiss(animated: false)
                if let superController = controller.presentingController as? MainMenuViewController
                {
                    superController.togglePause()
                }
            }
        }
    }
     */
    
    func deepCopyNode(_ node: SCNNode) -> SCNNode {
        
      let clone = SCNNode()
        clone.geometry = node.geometry
        
        clone.scale = node.scale
        clone.rotation = node.rotation
      
      return clone
    }
}

extension SCNVector3 {
     func distance(to vector: SCNVector3) -> Float {
         return simd_distance(simd_float3(self), simd_float3(vector))
     }
 }
