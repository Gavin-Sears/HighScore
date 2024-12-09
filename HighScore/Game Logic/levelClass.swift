//
//  levelClass.swift
//  Simple3DGame
//
//  Created by Stephen Sears on 7/26/24.
//  Modified for "High Score" on 12/4/24.
//

import Foundation
import SceneKit

class Level
{
    // this is the map of the level. This will never change
    private var tileIndices: [Int] = [1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1,
                                      1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1,
                                      1, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1,
                                      4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1,
                                      1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 3, 1, 1, 1, 4, 4,
                                      4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4,
                                      4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 4, 4, 4,
                                      4, 4, 4, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4,
                                      4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4,
                                      4, 4, 1, 1, 4, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 4, 4,
                                      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      4, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1,
                                      1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1,
                                      1, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                      1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1, 4, 4,
                                      1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 4, 4,]
    public var tiles: [[Tile]] = []
    public var gameScene: SCNScene
    // 0 is air, 1 is grass, 2 is water, 3 is tree, 4 is rock
    private var tileArray: [() -> Tile] = [air.init, grass.init, water.init, tree.init, rock.init]
    private var lights: [SCNNode] = []
    
    public var playerNode: SCNNode?
    
    init()
    {
        self.gameScene = SCNScene()
        
        buildLights()
        buildTiles()
    }
    
    func buildTiles()
    {
        for i in 0...19
        {
            var row: [Tile] = []
            
            for j in 0...19
            {
                let tileIndex = tileIndices[(i * 20) + j]
                
                var tile = tileArray[tileIndex]()
                tile.originalIndex = tileIndex
                
                if (tileIndex == 3)
                {
                    (tile as! tree).addBaseAngle(amount: Float(i).truncatingRemainder(dividingBy: 3.0) * .pi)
                }
                else if (tileIndex == 4)
                {
                    (tile as! rock).addBaseAngle(amount: Float(i).truncatingRemainder(dividingBy: 3.0) * .pi)
                }
                
                let posX = j * 2 - 19
                let posZ = i * 2 - 19
                
                tile.obj!.position = SCNVector3(posX, 0, posZ)
                
                row.append(tile)
                self.gameScene.rootNode.addChildNode(tile.obj!)
            }
            
            self.tiles.append(row)
        }
    }
    
    func resetTiles()
    {
        // for each row, sort them
        for i: Int in 0...tiles.count - 1
        {
            quickSortTiles(tileList: &tiles[i], low: 0, high: tiles.count - 1)
        }
        // then sort the rows based on the lowest element
        quickSort2DTiles(tileList: &tiles, low: 0, high: tiles.count - 1)
        
        // now resetting graphics to match current array
        
        for i in 0...19
        {
            for j in 0...19
            {
                let tile = tiles[i][j]
                
                let posX = j * 2 - 19
                let posZ = i * 2 - 19
                
                tile.obj?.position = SCNVector3(posX, 0, posZ)
            }
        }
    }
    
    func quickSortTiles(tileList: inout [Tile], low: Int, high: Int)
    {
        if (low >= high || low < 0)
        {
            return
        }
        
        let p = partition(tileList: &tileList, low: low, high: high)
        
        quickSortTiles(tileList: &tileList, low: low, high: p - 1)
        quickSortTiles(tileList: &tileList, low: p + 1, high: high)
    }
    
    func quickSort2DTiles(tileList: inout [[Tile]], low: Int, high: Int)
    {
        if (low >= high || low < 0)
        {
            return
        }
        
        let p = partition2D(tileList: &tileList, low: low, high: high)
        
        quickSort2DTiles(tileList: &tileList, low: low, high: p - 1)
        quickSort2DTiles(tileList: &tileList, low: p + 1, high: high)
    }
    
    func partition(tileList: inout [Tile], low: Int, high: Int) -> Int
    {
        let pivot = tileList[high]
        
        var i = low
        
        for j: Int in low...high - 1
        {
            if (tileList[j].originalIndex! <= pivot.originalIndex!)
            {
                tileList.swapAt(i, j)
                i += 1
            }
        }
        
        tileList.swapAt(i, high)
        return i
    }
    
    func partition2D(tileList: inout [[Tile]], low: Int, high: Int) -> Int
    {
        let pivot = tileList[high]
        
        var i = low
        
        for j: Int in low...high - 1
        {
            if (tileList[j][0].originalIndex! <= pivot[0].originalIndex!)
            {
                tileList.swapAt(i, j)
                i += 1
            }
        }
        
        tileList.swapAt(i, high)
        return i
    }
    
    func buildLights()
    {
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.intensity = 1200
        lightNode.eulerAngles = SCNVector3(-.pi / 2, 0.0, 0.0)
        
        self.gameScene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.white
        ambientLightNode.light!.intensity = 1100
        self.gameScene.rootNode.addChildNode(ambientLightNode)
        
        self.lights = [lightNode, ambientLightNode]
    }
    
