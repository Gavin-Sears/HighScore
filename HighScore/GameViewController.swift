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

class GameViewController: UIViewController, SCNSceneRendererDelegate, UITextFieldDelegate
{
    
    // Loading Screen info
    public weak var presentingController: UIViewController?
    
    // Scenes and Views
    private weak var gameView: SCNView!
    private var gameUIScene: SKScene!
    private var scoreUIScene: SKScene!
    private var startUIScene: SKScene!
    
    // Camera
    private var cameraNode: SCNNode = SCNNode()
    private var camTracks: Bool = true
    private let camPos: SCNVector3 = SCNVector3(x: 2.0, y: 24.0, z: -2.0)
    private let relCamPos: SCNVector3 = SCNVector3(x: 0.0, y: 8.0, z: 4.0)
    
    // Game State
    private var pause: Bool = false
    public var win: Bool = false
    public var lose: Bool = false
    
    // stuff that should probably be deleted before I'm done
    public var mat: SCNMaterial = SCNMaterial()
    public var waterMat: SCNMaterial = SCNMaterial()
    public var modelMat: SCNMatrix4 = SCNMatrix4()
    public var inverseModelMat: SCNMatrix4 = SCNMatrix4()
    public var grassNode: SCNNode = SCNNode()
    public var globeNode: SCNNode = SCNNode()
    
    public var curLevel: Level?
    
    public var grassTile: grass = grass()
    public var waterTile: water = water()
    public var treeTile: tree = tree()
    public var rockTile: rock = rock()
    
    public var playerPos = SCNVector3(1.0, 0.0, 1.0)
    public var prevTime: TimeInterval = 0.0
    
    public var skyNode: SCNNode = SCNNode()
    public var player: MainPlayer?
    
    // controls variables
    // how far you have to swipe to swipe
    public var swipeLength: CGFloat = 0.1
    
    public var fingerDown: Bool = false
    public var drillTimer: TimeInterval = 0.2
    public var drillTimerMax: TimeInterval = 0.2
    
    // UI
    public var timeLeft: SKLabelNode = SKLabelNode(fontNamed: "ArialRoundedMTBold")
    public var timer: TimeInterval = 5.4 {//60.4 {
        didSet {
            if (timer > 0.0)
            {
                timeLeft.text = "Time: \(Int(round(timer)))"
            }
            else
            {
                timeLeft.text = "Time: 0"
            }
        }
    }
    
    public var scoreLabel: SKLabelNode = SKLabelNode(fontNamed: "ArialRoundedMTBold")
    public var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    public var invalidText: SKLabelNode?
    public var myTextField: UITextField?
    
    public var time: TimeInterval?
    public var scoreTime: SKLabelNode = SKLabelNode(fontNamed: "ArialRoundedMTBold")
    public var nameTime: Int = 40 {
        didSet {
            scoreTime.text = "\(nameTime)"
        }
    }
    public var playerName: String = ""
    
