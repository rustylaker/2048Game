//
//  BaseModles.swift
//  2048test
//
//  Created by 闫榕慧 on 2020/11/17.
//

import Foundation

enum TileEnumm {
    case Empty
    case Tile(Int)
}

enum MoveDirection {
    case UP,DOWN,LEFT,RIGHT
}

enum TileAction{
    case NOACTION(source : Int , value : Int)
    case MOVE(source : Int , value : Int)
    case SINGLECOMBINE(source : Int , value : Int)
    case DOUBLECOMBINE(firstSource : Int , secondSource : Int , value : Int)
    
    func getValue() -> Int {
        switch self {
        case let .NOACTION(_, value) : return value
        case let .MOVE(_, value) : return value
        case let .SINGLECOMBINE(_, value) : return value
        case let .DOUBLECOMBINE(_, _, value) : return value
        }
    }
    
    func getSource() -> Int {
        switch self {
        case let .NOACTION(source , _) : return source
        case let .MOVE(source , _) : return source
        case let .SINGLECOMBINE(source , _) : return source
        case let .DOUBLECOMBINE(source , _ , _) : return source
        }
    }
}

enum MoveOrder{
    case SINGLEMOVEORDER(source : Int , destination : Int , value : Int , merged : Bool)
    case DOUBLEMOVEORDER(firstSource : Int , secondSource : Int , destination : Int , value : Int)
}

struct SequenceGamebordd<T> {
    var demision : Int
    var tileArray : [T]
    
    init(demision d : Int , initValue : T ){
        self.demision = d
        tileArray = [T](repeating: initValue, count : d*d )
    }
    
    subscript(row : Int , col : Int) -> T {
        get{
            assert(row >= 0 && row < demision && col >= 0 && col < demision)
            return tileArray[demision*row + col]
        }
        set{
            assert(row >= 0 && row < demision && col >= 0 && col < demision)
            tileArray[demision*row + col] = newValue
        }
    }
    
    mutating func setAll(value : T){
        for i in 0..<demision {
            for j in 0..<demision {
                self[i , j] = value
            }
        }
    }
}
