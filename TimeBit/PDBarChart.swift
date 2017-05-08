//
//  PDBarChart.swift
//  TimeBit
//
//  Created by Namrata Mehta on 5/6/17.
//  Copyright © 2017 BiteOfTime. All rights reserved.
//

import UIKit
import QuartzCore

class PDBarChartDataItem {
    //optional
    var axesColor: UIColor = UIColor(red: 80.0 / 255, green: 80.0 / 255, blue: 80.0 / 255, alpha: 1.0)
    var axesTipColor: UIColor = UIColor(red: 80.0 / 255, green: 80.0 / 255, blue: 80.0 / 255, alpha: 1.0)
    var chartLayerColor: UIColor = UIColor(red: 61.0 / 255, green: 189.0 / 255, blue: 100.0 / 255, alpha: 1.0) 
    
    var barBgColor: UIColor = UIColor(red: 234.0 / 255, green: 234.0 / 255, blue: 234.0 / 255, alpha: 1.0)
    var barColor: UIColor = UIColor(red: 69.0 / 255, green: 189.0 / 255, blue: 100.0 / 255, alpha: 1.0)//69 189 100
    
    var showAxes: Bool = true
    var axesWidth: CGFloat = 1.0
    
    var barMargin: CGFloat = 4.0
    var barWidth: CGFloat!
    
    var barCornerRadius: CGFloat = 0
    
    //require
    var xMax: CGFloat!
    var xInterval: CGFloat!
    
    var yMax: CGFloat!
    var yInterval: CGFloat!
    
    var xAxesDegreeTexts: [String]?
    var yAxesDegreeTexts: [String]?
    
    var barPointArray: [CGPoint]?
    
    init() {
        
    }
}

class PDBarChart: PDChart {
    
    var axesComponent: PDChartAxesComponent!
    var dataItem: PDBarChartDataItem!
    
    //property
    var barBgArray: [UIView] = []
    var barLayerArray: [CAShapeLayer] = []
    
    init(frame: CGRect, dataItem: PDBarChartDataItem) {
        super.init(frame: frame)
        self.dataItem = dataItem
        
        let axesDataItem: PDChartAxesComponentDataItem = PDChartAxesComponentDataItem()
        axesDataItem.arrowBodyLength += 10
        axesDataItem.targetView = self
        axesDataItem.featureH = getFeatureHeight()
        axesDataItem.featureW = getFeatureWidth()
        axesDataItem.xMax = dataItem.xMax
        axesDataItem.xInterval = dataItem.xInterval
        axesDataItem.yMax = dataItem.yMax
        axesDataItem.yInterval = dataItem.yInterval
        axesDataItem.xAxesDegreeTexts = dataItem.xAxesDegreeTexts
        axesDataItem.showXDegree = false
        axesDataItem.axesWidth = dataItem.axesWidth
        
        self.axesComponent = PDChartAxesComponent(dataItem: axesDataItem)
        
        //bar width
        let xDegreeInterval = self.axesComponent.getXDegreeInterval()
        self.dataItem.barWidth = xDegreeInterval - dataItem.barMargin * 2
        
        self.addBarBackgroundView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getFeatureWidth() -> CGFloat {
        return CGFloat(self.frame.size.width)
    }
    
    func getFeatureHeight() -> CGFloat {
        return CGFloat(self.frame.size.height)
    }
    
    func getBarView(_ frame: CGRect) -> UIView {
        let barView: UIView = UIView(frame: frame)
        barView.backgroundColor = self.dataItem.barBgColor
        barView.clipsToBounds = true
        barView.layer.cornerRadius = self.dataItem.barCornerRadius
        return barView
    }
    
    func getBarShapeLayer(_ layerFrame: CGRect, barHeight: CGFloat) -> CAShapeLayer {
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = self.dataItem.barColor.cgColor
        shapeLayer.lineWidth = self.dataItem.barWidth
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 1.0
        shapeLayer.frame = layerFrame
        
        let barPath: UIBezierPath = UIBezierPath()
        barPath.move(to: CGPoint(x: self.dataItem.barWidth / 2, y: layerFrame.size.height))
        barPath.addLine(to: CGPoint(x: self.dataItem.barWidth / 2, y: layerFrame.size.height - barHeight))
        barPath.stroke()
        
        shapeLayer.path = barPath.cgPath
        
        return shapeLayer
    }
    
    func getBarAnimation() -> CABasicAnimation {
        CATransaction.begin()
        
        let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.duration = 1.0
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        pathAnimation.fromValue = 0.0
        pathAnimation.toValue = 1.0
        
        CATransaction.setCompletionBlock({
            () -> Void in
            return
        })
        
        CATransaction.commit()
        
        return pathAnimation
    }
    
    func addBarBackgroundView() {
        let xDegreeInterval: CGFloat = self.axesComponent.getXDegreeInterval()
        let basePoint: CGPoint = self.axesComponent.getBasePoint()
        let yAxesHeight: CGFloat = self.axesComponent.getYAxesHeight()
        
        for i in 0..<self.dataItem.barPointArray!.count {
            let bvw: CGFloat = self.dataItem.barWidth
            let bvh: CGFloat = yAxesHeight
            let bvx: CGFloat = basePoint.x + xDegreeInterval / 2 + self.dataItem.barMargin + (self.dataItem.barWidth + self.dataItem.barMargin * 2) * CGFloat(i)
            let bvy: CGFloat = basePoint.y - bvh - self.dataItem.axesWidth / 2
            
            let barView: UIView = self.getBarView(CGRect(x: bvx, y: bvy, width: bvw, height: bvh))
            self.barBgArray.append(barView)
            self.addSubview(barView)
        }
    }
    
    override func strokeChart()  {
        if !(self.dataItem.barPointArray != nil) {
            return
        }
        
        UIGraphicsBeginImageContext(self.frame.size)
        
        let yAxesHeight: CGFloat = self.axesComponent.getYAxesHeight()
        
        for i in 0..<self.dataItem.barPointArray!.count {
            let point: CGPoint = self.dataItem.barPointArray![i]
            let barView: UIView = self.barBgArray[i]
            
            //barShape
            let barShapeLayer: CAShapeLayer = self.getBarShapeLayer(CGRect(x: 0, y: 0, width: barView.frame.size.width, height: barView.frame.size.height), barHeight: point.y / self.dataItem.yMax * yAxesHeight)
            barShapeLayer.add(self.getBarAnimation(), forKey: "barAnimation")
            self.barLayerArray.append(barShapeLayer)
            barView.layer.addSublayer(barShapeLayer)
        }
        
        UIGraphicsEndImageContext()
    }
    
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        let context: CGContext = UIGraphicsGetCurrentContext()!
        axesComponent.strokeAxes(context)
    }
    
}
