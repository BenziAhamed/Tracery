//: # Pixel Face Generator
//: Powered by [Tracery](https://github.com/BenziAhamed/Tracery)

import UIKit
import SpriteKit
import PlaygroundSupport
import Tracery


let view = SKView.init(frame: .init(x: 0, y: 0, width: 400, height: 400))
PlaygroundPage.current.liveView = view

var colors:[String: UIColor] = [
    "blk" : .black,
    "w": .white,
    "bg": UIColor(red:0.152, green:0.698, blue:0.962, alpha:1),
    "cheekcol": UIColor(hex: "f28fb2").withAlphaComponent(0.32),
    "skin-1": UIColor(hex: "ffcc80"),
    "skin-2": UIColor(hex: "ffb74d"),
    "skin-3": UIColor(hex: "ffa726"),
    "skin-4": UIColor(hex: "ff9800"),
    "skin-5": UIColor(hex: "fb8c00"),
    "skin-6": UIColor(hex: "f57c00"),
    "skin-8": UIColor(hex: "a1887f"),
    "skin-9": UIColor(hex: "8d6e63"),
    "skin-10": UIColor(hex: "795548"),
    "skin-11": UIColor(hex: "6d4c41"),
    "skin-12": UIColor(hex: "5d4037"),
]

/*:
 Our face is generated in a 8x8 block. We will exclusively use methods as the main mechanism to render the face. For example, the `.block` method is used to render a solid colored rectangle at the coordinates specified.
 */

var tracery = Tracery {[

    "face": "#.block(1,1,7,7,#skin#)#",
    "eyes": "#.set(2,4,w)# #.set(5,4,w)#",
    
    "neck": "#.xf(2,0,4,#skin-dark#)#",
    "mouth": "#.block(3,2,5,3,#lips#)#",
    "freckles": ["", "", "", "#.set(1,2,#skin-dark#)# #.set(6,3,#skin-dark#)#", "#.set(4,5,#skin-dark#)#", "#.xf(5,6,2,blk)#"],
    
    "cheeks": ["", "", "", "#.set(1,3,cheekcol)# #.set(6,3,cheekcol)#"],
    
    // various hairstyles
    "hair-neil": "#.block(1,7,7,8,blk)##.block(1,6,4,7,blk)#",
    "hair-latino" : "#.block(1,6,7,8,blk)##.set(4,6,blk)#",
    "hair-army2" : "#.block(1,7,7,8,blk)##.set(1,6,blk)##.set(3,6,blk)##.set(5,6,blk)#",
    "hair-army1" : "#.block(1,7,7,8,blk)#",
    "hair-chinese" : "#.block(0,3,1,8,blk)##.block(7,3,8,8,blk)##hair-army1##.set(3,6,blk)##.set(4,6,blk)#",
    "hair-fran": "#.yf(0,4,3,blk)##.xf(1,7,6,blk)##.xf(3,6,5,blk)##.xf(5,5,3,blk)##.set(6,4,blk)#",
    "hair-messi": "#.xf(1,7,6,blk)##.xf(0,6,4,blk)##.xf(5,6,2,blk)##.xf(4,5,2,blk)##.set(1,5,blk)#",
    "hair-alena": "#hair-army1# #.yf(0,3,4,blk)# #.yf(7,3,4,blk)# #.xf(0,6,4,blk)#",
    "hair-alice": "#hair-army1# #.yf(0,3,4,blk)# #.yf(7,3,4,blk)# #.yf(6,3,2,blk)# #.xf(2,5,2,blk)# #.set(4,6,blk)#",
    
    "hair-opts" : "neil latino army1 army2 fran messi alena alice".components(separatedBy: " "),
    
    // select a hair-style
    "initHair": "[hair:\\#hair-#hair-opts#\\#]",
    
    // select and set skin tone colors
    "initSkin": [
        "[skin:skin-1][skin-dark:skin-2][lips:skin-3]",
        "[skin:skin-2][skin-dark:skin-3][lips:skin-4]",
        "[skin:skin-3][skin-dark:skin-4][lips:skin-5]",
        "[skin:skin-4][skin-dark:skin-5][lips:skin-6]",
        "[skin:skin-8][skin-dark:skin-9][lips:skin-10]",
        "[skin:skin-9][skin-dark:skin-10][lips:skin-11]",
        "[skin:skin-10][skin-dark:skin-11][lips:skin-12]",
    ],
    
    // init
    "init": "#initHair# #initSkin#",
    
    // render a random face
    "gen" : "#init# #face# #eyes# #neck# #mouth# #freckles# #cheeks# #hair.eval#",
]}

class Scene : SKScene {
    
    var prevUpdateTime: TimeInterval? = nil
    var elapsed: CGFloat = 0
    let grid = SKNode()
    var zpos: CGFloat = 0
    
    override func didMove(to view: SKView) {
        size = view.frame.size
        backgroundColor = colors["bg"]!
        grid.position = CGPoint(x: 80, y: 80)
        addChild(grid)
        setupTracery()
        generateFace()
    }
    
//: We create and attach the necessary methods to Tracery
    
    func setupTracery() {
        // fills a rectangular area 
        // with a solid color
        func fillBlock(_ args: [String]) -> String {
            let sx = CGFloat(Double(args[0]) ?? 0)
            let sy = CGFloat(Double(args[1]) ?? 0)
            let ex = CGFloat(Double(args[2]) ?? 1)
            let ey = CGFloat(Double(args[3]) ?? 1)
            let color = colors[args[4]]!
            
            let size = CGSize(width: (ex - sx) * 30, height: (ey - sy) * 30)
            let block = SKSpriteNode(color: color, size: size)
            block.anchorPoint = .zero
            block.position = CGPoint.init(x: 30 * sx, y: 30 * sy)
            block.zPosition = zpos
            
            grid.addChild(block)
            return ""
        }
        
        
        tracery.add(method: "block") { _, args in
            return fillBlock(args)
        }
        
        
        // set an individial pixel
        tracery.add(method: "set") { _, args in
            let sx = Int(args[0]) ?? 0
            let sy = Int(args[1]) ?? 0
            let color = args[2]
            return fillBlock(["\(sx)","\(sy)","\(sx+1)","\(sy+1)",color])
        }
        
        // line across x axis
        tracery.add(method: "xf") { _, args in
            let sx = Int(args[0]) ?? 0
            let sy = Int(args[1]) ?? 0
            let count = Int(args[2]) ?? 0
            let color = args[3]
            return fillBlock(["\(sx)","\(sy)","\(sx+count)","\(sy+1)",color])
        }
        
        // line across y axis
        tracery.add(method: "yf") { _, args in
            let sx = Int(args[0]) ?? 0
            let sy = Int(args[1]) ?? 0
            let count = Int(args[2]) ?? 0
            let color = args[3]
            return fillBlock(["\(sx)","\(sy)","\(sx+1)","\(sy+count)",color])
        }
        
        tracery.add(modifier: "eval") { input in
            return tracery.expand(input, resetTags: false)
        }
    }
    
    
    
    func generateFace() {
        zpos = 0
        grid.removeAllChildren()
        _ = tracery.expand("#gen#")
    }
    
    
//: Generate a new face every second
    
    override func update(_ currentTime: TimeInterval) {
        elapsed += CGFloat(currentTime - (prevUpdateTime ?? currentTime))
        prevUpdateTime = currentTime
        guard elapsed >= 1 else { return }
        elapsed = 0
        generateFace()
    }
}

view.presentScene(Scene())

