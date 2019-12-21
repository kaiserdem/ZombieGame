//
//  GameScene.swift
//  Zombie
//
//  Created by Kaiserdem on 21.12.2019.
//  Copyright © 2019 Kaiserdem. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  let zombie = SKSpriteNode(imageNamed: "zombie1")
  
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  let zombieMovePointsPerSec: CGFloat = 480.0
  var velocity = CGPoint.zero // скорость
  
  let playableRect: CGRect // универсальный размер поля для всех екранов
  
  override init(size: CGSize) {
    let maxAspectRatio: CGFloat = 16.0 / 9.0
    let playableHight = size.width / maxAspectRatio
    let playableMargin = (size.height - playableHight) / 2.0
    playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHight)
    super.init(size: size)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
    override func didMove(to view: SKView) {
        
      backgroundColor = .black
      
      let background = SKSpriteNode(imageNamed: "background1")
      background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
      background.position = CGPoint(x: size.width / 2, y: size.height / 2)
      background.zPosition = -1
      addChild(background)
      
      zombie.position = CGPoint(x: 400, y: 400)
      addChild(zombie)
      
      debugDrawPlayableArea()
      
  }
  
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
    print(amountToMove)
    sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
  }
  
  func debugDrawPlayableArea() { // выделить граници екрана
    let shape = SKShapeNode()
    let path = CGMutablePath()
    path.addRect(playableRect)
    shape.path = path
    shape.strokeColor = SKColor.red
    shape.lineWidth = 4.0
    addChild(shape)
  }
  
  func moveZombieToward(location:CGPoint) { // напрявляться в эту точку
    let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
    let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
    let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
    velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
  }
  
  func sceneTouched(touchLocation: CGPoint) { // воспомагательная функция для передвижения
    moveZombieToward(location: touchLocation)
  }
  
  func rotate(sprite: SKSpriteNode, direction:CGPoint) { // повернуть обьект на угол
    sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
  }
  
  func boundsCheckZombie() { // не выходить за екран
    let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
    let topRight = CGPoint(x: size.width, y: playableRect.maxY)
    
    if zombie.position.x <= bottomLeft.x {
      zombie.position.x = bottomLeft.x
      velocity.x = -velocity.x
    }
    if zombie.position.x >= topRight.x {
      zombie.position.x = topRight.x
      velocity.x = -velocity.x
    }
    if zombie.position.y <= bottomLeft.y {
      zombie.position.y = bottomLeft.y
      velocity.y = -velocity.y
    }
    if zombie.position.y >= topRight.y {
      zombie.position.y = topRight.y
      velocity.y = -velocity.y
    }
  }
  
  override func update(_ currentTime: TimeInterval) {
    
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    //zombie.position = CGPoint(x: zombie.position.x + 8, y: zombie.position.y)
    print("\(dt*1000)")
    move(sprite: zombie, velocity: velocity)
    rotate(sprite: zombie, direction: velocity)
    
    boundsCheckZombie()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
}
