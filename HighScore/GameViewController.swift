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
    private let camPos: SCNVector3 = SCNVector3(x: 6.5, y: 24, z: -28)
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
    public var modelMat: SCNMatrix4 = SCNMatrix4()
    public var inverseModelMat: SCNMatrix4 = SCNMatrix4()
    public var planeNode: SCNNode = SCNNode()
    public var globeNode: SCNNode = SCNNode()
    
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
        // gameView.showsStatistics = true
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
    
    func setupLights()
    {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .spot
        lightNode.light!.spotOuterAngle = 120.0
        lightNode.light!.intensity = 1500
        lightNode.position = SCNVector3(x: -14, y: 20, z: -20)
        lightNode.look(at: SCNVector3(x: 6.5, y: 0, z: -6.5))
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
    
    // MOST IMPORTANT METHOD
    /// Populating game scene and UI scene with nodes
    func setupNodes()
    {
        setupCamera()
        
        self.gameScene = SCNScene()
        
        setupObjects()
        setupLights()
        
        self.gameScene.rootNode.addChildNode(self.cameraNode)
    }
    
    func setupCamera()
    {
        // create and add a camera to the scene
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.usesOrthographicProjection = false
        self.cameraNode.camera?.orthographicScale = 15.0
        // self.gameScene.rootNode.addChildNode(self.cameraNode)
        
        // place the camera
        self.cameraNode.position = self.camPos
        globeNode.position = self.camPos
        self.cameraNode.eulerAngles = SCNVector3(x: -(.pi / 3), y: .pi, z: 0)
    }
    
    func setupObjects()
    {
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(6.5, 1.0, -15.0)
        planeNode.scale = SCNVector3(5.0, 5.0, 5.0)
        planeNode.eulerAngles = SCNVector3(Double.pi, 0.0, 0.0)
        mat = SCNMaterial()
        mat.diffuse.contents = UIColor.green
        
        let distortionShaderModifier =
            "uniform float amplitude = 0.2; \n" +
            "vec2 sincos(float t) { return vec2(sin(t), cos(t)); } \n" +
            "#pragma transparent \n" +
            "#pragma body \n" +
            "_geometry.position.z += amplitude * sin(u_time * _geometry.position.x);"
        
        // 0.015-0.005
        let globeShaderModifier =
            "uniform mat4 modelMat; \n" +
            "uniform mat4 inverseModelMat; \n" +
            "uniform float amount; \n" +
            "uniform vec3 camPos; \n" +
            "vec4 worldPos = vec4(_geometry.position.xyz, 1.0) * modelMat; \n" +
            "vec3 diff = worldPos.xyz - camPos; \n" +
            "float height = pow(diff.x, 2) + pow(diff.z, 2) * amount; \n" +
            "vec4 offset = vec4(0.0, 0.0, height, 1.0); \n" +
            "vec4 newPos = worldPos + offset * inverseModelMat; \n" +
            "_geometry.position = newPos;"
        
        mat.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: globeShaderModifier]
        // mat4 modelMat
        mat.setValue(NSValue(scnMatrix4: planeNode.transform), forKey: "modelMat")
        // mat4 inverseModelMat
        mat.setValue(NSValue(scnMatrix4: SCNMatrix4Invert(planeNode.transform)), forKey: "inverseModelMat")
        // float amount
        mat.setValue(NSNumber(value: 0.005), forKey: "amount")
        // vec3 camPos
        mat.setValue(NSValue(scnVector3: globeNode.position), forKey: "camPos")
        
        planeNode.geometry = SCNPlane()
        let geo = (planeNode.geometry! as! SCNPlane)
        geo.widthSegmentCount = 10;
        geo.heightSegmentCount = 10;
        planeNode.geometry?.materials = [mat]
        
        self.gameScene.rootNode.addChildNode(planeNode)
        
        /*cubeNode.runAction(
            SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0.0, y: Double.pi, z: 0.0, duration: 2.0)
            )
        )*/
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
        print(time)
        // mat4 modelMat
        mat.setValue(NSValue(scnMatrix4: planeNode.transform), forKey: "modelMat")
        // mat4 inverseModelMat
        mat.setValue(NSValue(scnMatrix4: SCNMatrix4Invert(planeNode.transform)), forKey: "inverseModelMat")
        // float amount
        mat.setValue(NSNumber(value: 0.005), forKey: "amount")
        // vec3 camPos
        mat.setValue(NSValue(scnVector3: globeNode.position), forKey: "camPos")
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
}

extension SCNVector3 {
     func distance(to vector: SCNVector3) -> Float {
         return simd_distance(simd_float3(self), simd_float3(vector))
     }
 }