    //TODO: Combine spotlight with scroll level so I only have to loop once
    func spotLightUpdate(pos: SCNVector3, rad: Float)
    {
        let squaredRad = rad * rad
        
        // loop through all blocks
        for i: Int in 0...(tiles.count - 1)
        {
            let row = tiles[i]
            
            for j: Int in 0...(row.count - 1)
            {
                // get squared dist to block
                let curTile = tiles[i][j].obj!
                let curPos = curTile.position
                let squaredDist = pow((curPos.x - pos.x), 2.0) + pow((curPos.z - pos.z), 2.0)
                
                // check if block is in radius
                if (squaredRad > squaredDist)
                {
                    // yes, set active
                    curTile.isHidden = false
                    
                }
                else
                {
                    // no, set inactive
                    curTile.isHidden = true
                    
                }
            }
        }
    }
    
    // tiles array gets flipped, but graphically we just move forward
    // 1 -> index 0 moves to 19
    // -1 -> index 19 moves to 0
    // 0 -> nothing happens
    // only one direction at a time, so will return after one move
    func scrollLevel(move: SCNVector3)
    {
        if (abs(move.x) > 0.1)
        {
            for i: Int in 0...(tiles.count - 1)
            {
                let row = tiles[i]
                
                let leftMost = row[0]
                let rightMost = row[row.count - 1]
                
                if (move.x > 0.1)
                {
                    // get leftmost index, move to right
                    leftMost.obj!.position = rightMost.obj!.position + SCNVector3(2.0, 0.0, 0.0)
                    // remove leftmost index, place at end
                    tiles[i].remove(at: 0)
                    tiles[i].append(leftMost)
                }
                else
                {
                    // get rightmost index, move to left
                    rightMost.obj!.position = leftMost.obj!.position + SCNVector3(-2.0, 0.0, 0.0)
                    // remove last index, insert at beginning
                    tiles[i].remove(at: row.count - 1)
                    tiles[i].insert(rightMost, at: 0)
                }
            }
            
            return
        }
        
        if (abs(move.z) > 0.1)
        {
            let topMost = tiles[0]
            let bottomMost = tiles[tiles.count - 1]
            
            for i: Int in 0...(topMost.count - 1)
            {
                
                if (move.z > 0.1)
                {
                    let curBot = bottomMost[i]
                    topMost[i].obj!.position = curBot.obj!.position + SCNVector3(0.0, 0.0, 2.0)
                }
                else
                {
                    let curTop = topMost[i]
                    bottomMost[i].obj!.position = curTop.obj!.position + SCNVector3(0.0, 0.0, -2.0)
                }
            }
            
            if (move.z > 0.1)
            {
                // moving south, remove first row, and insert at end
                tiles.remove(at: 0)
                tiles.append(topMost)
            }
            else
            {
                // moving north, remove last row, and insert at index 0
                tiles.remove(at: tiles.count - 1)
                tiles.insert(bottomMost, at: 0)
            }
            
            return
        }
    }
    
    // checks if given move will cross a block that player is allowed to move on
    func canMove(movement: SCNVector3) -> Bool
    {
        return searchTiles(movement: movement).canWalk
    }
    
    // finds tile at position, and returns it
    // player will always be at (1.0, 2.0, 1.0),
    // so we can always check from there
    func searchTiles(movement: SCNVector3) -> Tile
    {
        return tiles[10 + Int(movement.z)][10 + Int(movement.x)]
    }
    
    func updateWaterFreshness(amount: Float)
    {
        for i: Int in 0...tiles.count - 1
        {
            for j: Int in 0...tiles[i].count - 1
            {
                let theTile: Tile = tiles[i][j]
                
                if (theTile.type == 2)
                {
                    theTile.updateFreshness(amount: amount)
                }
            }
        }
    }
    
    //TODO: parse csv file for freshness numbers
    func readFreshness(text: String) -> [String]
    {
        return text.components(separatedBy: ",")
    }
    
    deinit{
        print("level deallocated")
    }
}

//Helper Functions

// Input file name, return text in file
public func readTextFile(_ fileName: String) -> String
{
    var text = ""
    
    if let path = Bundle.main.path(forResource: fileName, ofType: "txt") {
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            text = data
        } catch {
            print(error)
        }
    }

    return text
}

// TODO: write to text file, send email??
public func updateTextFile(_ fileName: String, contents: String)
{
    /*
    var smtpSession = MCOSMTPSession()
    smtpSession.hostname = "smtp.gmail.com"
    smtpSession.username = "matt@gmail.com"
    smtpSession.password = "xxxxxxxxxxxxxxxx"
    smtpSession.port = 465
    smtpSession.authType = MCOAuthType.SASLPlain
    smtpSession.connectionType = MCOConnectionType.TLS
    smtpSession.connectionLogger = {(connectionID, type, data) in
        if data != nil {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding){
                NSLog("Connectionlogger: \(string)")
            }
        }
    }

    var builder = MCOMessageBuilder()
    builder.header.to = [MCOAddress(displayName: "Rool", mailbox: "itsrool@gmail.com")]
    builder.header.from = MCOAddress(displayName: "Matt R", mailbox: "matt@gmail.com")
    builder.header.subject = "My message"
    builder.htmlBody = "Yo Rool, this is a test message!"

    let rfc822Data = builder.data()
    let sendOperation = smtpSession.sendOperationWithData(rfc822Data)
    sendOperation.start { (error) -> Void in
        if (error != nil) {
            NSLog("Error sending email: \(error)")
        } else {
            NSLog("Successfully sent email!")
        }
    }
     */
}
