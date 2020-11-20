//
//  GameModel.swift
//  2048test
//
//  Created by 韦子龙 on 2020/11/17.
//

import Foundation
import UIKit



//逻辑面板
//实际进行计算
class GameModle : NSObject {

    let dimension : Int//面板大小
    let threshold : Int
    
    //存放数字块状态信息
    var gamebord : SequenceGamebordd<TileEnumm>

    unowned let delegate : GameModelProtocol
    
    //当前分数，改变后回调用分数视图渲染分数
    var score : Int = 0{
        didSet{
            delegate.changeScore(score: score)
        }
    }
    
    
    //初始化一个都存的Empty的SequenceGamebord<TileEnum>
    init(dimension : Int , threshold : Int , delegate : GameModelProtocol) {
        self.dimension = dimension
        self.threshold = threshold
        self.delegate = delegate
        gamebord = SequenceGamebordd(demision: dimension , initValue: TileEnumm.Empty)
        super.init()
    }
    
    
    
    
    
    //---------------move相关
        
        func queenMove(direction : MoveDirection , completion : (Bool) -> ()){
            let changed = performMove(direction: direction)
            completion(changed)
            
        }
        
        func performMove(direction : MoveDirection) -> Bool {
            
            let getMoveQueen : (Int) -> [(Int , Int)] = { (idx : Int) -> [(Int , Int)] in
                var buffer = Array<(Int , Int)>(repeating: (0, 0), count : self.dimension)
                for i in 0..<self.dimension {
                    switch direction {
                    case .UP : buffer[i] = (idx, i)
                    case .DOWN : buffer[i] = (idx, self.dimension - i - 1)
                    case .LEFT : buffer[i] = (i, idx)
                    case .RIGHT : buffer[i] = (self.dimension - i - 1, idx)
                    }
                }
                return buffer
            }
            
            var movedFlag = false
            for i in 0..<self.dimension {
                let moveQueen = getMoveQueen(i)
                let tiles = moveQueen.map({ (c : (Int, Int)) -> TileEnumm in
                    let (source , value) = c
                    return self.gamebord[source , value]
                })
                
                let moveOrders = merge(group: tiles)
                movedFlag = moveOrders.count > 0 ? true : movedFlag
                
                for order in moveOrders {
                    switch order {
                    case let .SINGLEMOVEORDER(s, d, v, m):
                        let (sx, sy) = moveQueen[s]
                        let (dx, dy) = moveQueen[d]
                        if m {
                            self.score += v
                        }
                        gamebord[sx , sy] = TileEnumm.Empty
                        gamebord[dx , dy] = TileEnumm.Tile(v)
                        
                        delegate.moveOneTile(from: (sx, sy), to: (dx, dy), value: v)
                    case let .DOUBLEMOVEORDER(fs , ts , d , v):
                        let (fsx , fsy) = moveQueen[fs]
                        let (tsx , tsy) = moveQueen[ts]
                        let (dx , dy) = moveQueen[d]
                        self.score += v
                        gamebord[fsx , fsy] = TileEnumm.Empty
                        gamebord[tsx , tsy] = TileEnumm.Empty
                        gamebord[dx , dy] = TileEnumm.Tile(v)
                        
                        delegate.moveTwoTiles(from: (moveQueen[fs], moveQueen[ts]), to: moveQueen[d], value: v)
                        
                    }
                }
            }
            return movedFlag
        }
        
        func tileBelowHasSameValue(location: (Int, Int), _ value: Int) -> Bool {
            let (x, y) = location
            guard y != dimension - 1 else {
                return false
            }
            if case let .Tile(v) = gamebord[x, y+1] {
                return v == value
            }
            return false
        }
        
        func tileToRightHasSameValue(location: (Int, Int), _ value: Int) -> Bool {
            let (x, y) = location
            guard x != dimension - 1 else {
                return false
            }
            if case let .Tile(v) = gamebord[x+1, y] {
                return v == value
            }
            return false
        }
        
        func reset() {
            score = 0
            gamebord.setAll(value: .Empty)
        }

        
        func userHasLost() -> Bool {
            guard getEmptyPosition().isEmpty else {
                // Player can't lose before filling up the board
                return false
            }
            
            // Run through all the tiles and check for possible moves
            for i in 0..<dimension {
                for j in 0..<dimension {
                    switch gamebord[i, j] {
                    case .Empty:
                        assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
                    case let .Tile(v):
                        if tileBelowHasSameValue(location:(i, j), v) || tileToRightHasSameValue(location:(i, j), v) {
                            return false
                        }
                    }
                }
            }
            return true
        }
        
        func userHasWon() -> (Bool, (Int, Int)?) {
            for i in 0..<dimension {
                for j in 0..<dimension {
                    // Look for a tile with the winning score or greater
                    if case let .Tile(v) = gamebord[i, j], v >= threshold {
                        return (true, (i, j))
                    }
                }
            }
            return (false, nil)
        }

        
    
    
    //--------------------------插入Tile相关
    
    //取出游戏区中空置的块
    //通过遍历SequenceGamebord<TileEnum>，将不为空的位置组成一个(Int , Int)的字典数组返回。
    func getEmptyPosition() -> [(Int , Int)]  {
        var emptyArrys : [(Int , Int)] = []
        for i in 0..<dimension {
            for j in 0..<dimension {
                if case .Empty = gamebord[i , j] {
                    emptyArrys.append((i , j))
                }
            }
        }
        return emptyArrys
    }
    
    
    //随机插入
    //取出当前所有的空的位置数组，在随机一个数组中的位置，之后赋值给gamebord以及调用游戏视图层渲染出新的游戏区块
    func insertRandomPositoinTile(value : Int)  {
        let emptyArrays = getEmptyPosition()
        if emptyArrays.isEmpty {
            return
        }
        let randomPos = Int(arc4random_uniform(UInt32(emptyArrays.count - 1)))
        let (x , y) = emptyArrays[randomPos]
        gamebord[x , y] = TileEnumm.Tile(value)
        delegate.insertTile(position: (x , y), value: value)
    }
    
    
    
    
    /* 算法相关－－－－－－－－－－－－ */
       
