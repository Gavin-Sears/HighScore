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
    
    required init()
    {
        self.obj = nil
    }
    
    required init(cloneOf: Tile)
    {
        self.obj = nil
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
