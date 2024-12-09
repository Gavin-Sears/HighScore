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
    
    public var playerPos = SCNVector3(1.0, 0.0, 1.0)
    public var prevTime: TimeInterval = 0.0
    
    public var skyNode: SCNNode = SCNNode()
    public var player: MainPlayer?
    
    // controls variables
    // how far you have to swipe to swipe
    public var swipeLength: CGFloat = 0.1
    
    public var fingerDown: Bool = false
    public var drillTimer: TimeInterval = 0.2
    public var drillCooldown: TimeInterval = 0.5
    public var drillTimerMax: TimeInterval = 0.2
    
    // game UI stuff
    public var timeLeft: SKLabelNode = SKLabelNode(fontNamed: "ArialRoundedMTBold")
    public var timer: TimeInterval = 60.4 {
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
    
    // score submit UI
    
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
    
    // start screen UI
    
    // entry 0 will be top score
    public var entries: [[SKLabelNode]] = []
    public var highScores: [(String, Int)] = Array(repeating: ("AAA", 0), count: 10) {
        didSet {
            if entries.count > 0
            {
                // entries number can't be more than highScores
                for i: Int in 0...(entries.count - 1)
                {
                    let entry = self.highScores[highScores.count - (i + 1)]
                    // names get displayed last
                    entries[i][2].text = entry.0
                    entries[i][1].text = "\(entry.1)"
                    // hide entries with zero score that are AAA
                    let hidden = entries[i][2].text == "AAA" && Int(entries[i][1].text!) == 0
                    for j: Int in 0...2
                    {
                        entries[i][j].isHidden = hidden
                    }
                }
            }
        }
    }
    public var canStart: Bool = false
    
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
        
        setupStartUI()
        setupGameUI()
        setupScoreUI()
        
        setScene()
    }
    
    func setScene()
    {
        gameView.delegate = self
        //gameView.isPlaying = true
        //gameView.loops = true // if render loop stops again
        //gameView.rendersContinuously = true // change if issues
        //gameView.allowsCameraControl = true
        gameView.showsStatistics = true
        gameView.backgroundColor = UIColor.black
        let level = Level()
        self.curLevel = level
        setupSky()
        
        self.player = MainPlayer(moveSpeed: 3.0, curLevel: self.curLevel!)
        curLevel!.playerNode = self.player!.obj!
        setupCamera()
        self.curLevel!.gameScene.rootNode.addChildNode(player!.obj!)
        
        // set the scene to the view
        gameView.scene = curLevel!.gameScene
        
        startUISwitch()
        
        curLevel!.spotLightUpdate(pos: player!.obj!.position, rad: 5)
    }
    
    func setupStartUI()
    {
        let screenSize = self.gameView.bounds.size
        let halfW = screenSize.width / 2.0
        let halfH = screenSize.height / 2.0
        
        self.startUIScene = SKScene(size: CGSize(width: screenSize.width, height: screenSize.height))
        
        //gray overlay
        let grayOverlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        let grayColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        grayOverlay.fillColor = grayColor
        grayOverlay.strokeColor = grayColor
        grayOverlay.zPosition = 0.0
        
        self.startUIScene.addChild(grayOverlay)
        
        // HIGH SCORE
        let title = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.text = "High Score"
        title.colorBlendFactor = 1.0
        title.fontSize = halfH / 8.0
        title.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: halfW, y: halfH * 1.7)
        title.zPosition = 1.0
        
        self.startUIScene.addChild(title)
        
        // LEADERBOARD (text)
        let lbText = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        lbText.horizontalAlignmentMode = .center
        lbText.verticalAlignmentMode = .center
        lbText.text = "Leaderboard:"
        lbText.colorBlendFactor = 1.0
        lbText.fontSize = halfH / 16.0
        lbText.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        lbText.position = CGPoint(x: halfW, y: halfH * 1.7 - halfH / 8.0)
        lbText.zPosition = 1.0
        
        self.startUIScene.addChild(lbText)
        
        // (actual Leaderboard)
        let height = halfH
        let width = halfW * 1.4
        let leaderBox = SKShapeNode(rect: CGRect(x: halfW - width / 2.0, y: halfH - height / 2.0, width: width, height: height))
        let boxColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        leaderBox.fillColor = boxColor
        leaderBox.strokeColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        leaderBox.zPosition = 1.0
        
        self.startUIScene.addChild(leaderBox)
        
        let topHeight = (halfH * 1.5) - halfH / 16.0 + 5
        
        // leaderboard entries 1-10
        entries = []
        for i: Int in 0...9
        {
            // example of entry
            // place
            let place = SKLabelNode(fontNamed: "ArialRoundedMTBold")
            place.horizontalAlignmentMode = .right
            place.verticalAlignmentMode = .center
            place.text = "\(i + 1)."
            place.colorBlendFactor = 1.0
            place.fontSize = halfH / 16.0
            place.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            place.position = CGPoint(x: halfW - halfW / 2.0, y: topHeight - CGFloat(i) * (halfH / 10.0))
            place.zPosition = 2.0
            // name
            let name = SKLabelNode(fontNamed: "ArialRoundedMTBold")
            name.horizontalAlignmentMode = .right
            name.verticalAlignmentMode = .center
            name.text = "AAA"
            name.colorBlendFactor = 1.0
            name.fontSize = halfH / 16.0
            name.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            name.position = CGPoint(x: halfW, y: topHeight - CGFloat(i) * (halfH / 10.0))
            name.zPosition = 2.0
            //score
            let score = SKLabelNode(fontNamed: "ArialRoundedMTBold")
            score.horizontalAlignmentMode = .right
            score.verticalAlignmentMode = .center
            score.text = "0"
            score.colorBlendFactor = 1.0
            score.fontSize = halfH / 16.0
            score.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            score.position = CGPoint(x: halfW + halfW / 1.6, y: topHeight - CGFloat(i) * (halfH / 10.0))
            score.zPosition = 2.0
            
            // hiding initial entries
            place.isHidden = true
            name.isHidden = true
            score.isHidden = true
            
            // adding to scene
            self.startUIScene.addChild(place)
            self.startUIScene.addChild(score)
            self.startUIScene.addChild(name)
            
            //array
            let entry: [SKLabelNode] = [place, score, name]
            entries.append(entry)
        }
        
        // SWIPE/TAP TO START
        let TTS = SKLabelNode(fontNamed: "ArialRoundedMTBold")
        TTS.horizontalAlignmentMode = .center
        TTS.verticalAlignmentMode = .center
        TTS.text = "SWIPE/TAP TO START"
        TTS.colorBlendFactor = 1.0
        TTS.fontSize = halfH / 8.0
        TTS.fontColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        TTS.position = CGPoint(x: halfW, y: halfH * 0.3)
        TTS.zPosition = 1.0
        
        self.startUIScene.addChild(TTS)
        
        // tap to start functionality
        let tapToStart = TapToStartZone(imageNamed: "transparent")
        tapToStart.gameViewController = self
        tapToStart.scale(to: CGSize(width: screenSize.width, height: screenSize.height))
        tapToStart.position = CGPoint(x: halfW, y: halfH)
        tapToStart.zPosition = 5.0
        
        self.startUIScene.addChild(tapToStart)
    }
    
    func startUISwitch()
    {
        self.pauseGame()
        self.gameView.overlaySKScene = self.startUIScene
        self.myTextField?.removeFromSuperview()
        self.scoreUIScene.removeAllActions()
        self.startUIScene.run(
            SKAction.sequence(
                [
                    SKAction.wait(forDuration: 1.0),
                    SKAction.run(self.allowStarting)
                ]
            )
        )
    }
    
    func allowStarting()
    {
        self.canStart = true
    }
    
    func forbidStarting()
    {
        self.canStart = false
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
        let submitButton = submitButton(rect: CGRect(x: halfW - 150, y: halfH / 1.5, width: 300, height: 100), cornerRadius: 50)
        submitButton.gameViewController = self
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
        
        submitButton.addChild(submitText)
    }
    
    func scoreUISwitch()
    {
        self.pauseGame()
        self.gameView.overlaySKScene = self.scoreUIScene
        self.gameView.addSubview(self.myTextField!)
        self.nameTime = 40
        self.scoreUIScene.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.run(countDown)])))
    }
    
    func scoreEntry(name: String)
    {
        submitScore(name: name)
        clearScore()
    }
    
    // if we know the score entry is in the top ten,
    // inserts the score into the leaderboard
    func submitScore(name: String)
    {
        let entry = (name, self.score)
        // we know the entry at least is this high
        self.highScores[0] = entry
        
        // sorts array with one out of place element
        // don't need to check last element, since we will have
        // switched it by the time we get there
        for i: Int in 0...(self.highScores.count - 2)
        {
            let curScore = self.highScores[i].1
            let nextScore = self.highScores[i + 1].1
            
            if (curScore > nextScore)
            {
                self.highScores.swapAt(i, i + 1)
            }
        }
    }
    
    func clearScore() -> Void
    {
        self.player!.score = 0
        self.score = 0
        self.playerName = ""
        self.myTextField!.text = ""
    }
    
    func isHighScore() -> Bool
    {
        return self.score > highScores[0].1
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
            
            self.scoreEntry(name: self.playerName)
            
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
        self.timeLeft.text = "Time: 60"
        self.timeLeft.colorBlendFactor = 1.0
        self.timeLeft.fontSize = halfH / 8.0
        self.timeLeft.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.timeLeft.position = CGPoint(x: halfW / 4.0, y: halfH - 90)
        
        self.gameUIScene.addChild(self.timeLeft)
        
        self.scoreLabel.horizontalAlignmentMode = .left
        self.scoreLabel.verticalAlignmentMode = .bottom
        self.scoreLabel.text = "Score: 0"
        self.scoreLabel.colorBlendFactor = 1.0
        self.scoreLabel.fontSize = halfH / 8.0
        self.scoreLabel.fontColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.scoreLabel.position = CGPoint(x: -halfW + halfW / 8.0, y: halfH - 90)
        
        self.gameUIScene.addChild(self.scoreLabel)
        
        let swipeArea = SwipeZone(imageNamed: "transparent")
        swipeArea.gameViewController = self
        swipeArea.scale(to: CGSize(width: screenSize.width, height: screenSize.height))
        
        self.gameUIScene.addChild(swipeArea)
    }
    
    func gameUISwitch()
    {
        self.continueGame()
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
    
    // get reversed normals, make as skybox
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
        self.curLevel!.gameScene.rootNode.addChildNode(self.skyNode)
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
        if (!pause)
        {
            var deltaTime = time - prevTime
            if (abs(deltaTime) > 0.3)
            {
                deltaTime = 0.0
            }
            cameraNode.position = player!.obj!.position + self.relCamPos
            skyNode.position = cameraNode.position
            self.timer -= deltaTime
            if (self.timer < 0.0)
            {
                DispatchQueue.main.async { self.endGame() }
            }
            updateDrilling(deltaTime: deltaTime)
            prevTime = time
        }
    }
    
    /// Movement logic for player to be used in update loop
    func updateDrilling(deltaTime: TimeInterval)
    {
        if (self.fingerDown)
        {
            drillCooldown = 0.0
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
            drillCooldown -= deltaTime
            if (drillCooldown < 0.0)
            {
                self.player!.drill()
                self.score = self.player!.score
                
                drillCooldown = 0.5
            }
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
                                self.gameViewController?.scoreEntry(name: playerName!)
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
    
    
    class TapToStartZone: SKSpriteNode
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
            if (self.gameViewController!.canStart)
            {
                print("start game")
                self.gameViewController!.startGame()
            }
            else
            {
                print("failed to start game")
            }
        }
    }
    
    func startGame()
    {
        // reset timer
        self.continueGame()
        self.gameUISwitch()
    }
    
    func endGame()
    {
        self.scoreLabel.text = "Score: 0"
        gameView.scene!.isPaused = true
        self.timer = 60.4
        self.pause = true
        
        if (self.isHighScore())
        {
            self.scoreUISwitch()
        }
        else
        {
            self.startUISwitch()
        }
    }
    
    func pauseGame()
    {
        gameView.preferredFramesPerSecond = 0
        gameView.loops = false
        gameView.rendersContinuously = false
        gameView.scene!.isPaused = true
        self.pause = true
    }
    
    func continueGame()
    {
        gameView.play(nil)
        gameView.loops = true
        gameView.rendersContinuously = true
        gameView.scene!.isPaused = false
        self.pause = false
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
