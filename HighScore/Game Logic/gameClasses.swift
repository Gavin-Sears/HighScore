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
    // Basic stats
    var moveSpeed: Float
    var obj: SCNNode
    
    var isIdle: Bool = false
    var isWalk: Bool = false
    var isMine: Bool = false
    
    var allowedToTurn: Bool = true
    var allowedToMove: Bool = true
    var allowedToIdle: Bool = true
    var allowedToAct: Bool = true
    
    var idleAnimPlayer: SCNAnimationPlayer?
    var walkAnimPlayer: SCNAnimationPlayer?
    var mineAnimPlayer: SCNAnimationPlayer?
    
    var curLevel: Level?
    
    var rotVec: SCNVector3 = SCNVector3(x: 0, y: 0, z: 1)
    
    // Move logic
    var isMoving: Bool
    
    // Player logic
    var ability: () -> Void
    
    init(moveSpeed: Float, curLevel: Level)
    {
        self.curLevel = curLevel
        self.moveSpeed = moveSpeed
        self.obj = SCNNode()
        
        """
        // idleAnimPlayer
        self.idleAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Characters/Dough_Puncher/Anims/DPIdle.dae")
        self.idleAnimPlayer.animation.isRemovedOnCompletion = false
        self.idleAnimPlayer.animation.blendInDuration = 0.001
        self.idleAnimPlayer.paused = true
        
        // walkAnimPlayer
        self.walkAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Characters/Dough_Puncher/Anims/DPWalk.dae")
        self.walkAnimPlayer.animation.isRemovedOnCompletion = false
        self.walkAnimPlayer.paused = true
        
        // mineAnimPlayer
        self.mineAnimPlayer = SCNAnimationPlayer.loadAnimation(fromSceneNamed: "art.scnassets/Characters/Dough_Puncher/Anims/DPWin.dae")
        self.mineAnimPlayer.animation.isRemovedOnCompletion = false
        self.mineAnimPlayer.paused = true
        """
        
        """
        if let arm = self.obj.childNode(withName: "Armature", recursively: true)
        {
            arm.addAnimationPlayer(self.idleAnimPlayer, forKey: "Idle")
            arm.addAnimationPlayer(self.walkAnimPlayer, forKey: "Walk")
            arm.addAnimationPlayer(self.mineAnimPlayer, forKey: "Mine")
        }
        """
        
        self.isMoving = false
        // just to stop the self errors
        self.ability = {() -> Void in return}
    }
    
    func useAbility()
    {
        self.ability()
    }
    
    func noAbility()
    {
        self.ability = {() -> Void in return}
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
        if self.allowedToTurn
        {
            if turn.length > 0.2
            {
                self.rotVec = turn
                let turnLoc =  self.obj.position + turn + SCNVector3(x:0.0001,y:0,z:0.0001)
                self.obj.look(at: turnLoc, up: SCNVector3(x: 0, y: 1, z: 0), localFront: SCNVector3(x: 0, y: 0, z: 1))
            }
        }
    }
    
    /*
    """
    /// Function that moves the main player
    ///
    /// Checks if a space is valid to move to, if so turns the character, then moves to the space
    ///
    /// - Parameters:
    /// - movement: vector representing the move we would like to make (difference from player position)
    /// - tiles: array of tiles in the stage
    ///
    func move(movement: SCNVector3, curLevel: Level)
    {
        if (!self.isDead && self.allowedToMove)
        {
            let moveLoc: SCNVector3 = movement + self.obj.position
            
            if !self.isMoving
            {
                self.turn(turn: movement)
                correctLoc()
                if canMove(moveLoc: moveLoc, curLevel: curLevel)
                {
                    self.moveAnim(movement: movement)
                }
            }
        }
    }
    
    /// Execute player's movement and animation
    ///
    /// Uses SCNActions to move the player, and uses any animations set beforehand
    ///
    /// - Parameters:
    ///  - movement: the local coordinate of the position we are moving to
    func moveAnim(movement: SCNVector3)
    {
        if !self.isWalk || (self.isWalk && self.walkAnimPlayer.paused)
        {
            self.stopAllAnims(withBlendOutDuration: 0.2)
            self.walkAnimPlayer.paused = false
            self.walkAnimPlayer.play()
            self.isIdle = false
            self.isWalk = true
        }
        self.isMoving = true
        self.obj.runAction(
            SCNAction.move(
                by: movement,
                duration: TimeInterval((movement.length / moveSpeed))),
                forKey: "playerMovement",
                completionHandler: {() -> Void in
                    self.isMoving = false})
    }
    """
    
    """
    func idleAnim()
    {
        // weird issue where acting while moving causes animation freeze
        if (!self.isIdle && self.allowedToIdle) || (self.isIdle && self.idleAnimPlayer.paused)
        {
            self.isWalk = false
            self.stopAllAnims(withBlendOutDuration: 0.2)
            self.idleAnimPlayer.paused = false
            self.idleAnimPlayer.play()
            self.isIdle = true
        }
    }
    """
    
    """
    func stopAllAnims(withBlendOutDuration: TimeInterval)
    {
        self.idleAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.idleAnimPlayer.paused = true
        self.walkAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.walkAnimPlayer.paused = true
        self.mineAnimPlayer.stop(withBlendOutDuration: withBlendOutDuration)
        self.mineAnimPlayer.paused = true
    }
    """
     */
    
    /// Rounds player position to avoid drifting
    func correctLoc()
    {
        let correctLoc = roundPos(pos: self.obj.position)
        self.obj.runAction(SCNAction.move(to: correctLoc, duration: TimeInterval(0)))
    }
    
    /// Returns whether or not the player is currently moving
    func movementState() -> Bool
    {
        return self.obj.actionKeys.contains("playerMovement")
    }
}

