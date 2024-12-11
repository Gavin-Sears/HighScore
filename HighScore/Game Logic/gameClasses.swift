//
//  gameClasses.swift
//  Simple3DGame
//
//  Created by Stephen Sears on 7/22/24.
//  Modified for "High Score" on 12/4/24.
//

import Foundation
import SceneKit
import SpriteKit

//PLAYERS

// Player that is being controlled on this device
// NOT NECESSARILY PLAYER 1
class MainPlayer: Entity
{
    var score: Int = 0
    
    // Basic stats
    var moveSpeed: Float
    // object in scene (is armature)
    weak var obj: SCNNode?
    // root bone (child of armature)
    var rootBone: SCNNode
    // robot mesh node (child of armature)
    var robotNode: SCNNode
    
    // stupid workaround
    var armNode: SCNNode
    
    // material for screen that displays things
    var screenMat: SCNMaterial
    
    // checking if animation is playing (costs less than checking keys)
    var isIdle: Bool = false
    var isMove: Bool = false
    var isDrill: Bool = false
    
    // animation players
    var idleAnimPlayer: SCNAnimationPlayer
    var moveAnimPlayer: SCNAnimationPlayer
    var drillAnimPlayer: SCNAnimationPlayer
    
    weak var curLevel: Level?
    
    // used for keeping rotations clean
    var rotVec: SCNVector3 = SCNVector3(x: 0, y: 0, z: -1.0)
    
    // movement logic
    var isMoving: Bool = false
    var isDrilling: Bool = false
    var inDrillFunction: Bool = false
    
    let drillAnimSpeed = 5.0
    
    init(moveSpeed: Float, curLevel: Level)
    {
        self.curLevel = curLevel
        self.moveSpeed = moveSpeed
        let robotScene = SCNScene(named:"robot.dae")!
        self.obj = robotScene.rootNode.childNode(withName: "Armature", recursively: true)!
        self.obj!.position = SCNVector3(1.0, 3.0, 1.0)
        self.obj!.scale = SCNVector3(0.3, 0.3, 0.3)
        self.obj!.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        self.rootBone = self.obj!.childNode(withName: "Root", recursively: true)!
        self.rootBone.position = SCNVector3(0.0, 0.0, 0.0)
        self.rootBone.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        
        self.robotNode = self.obj!.childNode(withName: "Robot", recursively: true)!
        self.robotNode.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        
        let roboGeo = robotNode.geometry!
        
        //stupid workaround because drill arm is not working
        self.armNode = self.rootBone.childNode(withName: "Arm1", recursively: true)!
        self.armNode.eulerAngles = SCNVector3((-.pi / 2.0) - 0.3, 0.0, 0.0)
        let arm2Node = self.armNode.childNode(withName: "Arm2", recursively: true)!
        arm2Node.eulerAngles = SCNVector3(0.3, 0.0, 0.0)
        self.armNode.scale = SCNVector3(0.0, 0.0, 0.0)
        
        // drill - set metal to 1.0, roughness to map
        let drillMat = roboGeo.materials[1]
        drillMat.lightingModel = SCNMaterial.LightingModel.physicallyBased
        drillMat.metalness.contents = 1.0
        drillMat.roughness.contents = UIImage(named: "drillRough")
        
        // screen - special shader to modify texture
        let screenTextureModifier = """
            uniform sampler2D texture_UV1;
            uniform sampler2D texture_UV2;
            uniform sampler2D texture_UV3;
            
            uniform float type;
                        
            #pragma body
            
            vec4 color;
            
            if (type == 1)
            {
                color = texture2D(texture_UV1, _surface.diffuseTexcoord);
            }
            else if (type == 2)
            {
                color = texture2D(texture_UV2, _surface.diffuseTexcoord);
            }
            else
            {
                color = texture2D(texture_UV3, _surface.diffuseTexcoord);
            }
            
            _output.color.rgba = color;
            """
        self.screenMat = SCNMaterial()
        self.screenMat.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: screenTextureModifier]
        let smiley = SCNMaterialProperty(contents: UIImage(named: "Smiley")!)
        let forward = SCNMaterialProperty(contents: UIImage(named: "Forward")!)
        let mining = SCNMaterialProperty(contents: UIImage(named: "Mining")!)
        
