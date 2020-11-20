//
//  TileView.swift
//  2048test
//
//  Created by 闫榕慧 on 2020/11/17.
//

import Foundation
import UIKit


//游戏中可以移动的小方块
class TileView : UIView{
    
    //数字块中的值
    var value : Int = 0 {
        didSet{ //属性观察器
            //负责给小方块上色（文字颜色、背景颜色）、显示出的Label数值
            backgroundColor = delegate.tileColor(value: value)
            lable.textColor = delegate.numberColor(value: value)
            lable.text = "\(value)"
        }
    }
    
    //提供颜色选择
    unowned let delegate : AppearanceProviderProtocol
    
    //一个数字块也就是一个lable
    var lable : UILabel

    init(position : CGPoint, width : CGFloat, value : Int, delegate d: AppearanceProviderProtocol){
        delegate = d
        lable = UILabel(frame : CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: width, height: width)))
        lable.textAlignment = NSTextAlignment.center
        lable.minimumScaleFactor = 0.5
        lable.font = UIFont(name: "HelveticaNeue-Bold", size: 15) ?? UIFont.systemFont(ofSize: 15)
        super.init(frame: CGRect(origin: CGPoint(x: position.x,y :position.y), size: CGSize(width: width, height: width)))
        addSubview(lable)
        lable.layer.cornerRadius = 6

        self.value = value
        backgroundColor = delegate.tileColor(value: value)
        lable.textColor = delegate.numberColor(value: value)
        lable.text = "\(value)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

