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
        // gameView.rendersContinuously // change if issues
        // gameView.allowsCameraControl = true
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
    
    // MOST IMPORTANT METHOD
    /// Populating game scene and UI scene with nodes
    func setupNodes()
    {
        setupCamera()
        
        self.gameScene = SCNScene()
        
        setupCubes()
        
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
        self.cameraNode.eulerAngles = SCNVector3(x: -(.pi / 3), y: .pi, z: 0)
    }
    
    func setupCubes()
    {
        let cubeNode = SCNNode()
        cubeNode.position = SCNVector3(1.0, 1.0, 1.0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(named: "blue")
        cubeNode.geometry = SCNBox()
        cubeNode.geometry?.materials = [mat]
        
        self.gameScene.rootNode.addChildNode(cubeNode)
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