        // setting shader variables
        screenMat.setValue(smiley, forKey: "texture_UV1")
        screenMat.setValue(forward, forKey: "texture_UV2")
        screenMat.setValue(mining, forKey: "texture_UV3")
        screenMat.setValue(NSNumber(value: 1), forKey: "type")
        
        roboGeo.materials[3] = self.screenMat
        
        // idleAnimPlayer
        self.idleAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "robotIdle.dae")
        self.idleAnimPlayer.animation.isRemovedOnCompletion = false
        self.idleAnimPlayer.animation.blendInDuration = 0.001
        self.idleAnimPlayer.paused = true
        self.idleAnimPlayer.play()
        
        // walkAnimPlayer
        self.moveAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "robotMove.dae")
        self.moveAnimPlayer.animation.isRemovedOnCompletion = false
        self.moveAnimPlayer.animation.blendInDuration = 0.001
        self.moveAnimPlayer.speed = CGFloat(moveSpeed)
        self.moveAnimPlayer.paused = true
        //self.moveAnimPlayer.play()
        
        // mineAnimPlayer
        self.drillAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "robotDrill.dae")
        self.drillAnimPlayer.animation.isRemovedOnCompletion = false
        self.drillAnimPlayer.paused = true
        self.drillAnimPlayer.speed = self.drillAnimSpeed
        //self.drillAnimPlayer.play()
        
        self.obj!.addAnimationPlayer(self.idleAnimPlayer, forKey: "Idle")
        self.obj!.addAnimationPlayer(self.moveAnimPlayer, forKey: "Move")
        self.obj!.addAnimationPlayer(self.drillAnimPlayer, forKey: "Drill")
        
        self.isMoving = false
    }
    
    /// Function that turns the main player
    ///
    /// Gets turn location, adds small amount to prevent gimbal lock, then turns character
    ///
    ///  - Parameters:
    ///   - turnLoc: the local position of the coordinate that we want the character to
    ///   turn towards
    func turn(turn: SCNVector3)
    {
        if turn.length > 0.2
        {
            if (abs(turn.x) > 0.0)
            {
                // x
                if (turn.x > 0.0)
                {
                    // right
                    self.obj!.eulerAngles.y = -.pi / 2.0
                    self.rotVec = SCNVector3(1.0, 0.0, 0.0)
                }
                else
                {
                    // left
                    self.obj!.eulerAngles.y = .pi / 2.0
                    self.rotVec = SCNVector3(-1.0, 0.0, 0.0)
                }
            }
            else
            {
                // y
                if (turn.z > 0.0)
                {
                    // towards
                    self.obj!.eulerAngles.y = .pi
                    self.rotVec = SCNVector3(0.0, 0.0, 1.0)
                }
                else
                {
                    // away
                    self.obj!.eulerAngles.y = 0.0001
                    self.rotVec = SCNVector3(0.0, 0.0, -1.0)
                }
            }
        }
    }
    
    func drill()
    {
        // can't act if we are moving, or already acting
        if (!isMoving && !isDrilling)
        {
            self.isDrilling = true
            self.inDrillFunction = true
            self.updateAnims()
            
            // search for tile in front of player
            let theTile = curLevel!.searchTiles(movement: self.rotVec)
            
            if (theTile.type != 2)
            {
                // lower freshness by value if not water
                theTile.updateFreshness(amount: -0.1)
            }
            else
            {
                curLevel?.updateWaterFreshness(amount: -0.02)
            }
            
            // checking if freshness if still there, so we can increase score
            if (theTile.freshness > 0.0)
            {
                // increment score
                switch (theTile.type)
                {
                case 0:
                    break
                case 1:
                    // score for grass
                    self.score += 100
                case 2:
                    // score for water
                    self.score += 500
                case 3:
                    // score for tree
                    self.score += 300
                case 4:
                    // score for rock
                    self.score += 400
                default:
                    break
                }
            }
            
            // should be duration of drill animation
            DispatchQueue.main.asyncAfter(deadline: .now() + drillAnimPlayer.animation.duration / self.drillAnimSpeed)
            {
                if (self.inDrillFunction)
                {
                    self.isDrilling = false
                }
            }
        }
    }
    
    /// Function that moves the main player
    ///
    /// Checks if a space is valid to move to, if so turns the character, then moves to the space
    ///
    /// - Parameters:
    /// - movement: vector representing the move we would like to make (difference from player position)
    /// - tiles: array of tiles in the stage
    ///
    func move(movement: SCNVector3)
    {
        if (!isMoving)
        {
            // we turn regardless of if we can move
            turn(turn: movement)
            // check to see if we have a valid move
            if (curLevel!.canMove(movement: movement))
            {
                if (!self.inDrillFunction)
                {
                    self.isDrilling = false
                }
                moveAnim(movement: movement * 2.0)
            }
        }
    }
    
    /// Execute player's movement and animation
    ///
    /// Uses SCNActions to move the player, and uses any animations set beforehand
    ///
    /// - Parameters:
    ///  - movement: the offset we are moving by
    func moveAnim(movement: SCNVector3)
    {
        self.isMoving = true
        self.updateAnims()
        self.obj!.runAction(
            SCNAction.move(
                by: movement,
                duration: TimeInterval((movement.length / moveSpeed))),
            forKey: "playerMovement",
            completionHandler: 
                {() -> Void in
                    self.isMoving = false
                    self.updateAnims()
                    self.curLevel!.spotLightUpdate(pos: self.obj!.position, rad: 5)
                    self.curLevel!.scrollLevel(move: movement)
                    self.correctLoc()
                })
    }
    
    func updateAnims()
    {
        
        if (isMoving)
        {
            // prevent continuous animation start
            if (!isMove)
            {
                // initiate move animation
                stopAllAnims(withBlendOutDuration: 0.01)
                self.moveAnimPlayer.paused = false
                self.moveAnimPlayer.play()
                self.isMove = true
                self.armNode.scale = SCNVector3(0.0, 0.0, 0.0)
                screenMat.setValue(NSNumber(value: 2), forKey: "type")
            }
        }
        else if (isDrilling)
        {
            // prevent continuous animation start
            if (!isDrill)
            {
                // initiate move animation
                stopAllAnims(withBlendOutDuration: 0.01)
                self.drillAnimPlayer.paused = false
                self.drillAnimPlayer.play()
                self.isDrill = true
                self.armNode.scale = SCNVector3(1.0, 1.0, 1.0)
                screenMat.setValue(NSNumber(value: 3), forKey: "type")
            }
        }
        else
        {
            // prevent continuous animation start
            if (!isIdle)
            {
                // initiate idle animation
                stopAllAnims(withBlendOutDuration: 0.01)
                self.idleAnimPlayer.paused = false
                self.idleAnimPlayer.play()
                self.isIdle = true
                self.armNode.scale = SCNVector3(0.0, 0.0, 0.0)
                screenMat.setValue(NSNumber(value: 1), forKey: "type")
            }
        }
    }
    
    func stopAllAnims(withBlendOutDuration: TimeInterval)
    {
        self.idleAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.idleAnimPlayer.paused = true
        self.isIdle = false
        self.moveAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.moveAnimPlayer.paused = true
        self.isMove = false
        self.drillAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.drillAnimPlayer.paused = true
        self.isDrill = false
    }
    
    /// Rounds player position to avoid drifting
    func correctLoc()
    {
        self.obj!.position = roundPos(pos: self.obj!.position)
    }
    
    /// Returns whether or not the player is currently moving
    func movementState() -> Bool
    {
        return self.obj!.actionKeys.contains("playerMovement")
    }
    
    deinit
    {
        print("player has been deallocated")
    }
}

