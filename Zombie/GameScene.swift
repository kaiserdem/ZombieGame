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
  var lastTouchLocation: CGPoint?
  let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
  let playableRect: CGRect // универсальный размер поля для всех екранов
  let zombieAnimtion: SKAction// анимация бега
  
  override init(size: CGSize) {
    let maxAspectRatio: CGFloat = 16.0 / 9.0
    let playableHight = size.width / maxAspectRatio
    let playableMargin = (size.height - playableHight) / 2.0
    playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHight)
    
    // анимация
    var textures: [SKTexture] = []
    
    for i in 1...4 {
      textures.append(SKTexture(imageNamed: "zombie\(i)"))
    }
    textures.append(textures[2])
    textures.append(textures[1])
    zombieAnimtion = SKAction.animate(with: textures, timePerFrame: 0.1)
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
      
      let mySize = background.size
      print("Size: \(mySize)")
      
      zombie.position = CGPoint(x: 400, y: 400)
      
      run(SKAction.repeatForever(SKAction.sequence([SKAction.run() { [weak self] in
        self?.spawnEnemy()
      }, SKAction.wait(forDuration: 2.0)])))
      
      
      run(SKAction.repeatForever(SKAction.sequence([SKAction.run() { [weak self] in
        self?.spawnCat()
      }, SKAction.wait(forDuration: 1.0)])))
      
      addChild(zombie)
      
      debugDrawPlayableArea()
      
  }
  
  override func didEvaluateActions() { // вызываеться после метода update
    <#code#>
  }
  
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                               y: velocity.y * CGFloat(dt))
    //print("Amount to move: \(amountToMove)")
    sprite.position += amountToMove
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
    startZombieAnimation()
    let offset = location - zombie.position
    
    let direction = offset.normalized()
    velocity = direction * zombieMovePointsPerSec
  }
  
  func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) { // поворот обьекта
    let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
    let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
    sprite.zRotation += shortest.sign() * amountToRotate
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
  
  func startZombieAnimation() {
    if zombie.action(forKey: "animation") == nil { //если у зомби нет екшене с таким ключем
      //тогда запускаем анимацию
      zombie.run(SKAction.repeatForever(zombieAnimtion), withKey: "animation")
    }
  }
  
  func stopZombieAnimation() {
    zombie.removeAction(forKey: "animation")
  }
  
  func spawnEnemy() { // бабуля
    
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.name = "enemy"
    enemy.position = CGPoint(x: size.width + enemy.size.width / 2, y:CGFloat.random(min: playableRect.minY + enemy.size.height / 2, max: playableRect.maxY - enemy.size.height / 2))
    addChild(enemy)
    
    let actionMove = SKAction.moveTo(x: -enemy.size.width / 2, duration: 2.0)
    let actionRemove = SKAction.removeFromParent() // удалить
    enemy.run(SKAction.sequence([actionMove, actionRemove]))
    
  }
  
  func spawnCat() {
    let cat = SKSpriteNode(imageNamed: "cat")
    cat.name = "cat"
    cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX, max: playableRect.maxX), y: CGFloat.random(min: playableRect.minY, max: playableRect.maxY))
    cat.setScale(0)
    addChild(cat)
    
    let appear = SKAction.scale(to: 1.0, duration: 0.5)
    //let wait = SKAction.wait(forDuration: 10.0)
    
    cat.zRotation = -π / 16.0
    let leftWiggle = SKAction.rotate(byAngle: π / 8.0, duration: 0.5)
    let rightWiggle = leftWiggle.reversed()
    let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
    //let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
    
    // груповые екшены
    let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
    let scaleDown = scaleUp.reversed()
    let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
    let group = SKAction.group([fullScale, fullWiggle])
    let groupWait = SKAction.repeat(group, count: 10)
    
    let disappear = SKAction.scale(to: 0, duration: 0.5)
    let removeFromParent = SKAction.removeFromParent()
    let actions = [appear, groupWait, disappear, removeFromParent]
    cat.run(SKAction.sequence(actions))
  }
  
  func zombieHit(cat: SKSpriteNode) { // когда обьекты пересекаються удалить
    cat.removeFromParent()
  }
  
  func zombieHit(enemy: SKSpriteNode) {
    enemy.removeFromParent()
  }
  
  func checkCollisions() { // пересекаються тогда удалить
    var hitCats: [SKSpriteNode] = []
    enumerateChildNodes(withName: "cat") { (node, _) in
      let cat = node as! SKSpriteNode
      if cat.frame.intersects(self.zombie.frame) { // если фреймы пересекаються
       hitCats.append(cat)
      }
    }
    for cat in hitCats {
      zombieHit(cat: cat)
    }
    
    
    var hitEnemies: [SKSpriteNode] = []
    enumerateChildNodes(withName: "enemy") { (node, _) in
      let enemy = node as! SKSpriteNode
                  // insetBy сделали больше размер обьектыа
      if enemy.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) { // если фреймы пересекаються
        hitEnemies.append(enemy)
      }
    }
    for enemy in hitEnemies {
      zombieHit(enemy: enemy)
    }
  }
  
  
  override func update(_ currentTime: TimeInterval) {
    
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    //print("\(dt*1000) milliseconds since last update")
    
    if let lastTouchLocation = lastTouchLocation {
      let diff = lastTouchLocation - zombie.position
      if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
        zombie.position = lastTouchLocation
        velocity = CGPoint.zero
        stopZombieAnimation()
      } else {
        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
      }
    }
    
    boundsCheckZombie()
    checkCollisions()
  }
  
  func sceneTouched(touchLocation: CGPoint) { // воспомагательная функция для передвижения
    lastTouchLocation = touchLocation
    moveZombieToward(location: touchLocation)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
}