//TILES

class air: Tile
{
    var freshness: Float = 0.0
    var obj: SCNNode?
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
    }
}

class grass: Tile
{
    var freshness: Float = 1.0
    var obj: SCNNode?
    var canWalk: Bool = true
    
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
        grassNode.geometry?.materials = [grassMat]
        
        self.obj = grassNode
    }
    
    required init(cloneOf: Tile)
    {
        if let object = cloneOf.obj
        {
            self.obj = deepCopyNode(object)
        }
    }
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        self.obj!.geometry!.materials[0].setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
}

class water: Tile
{
    var freshness: Float = 1.0
    var obj: SCNNode?
    var canWalk: Bool = false
    
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
        let waterNode = SCNScene(named:"water.dae")!.rootNode.childNode(withName: "Water", recursively: true)
        waterNode!.geometry!.materials = [waterMat]
        waterNode!.position = SCNVector3(1.0, 0.0, 0.0)
        waterNode?.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        
        // loading dirt model and adding material
        let dirtNode = SCNScene(named:"water.dae")!.rootNode.childNode(withName: "WaterDirt", recursively: true)
        dirtNode!.eulerAngles = SCNVector3(-Double.pi / 2, 0.0, 0.0)
        dirtNode!.position = SCNVector3(1.0, 0.0, 0.0)
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
    
    func updateFreshness(amount: Float)
    {
        self.freshness += amount
        self.obj!.geometry!.materials[0].setValue(NSNumber(value: self.freshness), forKey: "freshness")
    }
}

//HELPER FUNCTIONS

// I would make these the same function, but because of how often these are called, I want to save performance
// returns tile at given point and below given point
private func doubleTileLookup(curLevel: Level, pos: SCNVector3) -> [Tile]
{
    let tiles = curLevel.getTiles()
    let size = curLevel.getLevelSize()
    let width = size[0]
    let height = size[2]
    
    // Making sure we do not go off the top
    if !(pos.z > 0)
    {
        // Making sure we do go off the sides
        if !(pos.x < 0.0 || pos.x > Float(width - 1))
        {
            let columnLength = Float(((tiles.count / height) / width) - 1)
            // Making sure we do not go off the bottom
            if !(abs(pos.z) > columnLength)
            {
                let checkForHeight = floatCompare(f1: pos.y, f2: Float(height), thresh: 0.01)
                switch checkForHeight
                {
                    case 0:
                        // we are on top of the map
                        // this is repeated code, but it saves performance
                        let row = Int(round(pos.x)) * width
                        let index = Int(-round(pos.z)) + row
                        let flatNum = width * Int(columnLength + 1)
                    
                        let curIndex = index + flatNum * Int(pos.y - 1)
                    
                        return [tiles[curIndex], air()]
                    case 1:
                        print("character is above the map")
                        return [air(), air()]
                    case 2:
                        // do normal stuff
                        // this is repeated code, but it saves performance
                        let row = Int(round(pos.x)) * width
                        let index = Int(-round(pos.z)) + row
                        let flatNum = width * Int(columnLength + 1)
                    
                        let curIndex = index + flatNum * Int(pos.y - 1)
                        let upperIndex = index + flatNum * Int(pos.y)
                        
                        return [tiles[curIndex], tiles[upperIndex]]
                    default:
                        print("AN ERROR OCCURED")
                }
            }
        }
    }
    return [air(), air()]
}

/// This just saves performance to have both of these methods. Checks tile on given point
private func singleTileLookup(curLevel: Level, pos: SCNVector3) -> Tile
{
    let tiles = curLevel.getTiles()
    let size = curLevel.getLevelSize()
    let width = size[0]
    let height = size[2]
    // Making sure we do not go off the top
    if !(pos.z > 0)
    {
        // Making sure we do go off the sides
        if !(pos.x < 0.0 || pos.x > Float(width - 1))
        {
            let columnLength = Float(((tiles.count / height) / width) - 1)
            // Making sure we do not go off the bottom
            if !(abs(pos.z) > columnLength)
            {
                if floatCompare(f1: pos.y, f2: Float(height), thresh: 0.01) == 1
                {
                    return air()
                }
                else
                {
                    let row = Int(round(pos.x)) * width
                    let index = Int(-round(pos.z)) + row
                    let flatNum = width * Int(columnLength + 1)
                
                    let curIndex = index + flatNum * Int(pos.y)
                    
                    return tiles[curIndex]
                }
            }
        }
    }
    return air()
}

/// Function that determines if an entity can make a given move
///
/// takes the position of a desired move, looks up the associated tile, then checks whether or not that tile is possible to walk on
///
///  - Parameters:
///  - entity: Class deriving from interface Entity of which we are trying to move the associated obj
///  - moveLoc: World coordinate of the position we are trying to move entity to
///  - tiles: The array of tiles used in the level
///
///  - Returns:Whether or not the given entity can move to that given point
private func canMove(moveLoc: SCNVector3, curLevel: Level) -> Bool
{
    
    let targetTiles: [Tile] = doubleTileLookup(curLevel: curLevel, pos: moveLoc)
    let lowerTile = targetTiles[0]
    let upperTile = targetTiles[1]
    
    let lower : Bool = true
    let upper : Bool = true
    
    return lower && upper
}

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