//TILES

class air: Tile
{
    var originalIndex: Int?
    var type: Int = 0
    var freshness: Float = 0.0
    weak var obj: SCNNode?
    var canWalk: Bool = false
    
    required init()
    {
        self.obj = nil
    }
    
    required init(cloneOf: Tile)
    {
        self.obj = nil
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        if (self.freshness > 1.0)
        {
            self.freshness = 1.0
        }
        else if (self.freshness < 0.0)
        {
            self.freshness = 0.0
        }
    }
    
//    func updateGlobeShader(playerPos: SCNVector3)
//    {
//        return
//    }
}

class grass: Tile
{
    var originalIndex: Int?
    var type: Int = 1
    var freshness: Float = 1.0
    weak var obj: SCNNode?
    var canWalk: Bool = true
    var mat: SCNMaterial?
    
    required init()
    {
        let grassWaveModifier = """
            uniform float heightThresh;
            uniform vec3 xyOffset;
            uniform float magnitude;
            uniform float waveHeight;
            uniform float grassHeight;
            uniform float speed;
            uniform float freshness;
            
            if (_geometry.position.y > heightThresh)
            {
               float intensity = (_geometry.position.y - heightThresh) / waveHeight;
               _geometry.position.xz += (magnitude * 0.28 * sin(u_time * speed * 3.0) + magnitude * sin(u_time * speed) + xyOffset.xz) * intensity * freshness;
                float freshMod = (freshness - 0.6) * 2.5;
               _geometry.position.y += grassHeight * freshMod * intensity;
            }
            """
        
        let grassColorModifier = """
            uniform float freshness;
            
            if (_output.color.g > 0.03)
                _output.color.rgb += (vec3(0.9, 0.2, 0.0) * (1 - freshness));
            """
    
        // setting material properties and adding modifiers
        let grassMat = SCNMaterial()
        grassMat.diffuse.minificationFilter = SCNFilterMode.none
        grassMat.diffuse.magnificationFilter = SCNFilterMode.none
        grassMat.diffuse.contents = UIImage(named: "grass")
        grassMat.lightingModel = SCNMaterial.LightingModel.constant
        grassMat.blendMode = SCNBlendMode.alpha
        grassMat.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: grassWaveModifier, SCNShaderModifierEntryPoint.fragment: grassColorModifier]
        
