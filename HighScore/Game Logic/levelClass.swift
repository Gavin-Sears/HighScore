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
    private var tiles: [Tile] = []
    public var gameScene: SCNScene
    public var gameView: SCNView
    // Width, Length, Height
    private var levelSize: [Int] = [1, 1, 1]
    private var tileArray: [Tile] = []
    private var lights: [SCNNode] = []
    
    func replaceIndex(pos: SCNVector3, replacement: Int, index: Int)
    {
        let newBlock = air()
        
        if let oldObject = self.tiles[index].obj
        {
            oldObject.runAction(SCNAction.scale(to: 1.5, duration: 0.3), completionHandler:{() -> Void in
                oldObject.removeFromParentNode()})
        }
        
        self.tiles[index] = newBlock
        if let object = newBlock.obj
        {
            object.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
            object.position = pos
            self.gameView.scene!.rootNode.addChildNode(object)
            object.runAction(SCNAction.scale(to: 1.0, duration: 0.3))
        }
    }
    
    func getTiles() -> [Tile]
    {
        return self.tiles
    }
    
    init(file: String, height: Int, gameView: SCNView)
    {
        
        self.gameScene = SCNScene()
        self.gameView = gameView
        // To let the sky influence the lighting:
        self.gameScene.lightingEnvironment.contents = self.gameScene.background.contents
        
        self.lights = []
        self.tiles = []
    }
    
    func getLevelSize() -> [Int]
    {
        return levelSize
    }
    
    func buildLights(data: [SCNNode]) -> [SCNNode]
    {
        for light in data
        {
            gameScene.rootNode.addChildNode(light)
        }
        
        return data
    }
    
    func buildTiles(map: [String], tileIDs: [Int], height: Int) -> [Tile]
    {
        var tiles: [Tile] = []
        
        let width = self.levelSize[0]
        let length = self.levelSize[1]
        self.levelSize[2] = height
        
        return tiles
    }
    
    func readData(text: String) -> [String]
    {
        return text.components(separatedBy: ",")
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
