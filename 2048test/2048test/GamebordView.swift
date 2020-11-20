//
//  GamebordView.swift
//  2048test
//
//  Created by 韦子龙 on 2020/11/17.
//

import UIKit


//游戏面板view，同时实现一些对TileView的移动、插入等操作
class GamebordView : UIView {
    
    var dimension : Int//每行(列)区块个数
    var tileWidth : CGFloat//每个小块的宽度
    var tilePadding : CGFloat//每个小块间的间距
    //初始化，其中backgroundColor是游戏区块的背景色，foregroundColor是小块的颜色
    let provider = AppearanceProvider()
    
    let tilePopStartScale: CGFloat = 0.1
    let tilePopMaxScale: CGFloat = 1.1
    let tilePopDelay: TimeInterval = 0.05
    let tileExpandTime: TimeInterval = 0.18
    let tileContractTime: TimeInterval = 0.08
    
    let tileMergeStartScale: CGFloat = 1.0
    let tileMergeExpandTime: TimeInterval = 0.08
    let tileMergeContractTime: TimeInterval = 0.08
    
    let perSquareSlideDuration: TimeInterval = 0.08
    
    //存储TileView小方块
    var tiles : Dictionary<NSIndexPath , TileView>
    
    init(dimension d : Int, titleWidth width : CGFloat, titlePadding padding : CGFloat, backgroundColor : UIColor, foregroundColor : UIColor ) {
        dimension = d
        tileWidth = width
        tilePadding = padding
        tiles = Dictionary()
        let totalWidth = tilePadding + CGFloat(dimension)*(tilePadding + tileWidth)
        super.init(frame : CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: totalWidth, height: totalWidth)))
        setColor(backgroundColor: backgroundColor , foregroundColor: foregroundColor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(backgroundColor bgcolor : UIColor, foregroundColor forecolor : UIColor){
        self.backgroundColor = bgcolor
        var xCursor = tilePadding
        var yCursor : CGFloat
        
        for _ in 0..<dimension{
            yCursor = tilePadding
            for _ in 0..<dimension {
                let tileFrame = UIView(frame : CGRect(x: xCursor, y: yCursor, width: tileWidth, height: tileWidth))
                tileFrame.backgroundColor = forecolor
                tileFrame.layer.cornerRadius = 8
                addSubview(tileFrame)
                yCursor += tilePadding + tileWidth
            }
            xCursor += tilePadding + tileWidth
        }
        
    }
    
    

    func reset() {
        for (_, tile) in tiles {
            tile.removeFromSuperview()
        }
        tiles.removeAll(keepingCapacity: true)
    }

    
    //创建TileView并显示
    func insertTile(pos : (Int , Int) , value : Int) {
        assert(positionIsValied(position: pos))
        let (row , col) = pos
        //取出当前数字块的左上角坐标(相对于游戏区块)
        let x = tilePadding + CGFloat(row)*(tilePadding + tileWidth)
        let y = tilePadding + CGFloat(col)*(tilePadding + tileWidth)
        let tileView = TileView(position : CGPoint(x: x, y: y), width: tileWidth, value: value, delegate: provider)
        addSubview(tileView)
        bringSubviewToFront(tileView)
        
        tiles[NSIndexPath(row : row , section:  col)] = tileView
        //这里就是一些动画效果，如果有兴趣可以研究下，不影响功能
        /*UIView.animate(withDuration: tileExpandTime, delay: tilePopDelay, options: UIView.AnimationOptions.TransitionNone,
            animations: {
                tileView.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
            },
            completion: { finished in
                UIView.animateWithDuration(self.tileContractTime, animations: { () -> Void in
                tileView.layer.setAffineTransform(CGAffineTransformIdentity)
            })
        })*/
    }
    
    func positionIsValied(position : (Int , Int)) -> Bool{
        let (x , y) = position
        return x >= 0 && x < dimension && y >= 0 && y < dimension
    }
    
    
    
    //移动一个小方块
    func moveOneTiles(from : (Int , Int)  , to : (Int , Int) , value : Int) {
        let (fx , fy) = from
        let (tx , ty) = to
        let fromKey = NSIndexPath(row: fx , section: fy)
        let toKey = NSIndexPath(row: tx, section: ty)
        
        guard let tile = tiles[fromKey] else{
            assert(false, "not exists tile")
        }
        let endTile = tiles[toKey]
        
        var changeFrame = tile.frame
        changeFrame.origin.x = tilePadding + CGFloat(tx)*(tilePadding + tileWidth)
        changeFrame.origin.y = tilePadding + CGFloat(ty)*(tilePadding + tileWidth)
        
        //tiles.removeValueForKey(fromKey)
        tiles.removeValue(forKey: fromKey)
        tiles[toKey] = tile
        
        // Animate
        let shouldPop = endTile != nil
        UIView.animate(withDuration: perSquareSlideDuration,
                                   delay: 0.0,
                                   options: UIView.AnimationOptions.beginFromCurrentState,
                                   animations: {
                                    // Slide tile
                                    tile.frame = changeFrame
            },
                                   completion: { (finished: Bool) -> Void in
                                    tile.value = value
                                    endTile?.removeFromSuperview()
                                    if !shouldPop || !finished {
                                        return
                                    }
                                    tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                                    // Pop tile
                                    UIView.animate(withDuration: self.tileMergeExpandTime,
                                        animations: {
                                            tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                                        },
                                        completion: { finished in
                                            // Contract tile to original size
                                            UIView.animate(withDuration: self.tileMergeContractTime) {
                                                tile.layer.setAffineTransform(.identity)
                                            }
                                    })
        })
    }
    
    
    
    //移动两个小方块（合并）
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(positionIsValid(pos: from.0) && positionIsValid(pos: from.1) && positionIsValid(pos: to))
        let (fromRowA, fromColA) = from.0
        let (fromRowB, fromColB) = from.1
        let (toRow, toCol) = to
        let fromKeyA = NSIndexPath(row: fromRowA, section: fromColA)
        let fromKeyB = NSIndexPath(row: fromRowB, section: fromColB)
        let toKey = NSIndexPath(row: toRow, section: toCol)
        
        guard let tileA = tiles[fromKeyA] else {
            assert(false, "placeholder error")
        }
        guard let tileB = tiles[fromKeyB] else {
            assert(false, "placeholder error")
        }
        
        var finalFrame = tileA.frame
        finalFrame.origin.x = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)
        finalFrame.origin.y = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
        
        let oldTile = tiles[toKey]
        oldTile?.removeFromSuperview()
        //tiles.removeValueForKey(fromKeyA)
        //tiles.removeValueForKey(fromKeyB)
        tiles.removeValue(forKey: fromKeyA)
        tiles.removeValue(forKey: fromKeyB)
        tiles[toKey] = tileA
        
        UIView.animate(withDuration: perSquareSlideDuration,
                                   delay: 0.0,
                                   options: UIView.AnimationOptions.beginFromCurrentState,
                                   animations: {
                                    // Slide tiles
                                    tileA.frame = finalFrame
                                    tileB.frame = finalFrame
            },
                                   completion: { finished in
                                    tileA.value = value
                                    tileB.removeFromSuperview()
                                    if !finished {
                                        return
                                    }
                                    tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                                    // Pop tile
                                    UIView.animate(withDuration: self.tileMergeExpandTime,
                                        animations: {
                                            tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                                        },
                                        completion: { finished in
                                            // Contract tile to original size
                                            UIView.animate(withDuration: self.tileMergeContractTime) {
                                                tileA.layer.setAffineTransform(.identity)
                                            }
                                    })
        })
    }
    
    
    func positionIsValid(pos: (Int, Int)) -> Bool {
        let (x, y) = pos
        return (x >= 0 && x < dimension && y >= 0 && y < dimension)
    }
    
}