        // setting grassWave modifier variables
        grassMat.setValue(NSNumber(value: 2.0), forKey: "heightThresh")
        grassMat.setValue(NSValue(scnVector3: SCNVector3(0.05, 0.05, 0.0)), forKey: "xyOffset")
        grassMat.setValue(NSNumber(value: 0.02), forKey: "magnitude")
        grassMat.setValue(NSNumber(value: 0.1), forKey: "waveHeight")
        grassMat.setValue(NSNumber(value: 0.06), forKey: "grassHeight")
        grassMat.setValue(NSNumber(value: 1.2), forKey: "speed")
        grassMat.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        
        // loading model and adding material
        let grassNode = SCNScene(named: "grass.dae")!.rootNode.childNode(withName: "Grass", recursively: true)!
        grassNode.position = SCNVector3(0.0, 0.0, 0.0)
        
        self.mat = grassMat
        
        grassNode.geometry?.materials = [self.mat!]
        self.obj = grassNode
    }
    
    required init(cloneOf: Tile)
    {
        if let object = cloneOf.obj
        {
            self.obj = deepCopyNode(object)
        }
    }
    
    func setFreshness(amount: Float)
    {
        self.freshness = amount
        self.obj?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        if (self.freshness > 1.0)
        {
            self.freshness = 1.0
        }
        else if (self.freshness < 0.0)
        {
            self.freshness = 0.0
        }
        
        self.obj?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
}

class water: Tile
{
    var originalIndex: Int?
    var type: Int = 2
    var freshness: Float = 1.0
    var obj: SCNNode?
    var canWalk: Bool = false
    var mat: SCNMaterial?
    
    required init()
    {
        let waterColorModifier = """
            uniform sampler2D texture_UV1;
            uniform sampler2D texture_UV2;
            uniform float speed;
            uniform float freshness;
            
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
            
            _output.color.a = source3.r * 0.2 + (1.0 - pow(freshness, 0.5)) * 0.4;
            _output.color.rgb = vec3(freshness * freshness * freshness) * _output.color.a;
            """
        
        let waterHeightModifier = """
            uniform float freshness;
            uniform float heightThresh;
            
            if (_geometry.position.z > heightThresh)
                _geometry.position.z -= (1.0 - freshness) * 0.49;
            """
        
        // creating material and setting properties
        let waterMat = SCNMaterial()
        waterMat.blendMode = SCNBlendMode.alpha
        waterMat.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: waterColorModifier, SCNShaderModifierEntryPoint.geometry: waterHeightModifier]
        waterMat.diffuse.minificationFilter = SCNFilterMode.none
        waterMat.diffuse.magnificationFilter = SCNFilterMode.none
        waterMat.roughness.contents = 0.0
        let seamlessNoise = SCNMaterialProperty(contents: UIImage(named: "seamlessNoiseBig.png")!)
        let darkWater = SCNMaterialProperty(contents: UIImage(named: "darkWaterBig.png")!)
        