    // Beginning functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        print("game has loaded")
    }
    
    public var highScores: [(String, Int)] = []
    
    /// Setting up gameview, and creating game scene
    func setupScene()
    {
        gameView = self.view as? SCNView
        
        setupStartUI()
        setupGameUI()
        setupScoreUI()
        
        setScene()
    }
    
    func setScene()
    {
        gameView.delegate = self
        gameView.isPlaying = true
        gameView.loops = true // if render loop stops again
        //gameView.rendersContinuously = true // change if issues
        //gameView.allowsCameraControl = true
        gameView.showsStatistics = true
        gameView.backgroundColor = UIColor.black
        let level = Level()
        self.curLevel = level
        //self.curLevel!.gameScene.rootNode.addChildNode(self.cameraNode)
        //setupSky()
        //self.curLevel!.gameScene.rootNode.addChildNode(skyNode)
        
        //self.player = nil
        self.player = MainPlayer(moveSpeed: 3.0, curLevel: self.curLevel!)
        //player!.obj.position = SCNVector3(1.0, 0.0, 1.0)
        setupCamera()
        //player!.obj.addChildNode(self.cameraNode)
        self.curLevel!.gameScene.rootNode.addChildNode(player!.obj!)
        
        //self.gameView.overlaySKScene = self.startUIScene
        scoreUISwitch()
        // set the scene to the view
        gameView.scene = curLevel!.gameScene
    }
    
    func setupStartUI()
    {
        let screenSize = self.gameView.bounds.size
        let halfW = screenSize.width / 2.0
        let halfH = screenSize.height / 2.0
        
        self.startUIScene = SKScene(size: CGSize(width: screenSize.width, height: screenSize.height))
        
        // HIGH SCORE
        // LEADERBOARD (text)
        
        // (actual Leaderboard)
        // leaderboard transparent box
        // leaderboard entries 1-10
        
        // SWIPE/TAP TO START
    }
    
    func startUISwitch()
    {
        self.gameView.overlaySKScene = self.startUIScene
        self.myTextField?.removeFromSuperview()
        self.gameUIScene.removeAllActions()
    }
    
    func setupScoreUI()
    {
        // create score display, name input, and submit
        let screenSize = self.gameView.bounds.size
        let halfW = screenSize.width / 2.0
        let halfH = screenSize.height / 2.0
        
        self.scoreUIScene = SKScene(size: CGSize(width: screenSize.width, height: screenSize.height))
        
        //gray overlay
        let grayOverlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        let grayColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        grayOverlay.fillColor = grayColor
        grayOverlay.strokeColor = grayColor
        
        self.scoreUIScene.addChild(grayOverlay)
        
        // timer to input score
        self.scoreTime.horizontalAlignmentMode = .left
        self.scoreTime.verticalAlignmentMode = .bottom
        self.scoreTime.text = "\(nameTime)"
        self.scoreTime.colorBlendFactor = 1.0
        self.scoreTime.fontSize = 80.0
        self.scoreTime.fontColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.scoreTime.position = CGPoint(x: halfW / 8.0 + 5, y: screenSize.height - 90)
        
        self.scoreUIScene.addChild(self.scoreTime)
        
        //you got a high score!
        let congrat = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        congrat.horizontalAlignmentMode = .center
        congrat.verticalAlignmentMode = .center
        congrat.text = "You got a High Score!"
        congrat.colorBlendFactor = 1.0
        congrat.fontSize = halfH / 8.0
        congrat.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        congrat.position = CGPoint(x: halfW, y: halfH * 1.7)
        congrat.zPosition = 0.0
        
        self.scoreUIScene.addChild(congrat)
        
        // name
        let name = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        name.horizontalAlignmentMode = .center
        name.verticalAlignmentMode = .center
        name.text = "Initials:"
        name.colorBlendFactor = 1.0
        name.fontSize = halfH / 10.0
        name.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        name.zPosition = 0.0
        name.position = CGPoint(x: halfW, y: halfH * 1.32)
        
        self.scoreUIScene.addChild(name)
        
        // text input field
        self.myTextField = UITextField(frame: CGRect(origin: CGPoint(x: halfW - 150, y: halfH - 125), size: CGSize(width: 300, height: 120)))
        self.myTextField!.delegate = self
        self.myTextField!.borderStyle = .roundedRect
        self.myTextField!.backgroundColor = UIColor.black
        self.myTextField?.font = UIFont(name: "ArialRoundedMTBold", size: 100.0)
        self.myTextField?.textColor = UIColor.white
        self.myTextField?.textAlignment = NSTextAlignment.center
        self.myTextField?.contentVerticalAlignment = .bottom
        self.myTextField!.placeholder = ""
        
        // wrong input message
        let wrongText = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        wrongText.horizontalAlignmentMode = .center
        wrongText.verticalAlignmentMode = .center
        wrongText.text = "Use only letters (a-z). Must be 3 characters"
        wrongText.colorBlendFactor = 1.0
        wrongText.fontSize = halfH / 32.0
        wrongText.fontColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        wrongText.zPosition = 1.0
        wrongText.position = CGPoint(x: halfW, y: halfH / 1.5 + 150)
        
        self.scoreUIScene.addChild(wrongText)
        
        // submit button adds to high score list
        let submitButton = SKShapeNode(rect: CGRect(x: halfW - 150, y: halfH / 1.5, width: 300, height: 100), cornerRadius: 50)
        submitButton.fillColor = UIColor.systemBlue
        submitButton.strokeColor = UIColor.systemBlue
        submitButton.zPosition = 1.0
        
        self.scoreUIScene.addChild(submitButton)
        
        // submit text
        let submitText = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        submitText.horizontalAlignmentMode = .center
        submitText.verticalAlignmentMode = .center
        submitText.text = "Submit"
        submitText.colorBlendFactor = 1.0
        submitText.fontSize = halfH / 10.0
        submitText.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        submitText.zPosition = 2.0
        submitText.position = CGPoint(x: halfW, y: halfH / 1.5 + 50)
        
        self.scoreUIScene.addChild(submitText)
        
    }
    
    func scoreUISwitch()
    {
        self.gameView.overlaySKScene = self.scoreUIScene
        self.gameView.addSubview(self.myTextField!)
        self.scoreUIScene.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.run(countDown)])))
    }
    
    func submitScore(name: String)
    {
        // add score to list of scores
        print(name)
    }
    
    func countDown() -> Void
    {
        nameTime -= 1
        
        if (nameTime <= 0)
        {
            if (self.playerName.count < 3)
            {
                self.playerName = "AAA"
            }
            
            self.submitScore(name: self.playerName)
            
            DispatchQueue.main.async { self.startUISwitch() }
        }
    }
    
    func setupGameUI()
    {
        let screenSize = self.gameView.bounds.size
        let halfW = screenSize.width / 2.0
        let halfH = screenSize.height / 2.0
        
        self.gameUIScene = SKScene(size: CGSize(width: screenSize.width, height: screenSize.height))
        self.gameUIScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // create timer, and score
        self.timeLeft.horizontalAlignmentMode = .left
        self.timeLeft.verticalAlignmentMode = .bottom
        self.timeLeft.text = "60"
        self.timeLeft.colorBlendFactor = 1.0
        self.timeLeft.fontSize = 80.0
        self.timeLeft.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.timeLeft.position = CGPoint(x: halfW / 4.0, y: halfH - 90)
        
        self.gameUIScene.addChild(self.timeLeft)
        
        self.scoreLabel.horizontalAlignmentMode = .left
        self.scoreLabel.verticalAlignmentMode = .bottom
        self.scoreLabel.text = "Score: 0"
        self.scoreLabel.colorBlendFactor = 1.0
        self.scoreLabel.fontSize = 80.0
        self.scoreLabel.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.scoreLabel.position = CGPoint(x: -halfW + halfW / 8.0, y: halfH - 90)
        
        self.gameUIScene.addChild(self.scoreLabel)
        
        let swipeArea = SwipeZone(imageNamed: "transparent")
        swipeArea.gameViewController = self
        swipeArea.scale(to: CGSize(width: screenSize.width, height: screenSize.height))
        
        self.gameUIScene.addChild(swipeArea)
    }
    
    func gameUISwitch()
    {
        self.gameView.overlaySKScene = self.gameUIScene
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
        self.cameraNode.position = self.relCamPos + player!.obj!.position
        //globeNode.position = self.camPos
        // 90 - 18.5 = 71.5
        self.cameraNode.eulerAngles = SCNVector3(x: -63.44 * .pi / 180.0, y: 0.0, z: 0.0)
        
        curLevel!.gameScene.rootNode.addChildNode(self.cameraNode)
    }
    
    /*
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
     */
    
    /*
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
    */
    
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
        var deltaTime = time - prevTime
        if (abs(deltaTime) > 10.0)
        {
            deltaTime = 0.0
        }
        cameraNode.position = player!.obj!.position + self.relCamPos
        //cameraNode.position = SCNVector3(cameraNode.position.x, cameraNode.position.y, cameraNode.position.z + 0.03 * sin(Float(time)))
        skyNode.position = cameraNode.position
        // mat4 modelMat
        //mat.setValue(NSValue(scnMatrix4: grassNode.transform), forKey: "modelMat")
        // mat4 inverseModelMat
        //mat.setValue(NSValue(scnMatrix4: SCNMatrix4Invert(grassNode.transform)), forKey: "inverseModelMat")
        // float amount
        //mat.setValue(NSNumber(value: 1.0), forKey: "amount")
        // vec3 camPos
        //mat.setValue(NSValue(scnVector3: cameraNode.position), forKey: "camPos")
        self.timer = self.timer - deltaTime
        if (self.timer < 0.0)
        {
            //DispatchQueue.main.async { self.endGame() }
        }
        updateDrilling(deltaTime: deltaTime)
        
        /*
        grassTile.setFreshness(amount: Float(sin(time) + 1.0) / 2.0)
        waterTile.setFreshness(amount: Float(sin(time) + 1.0) / 2.0)
        treeTile.setFreshness(amount: Float(sin(time) + 1.0) / 2.0)
        rockTile.setFreshness(amount: Float(sin(time) + 1.0) / 2.0)
         */
        //timer -= Float(seconds)
        curLevel!.spotLightUpdate(pos: player!.obj!.position, rad: 5)
        
         /*
        if (timer < 0.0)
        {
            print("scroll")
            let move = SCNVector3(2.0, 0.0, 0.0)
            playerPos += move
            curLevel!.scrollLevel(move: move)
            timer = 0.5
        }
          */
        prevTime = time
    }
    
    /// Movement logic for player to be used in update loop
    func updateDrilling(deltaTime: TimeInterval)
    {
        if (self.fingerDown)
        {
            drillTimer -= deltaTime
        }
        else
        {
            player!.isDrilling = false
            player!.updateAnims()
            drillTimer = self.drillTimerMax
        }
        
        if (self.fingerDown && drillTimer < 0.0)
        {
            self.player!.drill()
            
            self.score = self.player!.score
        }
    }
    
    class submitButton: SKShapeNode
    {
        var gameViewController: GameViewController?
        
        override var isUserInteractionEnabled: Bool
        {
            set
            {
                // ignore
            }
            get
            {
                return true
            }
        }
        
        var fingers = [UITouch?](repeating: nil, count:5)

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
                super.touchesBegan(touches, with: event)
                for touch in touches{
                    for (index,finger)  in self.fingers.enumerated() {
                        if finger == nil {
                            fingers[index] = touch
                            //print("finger \(index+1): x=\(point.x) , y=\(point.y)")
                            let playerName = self.gameViewController?.playerName
                            if (playerName!.count == 3)
                            {
                                self.gameViewController?.submitScore(name: playerName!)
                                self.gameViewController?.startUISwitch()
                            }
                            break
                        }
                    }
                }
        }
    }
    
    class SwipeZone: SKSpriteNode
    {
        var gameViewController: GameViewController?
        
        var firstInput: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
        override var isUserInteractionEnabled: Bool
        {
            set
            {
                // ignore
            }
            get
            {
                return true
            }
        }
        
        var fingers = [UITouch?](repeating: nil, count:5)

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let paused = self.gameViewController?.pause
            {
                if !paused
                {
                    super.touchesBegan(touches, with: event)
                    for touch in touches{
                        let point = touch.location(in: self)
                        for (index,finger)  in self.fingers.enumerated() {
                            if finger == nil {
                                fingers[index] = touch
                                self.firstInput = point
                                self.gameViewController!.fingerDown = true
                                //print("finger \(index+1): x=\(point.x) , y=\(point.y)")
                                break
                            }
                        }
                    }
                }
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let paused = self.gameViewController?.pause
            {
                if !paused
                {
                    super.touchesMoved(touches, with: event)
                    for touch in touches {
                        let point = touch.location(in: self)
                        for (_,finger) in self.fingers.enumerated() {
                            if let finger = finger, finger == touch {
                                // print("finger \(index+1): x=\(point.x) , y=\(point.y)")
                                var move: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
                                
                                let diffX = point.x - self.firstInput.x
                                let diffY = point.y - self.firstInput.y
                                let absX = abs(diffX)
                                let absY = abs(diffY)
                                
                                let sumDiff = absX + absY
                                
                                if (sumDiff > self.gameViewController!.swipeLength)
                                {
                                    self.gameViewController!.fingerDown = false
                                    if (absX > absY)
                                    {
                                        // horizontal movement
                                        move = SCNVector3(diffX / absX, 0.0, 0.0)
                                    }
                                    else
                                    {
                                        // vertical movement
                                        move = SCNVector3(0.0, 0.0, -diffY / absY)
                                    }
                                    
                                    self.gameViewController!.player!.move(movement: move)
                                }
                                
                                break
                            }
                        }
                    }
                }
            }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            for touch in touches {
                for (index,finger) in self.fingers.enumerated() {
                    if let finger = finger, finger == touch {
                        fingers[index] = nil
                        self.gameViewController!.fingerDown = false
                        break
                    }
                }
            }
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            touchesEnded(touches, with: event)
        }
        
        func countFingers() -> Int
        {
            var count: Int = 0
            for (_,finger) in self.fingers.enumerated()
            {
                if finger != nil
                {
                    count += 1
                }
            }
            return count
        }
        
        // only if there is one finger
        func findFingerLocation() -> CGPoint
        {
            for (_,finger) in self.fingers.enumerated()
            {
                if let finger = finger
                {
                    return finger.location(in: self)
                }
            }
            return CGPoint(x: 0, y: 0)
        }
    }
    
    func endGame()
    {
        //self.pause = true
        //self.gameScene.isPaused = true
        //self.gameView.isPlaying = false
        //self.gameView.loops = false
        /*
        self.player!.obj.position = SCNVector3(1.0, 3.0, 1.0)
        cameraNode.position = player!.obj.position + self.relCamPos
        curLevel!.resetTiles()
         */
        
        curLevel = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now())
        {
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // words that I don't want to be allowed
        // I apologize in advance for anyone who has to read these.
        // I just tried to figure out what would offend others or ruin
        // the experience of the exhibit
        let badWords = ["sex", "fuk", "fuc", "fck", "cum", "ass", "fag", "fgt", "jew", "tit", "bbc", "nut", "poo", "pee", "kkk", "nig", "ngr", "gyp", "cox"]
        
        var accepted = true
        
        for word in badWords
        {
            if (updatedText.lowercased() == word)
            {
                accepted = false
            }
        }
        
        // make sure the result is under 3 characters
        if ((updatedText.count <= 3) && containsOnlyLetters(input: updatedText) && accepted)
        {
            self.playerName = updatedText
            return true
        }
        return false
    }
    
    func containsOnlyLetters(input: String) -> Bool {
       for chr in input {
          if (!(chr >= "a" && chr <= "z") && !(chr >= "A" && chr <= "Z") ) {
             return false
          }
       }
       return true
    }
    
    func deepCopyNode(_ node: SCNNode) -> SCNNode {
        
      let clone = SCNNode()
        clone.geometry = node.geometry
        
        clone.scale = node.scale
        clone.rotation = node.rotation
      
      return clone
    }
    
    deinit {
        self.curLevel?.gameScene.rootNode.cleanup()
        print("deallocating view")
    }
}

extension SCNVector3 {
     func distance(to vector: SCNVector3) -> Float {
         return simd_distance(simd_float3(self), simd_float3(vector))
     }
 }

extension SCNNode {
    func cleanup() {
        for child in childNodes {
            child.cleanup()
        }
        geometry = nil
        print("cleanup")
    }
}