       func merge(group : [TileEnumm]) -> [MoveOrder] {
        return convert(group: collapse(group: condense(group: group)))
       }
       
       //去除空   如：|2| | |2|去掉空为：|2|2| | |
       func condense(group : [TileEnumm]) -> [TileAction] {
           var buffer = [TileAction]()
           for (index , tile) in group.enumerated(){
               switch tile {
               case let .Tile(value) where buffer.count == index :
                   buffer.append(TileAction.NOACTION(source: index, value: value))
               case let .Tile(value) :
                   buffer.append(TileAction.MOVE(source: index, value: value))
               default:
                   break
               }
           }
           return buffer
       }
       
       //合并相同的    如：|2| | 2|2|合并为：|4|2| | |
       func collapse(group : [TileAction]) -> [TileAction] {
           
           var tokenBuffer = [TileAction]()
           var skipNext = false
           for (idx, token) in group.enumerated() {
               if skipNext {
                   // Prior iteration handled a merge. So skip this iteration.
                   skipNext = false
                   continue
               }
               switch token {
               case .SINGLECOMBINE:
                   assert(false, "Cannot have single combine token in input")
               case .DOUBLECOMBINE:
                   assert(false, "Cannot have double combine token in input")
               case let .NOACTION(s, v)
                   where (idx < group.count-1
                       && v == group[idx+1].getValue()
                            && GameModle.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s)):
                   // This tile hasn't moved yet, but matches the next tile. This is a single merge
                   // The last tile is *not* eligible for a merge
                   let next = group[idx+1]
                   let nv = v + group[idx+1].getValue()
                   skipNext = true
                   tokenBuffer.append(TileAction.SINGLECOMBINE(source: next.getSource(), value: nv))
               case let t where (idx < group.count-1 && t.getValue() == group[idx+1].getValue()):
                   // This tile has moved, and matches the next tile. This is a double merge
                   // (The tile may either have moved prevously, or the tile might have moved as a result of a previous merge)
                   // The last tile is *not* eligible for a merge
                   let next = group[idx+1]
                   let nv = t.getValue() + group[idx+1].getValue()
                   skipNext = true
                   tokenBuffer.append(TileAction.DOUBLECOMBINE(firstSource: t.getSource(), secondSource: next.getSource(), value: nv))
               case let .NOACTION(s, v) where !GameModle.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s):
                   // A tile that didn't move before has moved (first cond.), or there was a previous merge (second cond.)
                   tokenBuffer.append(TileAction.MOVE(source: s, value: v))
               case let .NOACTION(s, v):
                   // A tile that didn't move before still hasn't moved
                   tokenBuffer.append(TileAction.NOACTION(source: s, value: v))
               case let .MOVE(s, v):
                   // Propagate a move
                   tokenBuffer.append(TileAction.MOVE(source: s, value: v))
               default:
                   // Don't do anything
                   break
               }
           }
           return tokenBuffer
   //            case let .NOACTION(i , v)
   //                where (index < group.count - 1 && v == group[index + 1].getValue() && (index == buffer.count && index == i)) :
   //                let next = group[index + 1]
   //                let totalValue = next.getValue() + v
   //                skipNext = true
   //                buffer.append(TileAction.SINGLECOMBINE(source: next.getSource(), value: totalValue))
   //            case let action where (index < group.count - 1 && action.getValue() == group[index + 1].getValue()) :
   //                let next = group[index + 1]
   //                let totalValue = next.getValue() + action.getValue()
   //                skipNext = true
   //                buffer.append(TileAction.DOUBLECOMBINE(firstSource: action.getSource(), secondSource: next.getSource(), value: totalValue))
   //            case let .NOACTION(i , v) where (index == buffer.count && index == i) :
   //                buffer.append(TileAction.NOACTION(source: i, value: v))
   //            case let .NOACTION(i , v) :
   //                buffer.append(TileAction.MOVE(source: i, value: v))
   //            case let .MOVE(i , v) :
   //                buffer.append(TileAction.MOVE(source: i, value: v))
   //            default:
   //                break
       }
       
       class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
           // Return whether or not a 'NoAction' token still represents an unmoved tile
           return (inputPosition == outputLength) && (originalPosition == inputPosition)
       }
       
       //转换为MOVEORDER便于后续处理
       func convert(group : [TileAction]) -> [MoveOrder] {
           var buffer = [MoveOrder]()
           for (idx , tileAction) in group.enumerated() {
               switch tileAction {
               case let .MOVE(s, v) :
                   buffer.append(MoveOrder.SINGLEMOVEORDER(source: s, destination: idx, value: v, merged: false))
               case let .SINGLECOMBINE(s, v) :
                   buffer.append(MoveOrder.SINGLEMOVEORDER(source: s, destination: idx, value: v, merged: true))
               case let .DOUBLECOMBINE(s, d, v) :
                   buffer.append(MoveOrder.DOUBLEMOVEORDER(firstSource: s, secondSource: d, destination: idx, value: v))
               default:
                   break
               }
           }
           return buffer
       }
}