        // setting shader variables
        waterMat.setValue(darkWater, forKey: "texture_UV1")
        waterMat.setValue(seamlessNoise, forKey: "texture_UV2")
        waterMat.setValue(NSNumber(value: 0.015), forKey: "speed")
        waterMat.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        waterMat.setValue(NSNumber(value: 1.9), forKey: "heightThresh")
        
        // loading water model and adding material
        let waterScene = SCNScene(named:"water.dae")
        
        let waterNode = waterScene!.rootNode.childNode(withName: "Water", recursively: true)
        waterNode!.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        waterNode!.position = SCNVector3(0.0, 0.0, 0.0)
        
        self.mat = waterMat
        
        waterNode!.geometry!.materials = [self.mat!]
        
        // loading dirt model and adding material
        let dirtNode = waterScene!.rootNode.childNode(withName: "WaterDirt", recursively: true)
        dirtNode!.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        dirtNode!.position = SCNVector3(0.0, 0.0, 0.0)
        dirtNode!.geometry!.materials[0].diffuse.contents = UIColor(red: 61.0 / 255.0, green: 41.0 / 255.0, blue: 17.0 / 255.0, alpha: 1.0)
        
        // combining two objects to one node
        let waterObj = SCNNode()
        waterObj.addChildNode(waterNode!)
        waterObj.addChildNode(dirtNode!)
        
        self.obj = waterObj
    }
    
    required init(cloneOf: Tile)
    {
        if let object = cloneOf.obj
        {
            self.obj = deepCopyNode(object)
        }
    }
    
    func setFreshness(amount: Float)
    {
        self.freshness = amount
        self.obj?.childNode(withName: "Water", recursively: true)?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        if (self.freshness > 1.0)
        {
            self.freshness = 1.0
        }
        else if (self.freshness < 0.0)
        {
            self.freshness = 0.0
        }
            
        self.obj?.childNode(withName: "Water", recursively: true)?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
}

class tree: Tile
{
    var originalIndex: Int?
    var type: Int = 3
    var freshness: Float = 1.0
    weak var obj: SCNNode?
    var canWalk: Bool = false
    var originalColors: UIImage?
    var baseYAngle: Float = 0.0
    var mat: SCNMaterial?
    
