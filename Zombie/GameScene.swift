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
  let zombieAnimtion: SKAction // анимация бега
  let catCillisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
  let enemyCillisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
  var lives = 10
  var gameOver = false
  var invincible = false
  let catMovePointsPerSec:CGFloat = 480.0
  let cameraNode = SKCameraNode()
  let cameraMovePointsPerSec: CGFloat = 200.0 // скорость камеры
  let livesLabel = SKLabelNode(fontNamed: "Glimstick")
  let countCats = SKLabelNode(fontNamed: "Glimstick")
  
  var cameraRect: CGRect { // видимый прямоугольник
    let x = cameraNode.position.x - size.width / 2
      + (size.width - playableRect.size.width) / 2
    let y = cameraNode.position.y - size.width / 2
      + (size.height - playableRect.size.height) / 2
    return CGRect(x: x,
                  y: y,
                  width: playableRect.width,
                  height: playableRect.height)
    
  }
  
  override init(size: CGSize) {
    let maxAspectRatio: CGFloat = 16.0 / 9.0
    let playableHight = size.width / maxAspectRatio
    let playableMargin = (size.height - playableHight) / 2.0
    playableRect = CGRect(x: 0,
                          y: playableMargin,
                          width: size.width,
                          height: playableHight)
    
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
    
    playBackgroundMusic(fileName: "backgroundMusic.mp3")
    
    for i in 0...1 {

      let background = backgroundNode()
      background.anchorPoint = CGPoint.zero
      background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
      background.zPosition = -1
      background.name = "background"
      addChild(background)
    }
    
    zombie.position = CGPoint(x: 400, y: 400)
    zombie.zPosition = 100
    addChild(zombie)
    
    run(SKAction.repeatForever(
      SKAction.sequence([SKAction.run() { [weak self] in
        self?.spawnEnemy()
        },
                         SKAction.wait(forDuration: 2.0)])))
    
    run(SKAction.repeatForever(
      SKAction.sequence([SKAction.run() { [weak self] in
        self?.spawnCat()
        },
                         SKAction.wait(forDuration: 1.0)])))
    
    addChild(cameraNode)
    camera = cameraNode
    // зомби по середине камеры
    cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    
    livesLabel.text = "Lives: X"
    livesLabel.fontColor = SKColor.black
    livesLabel.fontSize = 100
    livesLabel.zPosition = 150
    livesLabel.horizontalAlignmentMode = .left
    livesLabel.verticalAlignmentMode = .bottom
    livesLabel.position = CGPoint(x: -playableRect.size.width / 2 + CGFloat(20), y:  -playableRect.size.height / 2 + CGFloat(20))
    cameraNode.addChild(livesLabel)
    
    countCats.text = "Cats: 0"
    countCats.fontColor = SKColor.black
    countCats.fontSize = 100
    countCats.zPosition = 150
    countCats.horizontalAlignmentMode = .right
    countCats.verticalAlignmentMode = .bottom
    countCats.position = CGPoint(x: playableRect.size.width / 2 - CGFloat(10), y:  -playableRect.size.height / 2 + CGFloat(20))
    cameraNode.addChild(countCats)
    
  }
  
  func moveCamera() { // двигает камеру
    
    let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
    let amountToMove = backgroundVelocity * CGFloat(dt)
    cameraNode.position += amountToMove
    
    enumerateChildNodes(withName: "background") { (node, _) in
      let background = node as! SKSpriteNode
      if background.position.x + background.size.width < self.cameraRect.origin.x {
        background.position = CGPoint(x: background.position.x + background.size.width * 2,
                                      y: background.position.y)
      }
    }
  }
  
  func backgroundNode() -> SKSpriteNode { // создали бекграунд с двух картинок
    
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"
    
    let background1 = SKSpriteNode(imageNamed: "background1")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    let background2 = SKSpriteNode(imageNamed: "background2")
    background2.anchorPoint = CGPoint.zero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
    
    backgroundNode.size = CGSize(width: background1.size.width + background2.size.width, height: background1.size.height)
    return backgroundNode
    
  }
  
  // вызываеться после метода update, когда все екшены сделаны
  override func didEvaluateActions() {
    checkCollisions()
  }
  
  func loseCat() { // когда столкновение с enemy коты убавляються
    var loseCount = 0
    enumerateChildNodes(withName: "train") { (node, stop) in
      var randomSpot = node.position
      randomSpot.x += CGFloat.random(min: -100, max: 100)
      randomSpot.y += CGFloat.random(min: -100, max: 100)
      node.name = ""
      node.run(
        SKAction.sequence([
        SKAction.group([
        SKAction.rotate(byAngle: π*4, duration: 1.0), // крутиться на угол п 4
        SKAction.move(to: randomSpot, duration: 1.0), // двигаться в рандомном направление
        SKAction.scale(to: 0, duration: 1) // пропадет
        ]),
        SKAction.removeFromParent() // удалиться
        ]))
      loseCount += 1
      if loseCount >= 2 {
        stop[0] = true
      }
    }
  }
  
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                               y: velocity.y * CGFloat(dt))
    sprite.position += amountToMove
  }
  
  override func update(_ currentTime: TimeInterval) {
    
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    move(sprite: zombie, velocity: velocity)
    rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)

    boundsCheckZombie()
    moveTrain()
    moveCamera()
    
    livesLabel.text = "Lives: \(lives)"
    
    if lives <= 0 && !gameOver { // жизней нет и игра не закончена
      gameOver = true
      print("You Lose!")
      backgroundMusicPlayer.stop()
      
      let gameOverScene = GameOverScene(size: size, won: false) // переход на другую сцену
      gameOverScene.scaleMode = scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5) // анимация появления
      view?.presentScene(gameOverScene, transition: reveal)
    }
    
    // камера следит за зомби, он всегда по середине
    //cameraNode.position = zombie.position
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
    let bottomLeft = CGPoint(x: cameraRect.minX, y: playableRect.minY)
    let topRight = CGPoint(x: cameraRect.maxX, y: playableRect.maxY)
    
    if zombie.position.x <= bottomLeft.x {
      zombie.position.x = bottomLeft.x
      velocity.x = abs(velocity.x)
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
    enemy.position = CGPoint(x: cameraRect.maxX + enemy.size.width/2,
                             y: CGFloat.random(
                              min: cameraRect.minY + enemy.size.height/2,
                              max: cameraRect.maxY - enemy.size.height/2))
    enemy.zPosition = 50
    enemy.name = "enemy"
    addChild(enemy)
    
    let actionMove = SKAction.moveTo(x: -enemy.size.width / 2, duration: 2.0)
    let actionRemove = SKAction.removeFromParent() // удалить
    enemy.run(SKAction.sequence([actionMove, actionRemove]))
    
  }
  
  func spawnCat() {
    let cat = SKSpriteNode(imageNamed: "cat")
    cat.name = "cat"
    cat.position = CGPoint(x: CGFloat.random(min: cameraRect.minX,
                                             max: cameraRect.maxX),
                           y: CGFloat.random(min: cameraRect.minY,
                                             max: cameraRect.maxY))
    cat.zPosition = 50
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
  
  // когда обьекты пересекаються
  func zombieHit(cat: SKSpriteNode) {
    cat.name = "train"
    cat.removeAllActions()
    cat.setScale(1.0)
    cat.zRotation = 0
    
    let turnGreen = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
    cat.run(turnGreen)
    
    run(catCillisionSound)
  }
  
  func zombieHit(enemy: SKSpriteNode) {
    invincible = true
    let blinkTimes = 10.0
    let duration = 3.0
    let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
      let slice = duration / blinkTimes
      let remainder = Double(elapsedTime).truncatingRemainder(
        dividingBy: slice)
      node.isHidden = remainder > slice / 2
    }
    let setHidden = SKAction.run() { [weak self] in
      self?.zombie.isHidden = false
      self?.invincible = false
    }
    zombie.run(SKAction.sequence([blinkAction, setHidden]))
    
    run(enemyCillisionSound)
    loseCat()
    lives -= 1
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
    if invincible {
      return
    }
    
    var hitEnemies: [SKSpriteNode] = []
    enumerateChildNodes(withName: "enemy") { (node, _) in
      let enemy = node as! SKSpriteNode
      // insetBy сделали больше размер обьектыа
      if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) { // если фреймы пересекаються
        hitEnemies.append(enemy)
      }
    }
    for enemy in hitEnemies {
      zombieHit(enemy: enemy)
    }
  }
  
  
  
  
  func moveTrain() { // коты следуют за зомби
    var trainCount = 0
    var targetPosition = zombie.position
    
    enumerateChildNodes(withName: "train") { node, stop in
      trainCount += 1
      if !node.hasActions() {
        let actionDuration = 0.3
        let offset = targetPosition - node.position
        let direction = offset.normalized()
        let amountToMovePerSec = direction * self.catMovePointsPerSec
        let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
        let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
        node.run(moveAction)
      }
      targetPosition = node.position
    }
    self.countCats.text = "Cats: \(trainCount)"
    if trainCount >= 15 && !gameOver {
      gameOver = true
      print("You Win")
      backgroundMusicPlayer.stop()
      
      let gameOverScene = GameOverScene(size: size, won: true) // переход на другую сцену
      gameOverScene.scaleMode = scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5) // анимация появления
      view?.presentScene(gameOverScene, transition: reveal)
    }
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
