//
//  LoadingScreenViewController.swift
//  HighScore
//
//  Created by Stephen Sears on 12/7/24.
//

import Foundation
import UIKit

class LoadingScreenViewController : UIViewController
{
    public weak var gameController: GameViewController?
    
    override func viewDidAppear(_ animated: Bool)
    {
        self.gameController = self.storyboard!.instantiateViewController(withIdentifier: "game_view_controller") as? GameViewController
        
        gameController?.modalPresentationStyle = .overFullScreen
        gameController?.modalTransitionStyle = .crossDissolve
        gameController?.presentingController = self
        
        self.show(gameController!, sender: self)
    }
    
    public func reload()
    {
        self.gameController.myUnwindAction()
        self.gameController = nil
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        self.gameController = storyboard.instantiateViewController(withIdentifier: "game_view_controller") as? GameViewController
        
        gameController?.modalPresentationStyle = .overFullScreen
        gameController?.modalTransitionStyle = .crossDissolve
        gameController?.presentingController = self
        
        self.show(gameController!, sender: self)
    }
}