    required init()
    {
        let grassWaveModifier = """
            uniform float heightThresh;
            uniform vec3 xyOffset;
            uniform float magnitude;
            uniform float waveHeight;
            uniform float grassHeight;
            uniform float speed;
            uniform float freshness;
            
            if (_geometry.position.z > heightThresh)
            {
               float intensity = (_geometry.position.z - heightThresh) / waveHeight;
                vec2 offset = (magnitude * 0.28 * sin(u_time * speed * 3.0) + magnitude * sin(u_time * speed) + xyOffset.xy) * intensity * freshness;
               _geometry.position.xy += vec2(offset.x, -offset.y);
                float freshMod = (freshness - 0.6) * 2.5;
               _geometry.position.z += grassHeight * freshMod * intensity;
            }
            """
        
        let grassColorModifier = """
            uniform float freshness;
            
            if (_output.color.g > 0.03)
                _output.color.rgb += (vec3(0.9, 0.2, 0.0) * (1 - freshness));
            """
    
        // setting material properties and adding modifiers
        let grassMat = SCNMaterial()
        grassMat.diffuse.minificationFilter = SCNFilterMode.none
        grassMat.diffuse.magnificationFilter = SCNFilterMode.none
        grassMat.diffuse.contents = UIImage(named: "grass")
        grassMat.lightingModel = SCNMaterial.LightingModel.constant
        grassMat.blendMode = SCNBlendMode.alpha
        grassMat.shaderModifiers = [SCNShaderModifierEntryPoint.geometry: grassWaveModifier, SCNShaderModifierEntryPoint.fragment: grassColorModifier]
        
        // setting grassWave modifier variables
        grassMat.setValue(NSNumber(value: 2.0), forKey: "heightThresh")
        grassMat.setValue(NSValue(scnVector3: SCNVector3(0.05, 0.0, 0.05)), forKey: "xyOffset")
        grassMat.setValue(NSNumber(value: 0.02), forKey: "magnitude")
        grassMat.setValue(NSNumber(value: 0.1), forKey: "waveHeight")
        grassMat.setValue(NSNumber(value: 0.06), forKey: "grassHeight")
        grassMat.setValue(NSNumber(value: 1.2), forKey: "speed")
        grassMat.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        
        let treeScene = SCNScene(named: "tree.dae")
        
        // loading grass and adding material
        let treeGrass = treeScene!.rootNode.childNode(withName: "TreeGrass", recursively: true)!
        treeGrass.geometry?.materials = [grassMat]
        treeGrass.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        treeGrass.position = SCNVector3(0.0, 0.0, 0.0)
        
        // creating tree material
        let treeColorModifier = """
            uniform float freshness;
            
            if (_output.color.r > 0.2)
                _output.color.rgb = _output.color.rgb * freshness + vec3(0.0) * (1.0 - freshness);
            else
                _output.color.rgb += (vec3(0.9, 0.2, 0.0) * (1 - pow(freshness, 0.25)));
            """
        
        let treeMat = SCNMaterial()
        self.originalColors = UIImage(named: "tree.png")
        treeMat.lightingModel = SCNMaterial.LightingModel.phong
        treeMat.diffuse.contents = self.originalColors
        treeMat.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: treeColorModifier]
        treeMat.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        
        // loading tree and adding material
        let treeNode = treeScene!.rootNode.childNode(withName: "Tree", recursively: true)!
        treeNode.geometry?.materials = [treeMat]
        treeNode.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        treeNode.position = SCNVector3(0.0, 2.0, 0.0)
        
        // combining two objects to one node
        let treeObj = SCNNode()
        treeObj.addChildNode(treeGrass)
        treeObj.addChildNode(treeNode)
        
        self.obj = treeObj
    }
    
    required init(cloneOf: Tile)
    {
        if let object = cloneOf.obj
        {
            self.obj = deepCopyNode(object)
        }
    }
    
    func treeFreshness(amount: Float)
    {
        let treeNode = self.obj?.childNode(withName: "Tree", recursively: true)
        
        let remappedAmount = (amount * 0.8) + 0.2
        
        treeNode?.scale = SCNVector3(remappedAmount, remappedAmount, remappedAmount)
        treeNode?.eulerAngles.y = .pi * amount + baseYAngle
        
        treeNode?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
    
    func setFreshness(amount: Float)
    {
        self.freshness = amount
        self.obj?.childNode(withName: "TreeGrass", recursively: true)?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        treeFreshness(amount: self.freshness)
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        if (self.freshness > 1.0)
        {
            self.freshness = 1.0
        }
        else if (self.freshness < 0.0)
        {
            self.freshness = 0.0
        }
        
        self.obj?.childNode(withName: "TreeGrass", recursively: true)?.geometry?.firstMaterial?.setValue(NSNumber(value: self.freshness), forKey: "freshness")
        treeFreshness(amount: self.freshness)
    }
    
    func addBaseAngle(amount: Float)
    {
        self.baseYAngle += amount
        self.obj?.childNode(withName: "Tree", recursively: true)?.eulerAngles.y += amount
    }
}

class rock: Tile
{
    var originalIndex: Int?
    var type: Int = 3
    var freshness: Float = 1.0
    weak var obj: SCNNode?
    var canWalk: Bool = false
    var baseYAngle: Float = 0.0
    var mat: SCNMaterial?
    
