//
//  GameOverScene.swift
//  Zombie
//
//  Created by Kaiserdem on 22.12.2019.
//  Copyright © 2019 Kaiserdem. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
  
  let won: Bool
  
   init(size: CGSize, won: Bool) {
    self.won = won
    super.init(size: size)
  }
  
  override func didMove(to view: SKView) {
    var bacground: SKSpriteNode
    if won {
      bacground = SKSpriteNode(imageNamed: "YouWin")
      run(SKAction.playSoundFileNamed("win.wav", waitForCompletion: false))
    } else {
      bacground = SKSpriteNode(imageNamed: "YouLose")
      run(SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false))
    }
    bacground.position = CGPoint(x: size.width / 2, y: size.height / 2)
    self.addChild(bacground)
    
    let wait = SKAction.wait(forDuration: 3.0)
    let block = SKAction.run {
      let myScene = GameScene(size: self.size)
      myScene.scaleMode = self.scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      self.view?.presentScene(myScene, transition: reveal)
    }
    self.run(SKAction.sequence([wait, block]))
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
