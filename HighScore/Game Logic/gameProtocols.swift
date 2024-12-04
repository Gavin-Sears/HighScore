//
//  gameProtocols.swift
//  Simple3DGame
//
//  Created by Stephen Sears on 7/21/24.
//  Modified for "High Score" on 12/4/24.
//

import Foundation
import SceneKit

protocol Tile
{
    var freshness: Float { get set }
    var obj: SCNNode? { get set }
    
    init()
    init(cloneOf: Tile)
    
    func updateFreshness(amount: Float)
}

protocol Entity
{
    var moveSpeed: Float { get set }
    var obj: SCNNode { get set }
}