    required init()
    {
        let rockScene = SCNScene(named:"rock.dae")!
        
        // loading rock model
        let rockNode = rockScene.rootNode.childNode(withName: "Rock", recursively: true)
        rockNode!.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        rockNode!.position = SCNVector3(0.0, 2.0, 0.0)
        
        // creating and setting dirt material
        let dirtMat = SCNMaterial()
        dirtMat.diffuse.contents = UIImage(named: "rockDirt")
        
        // loading dirt model
        let dirtNode = SCNScene(named:"rock.dae")!.rootNode.childNode(withName: "RockDirt", recursively: true)
        dirtNode!.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        dirtNode!.position = SCNVector3(0.0, 0.0, 0.0)
        dirtNode!.geometry!.materials = [dirtMat]
        
        // combining two objects to one node
        let rockObj = SCNNode()
        rockObj.addChildNode(rockNode!)
        rockObj.addChildNode(dirtNode!)
        
        self.obj = rockObj
    }
    
    required init(cloneOf: Tile)
    {
        if let object = cloneOf.obj
        {
            self.obj = deepCopyNode(object)
        }
    }
    
    func rockFreshness(amount: Float)
    {
        let rock = self.obj?.childNode(withName: "Rock", recursively: true)
        
        var newAmount: Float = 0.0
        
        if (amount > 0.0)
        {
            newAmount = amount
        }
        
        let remappedFreshness = floor(((newAmount * newAmount) * 10.0) + 0.9) / 10.0
        
        rock?.scale = SCNVector3(remappedFreshness, remappedFreshness, remappedFreshness)
        rock?.eulerAngles.y = remappedFreshness * .pi + baseYAngle
    }
    
    func setFreshness(amount: Float)
    {
        self.freshness = amount
        rockFreshness(amount: amount)
        
        if (freshness < 0.1)
        {
            self.canWalk = true
        }
        else
        {
            self.canWalk = false
        }
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        rockFreshness(amount: self.freshness)
        
        if (freshness < 0.1)
        {
            self.canWalk = true
        }
        else
        {
            self.canWalk = false
        }
    }
    
    func addBaseAngle(amount: Float)
    {
        self.baseYAngle += amount
        self.obj?.childNode(withName: "Rock", recursively: true)?.eulerAngles.y += amount
    }
}

//HELPER FUNCTIONS

/// Compares two floating point numbers with a threshold
///
/// likely depreciated, but tells us whether two floating point numbers are within a certain range of eachother
///
/// - Parameters:
/// - f1:first Float to compare
/// - f2: second Float to compare
/// - thresh: threshold for comparing Floats
///
/// - Returns: 0 if floats are equal, 1 if f1 is bigger, and 2 if f2 is bigger
public func floatCompare(f1: Float, f2: Float, thresh: Float) -> Int
{
    if abs(f1 - f2) < abs(thresh)
    {
        return 0
    }
    else
    {
        if f1 > f2
        {
            return 1
        }
        else
        {
            return 2
        }
    }
}

///Returns true if two vectors are similar enough, otherwise returns false
public func vectorCompare(v1: SCNVector3, v2: SCNVector3, thresh: Float) -> Bool
{
    let compareX: Bool = (floatCompare(f1: v1.x, f2: v2.x, thresh: thresh) == 0)
    let compareY: Bool = (floatCompare(f1: v1.y, f2: v2.y, thresh: thresh) == 0)
    let compareZ: Bool = (floatCompare(f1: v1.z, f2: v2.z, thresh: thresh) == 0)
    
    return (compareX && compareY && compareZ)
}

extension SCNAnimationPlayer {
    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
    
    
    class func loadAnimations(fromSceneNamed sceneName: String) -> [SCNAnimationPlayer] {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayers: [SCNAnimationPlayer]! = []
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                for key in child.animationKeys
                {
                    if let player: SCNAnimationPlayer = child.animationPlayer(forKey: key)
                    {
                        animationPlayers.append(player)
                    }
                }
                stop.pointee = true
            }
        }
        return animationPlayers
    }
}

func deepCopyNode(_ node: SCNNode) -> SCNNode {
  let clone = SCNNode()
    clone.geometry = node.geometry
    
    clone.scale = node.scale
    clone.rotation = node.rotation
  
  return clone
}

public func roundPos(pos: SCNVector3) -> SCNVector3
{
    return SCNVector3(
        x: round(pos.x),
        y: round(pos.y),
        z: round(pos.z)
    )
}
