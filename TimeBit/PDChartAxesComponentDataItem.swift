//
//  PDChartAxesComponentDataItem.swift
//  TimeBit
//
//  Created by Namrata Mehta on 5/6/17.
//  Copyright © 2017 BiteOfTime. All rights reserved.
//

import UIKit

class PDChartAxesComponentDataItem: NSObject {
    //required
    var targetView: UIView!
    
    var featureH: CGFloat!
    var featureW: CGFloat!
    
    var xMax: CGFloat!
    var xInterval: CGFloat!
    var yMax: CGFloat!
    var yInterval: CGFloat!
    
    var xAxesDegreeTexts: [String]?
    var yAxesDegreeTexts: [String]?
    
    //optional default
    var showAxes: Bool = true
    
    var showXDegree: Bool = true
    var showYDegree: Bool = true
    
    var axesColor: UIColor = UIColor(red: 80.0 / 255, green: 80.0 / 255, blue: 80.0 / 255, alpha: 1.0)
    var axesTipColor: UIColor = UIColor(red: 80.0 / 255, green: 80.0 / 255, blue: 80.0 / 255, alpha: 1.0)
    
    var xAxesLeftMargin: CGFloat = 40
    var xAxesRightMargin: CGFloat = 40
    var yAxesBottomMargin: CGFloat = 40
    var yAxesTopMargin: CGFloat = 40
    
    var axesWidth: CGFloat = 1.0
    
    var arrowHeight: CGFloat = 5.0
    var arrowWidth: CGFloat = 5.0
    var arrowBodyLength: CGFloat = 10.0
    
    var degreeLength: CGFloat = 5.0
    var degreeTipFontSize: CGFloat = 10.0
    var degreeTipMarginHorizon: CGFloat = 5.0
    var degreeTipMarginVertical: CGFloat = 5.0
    
    override init() {
        
    }
}


class PDChartAxesComponent: NSObject {
    
    var dataItem: PDChartAxesComponentDataItem!
    
    init(dataItem: PDChartAxesComponentDataItem) {
        self.dataItem = dataItem
    }
    
    func getYAxesHeight() -> CGFloat {//heigth between 0~yMax
        let basePoint: CGPoint = self.getBasePoint()
        let yAxesHeight = basePoint.y - dataItem.arrowHeight - dataItem.yAxesTopMargin - dataItem.arrowBodyLength
        return yAxesHeight
    }
    
    func getXAxesWidth() -> CGFloat {//width between 0~xMax
        let basePoint: CGPoint = self.getBasePoint()
        let xAxesWidth = dataItem.featureW - basePoint.x - dataItem.arrowHeight - dataItem.xAxesRightMargin - dataItem.arrowBodyLength
        return xAxesWidth
    }
    
    func getBasePoint() -> CGPoint {
        
        var neededAxesWidth: CGFloat!
        if dataItem.showAxes {
            neededAxesWidth = CGFloat(dataItem.axesWidth)
        } else {
            neededAxesWidth = 0
        }
        
        let basePoint: CGPoint = CGPoint(x: dataItem.xAxesLeftMargin + neededAxesWidth / 2.0, y: dataItem.featureH - (dataItem.yAxesBottomMargin + neededAxesWidth / 2.0))
        return basePoint
    }
    
    func getXDegreeInterval() -> CGFloat {
        let xAxesWidth: CGFloat = self.getXAxesWidth()
        let xDegreeInterval: CGFloat = dataItem.xInterval / dataItem.xMax * xAxesWidth
        return xDegreeInterval
    }
    
    func getYDegreeInterval() -> CGFloat {
        let yAxesHeight: CGFloat = self.getYAxesHeight()
        let yDegreeInterval: CGFloat = dataItem.yInterval / dataItem.yMax * yAxesHeight
        return yDegreeInterval
    }
    
    func getAxesDegreeTipLabel(_ tipText: String, center: CGPoint, size: CGSize, fontSize: CGFloat, textAlignment: NSTextAlignment, textColor: UIColor) -> UILabel {
        let label: UILabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        label.text = tipText
        label.center = center
        label.textAlignment = textAlignment
        label.textColor = textColor
        label.backgroundColor = UIColor.clear
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: fontSize)
        return label
    }
    
    func getXAxesDegreeTipLabel(_ tipText: String, center: CGPoint, size: CGSize, fontSize: CGFloat) -> UILabel {
        return self.getAxesDegreeTipLabel(tipText, center: center, size: size, fontSize: fontSize, textAlignment: NSTextAlignment.center, textColor: dataItem.axesTipColor)
    }
    
    func getYAxesDegreeTipLabel(_ tipText: String, center: CGPoint, size: CGSize, fontSize: CGFloat) -> UILabel {
        return self.getAxesDegreeTipLabel(tipText, center: center, size: size, fontSize: fontSize, textAlignment: NSTextAlignment.right, textColor: dataItem.axesTipColor)
    }
    
    func strokeAxes(_ context: CGContext?) {
        let xAxesWidth: CGFloat = self.getXAxesWidth()
        let yAxesHeight: CGFloat = self.getYAxesHeight()
        let basePoint: CGPoint = self.getBasePoint()
        
        
        if dataItem.showAxes {
            context?.setStrokeColor(dataItem.axesColor.cgColor)
            context?.setFillColor(dataItem.axesColor.cgColor)
            
            let axesPath: UIBezierPath = UIBezierPath()
            axesPath.lineWidth = dataItem.axesWidth
            axesPath.lineCapStyle = CGLineCap.round
            axesPath.lineJoinStyle = CGLineJoin.round
            
            //x axes--------------------------------------
            axesPath.move(to: CGPoint(x: basePoint.x, y: basePoint.y))
            axesPath.addLine(to: CGPoint(x: basePoint.x + xAxesWidth, y: basePoint.y))
            
            //degrees in x axes
            let xDegreeNum: Int = Int((dataItem.xMax - (dataItem.xMax.truncatingRemainder(dividingBy: dataItem.xInterval))) / dataItem.xInterval)
            let xDegreeInterval: CGFloat = self.getXDegreeInterval()
            
            if dataItem.showXDegree {
                for i in 0..<xDegreeNum {
                    let degreeX: CGFloat = basePoint.x + xDegreeInterval * CGFloat(i + 1)
                    axesPath.move(to: CGPoint(x: degreeX, y: basePoint.y))
                    axesPath.addLine(to: CGPoint(x: degreeX, y: basePoint.y - dataItem.degreeLength))
                }
            }
            
            //x axes arrow
            //arrow body
            axesPath.move(to: CGPoint(x: basePoint.x + xAxesWidth, y: basePoint.y))
            axesPath.addLine(to: CGPoint(x: basePoint.x + xAxesWidth + dataItem.arrowBodyLength, y: basePoint.y))
            //arrow head
            let arrowPath: UIBezierPath = UIBezierPath()
            arrowPath.lineWidth = dataItem.axesWidth
            arrowPath.lineCapStyle = CGLineCap.round
            arrowPath.lineJoinStyle = CGLineJoin.round
            
            let xArrowTopPoint: CGPoint = CGPoint(x: basePoint.x + xAxesWidth + dataItem.arrowBodyLength + dataItem.arrowHeight, y: basePoint.y)
            arrowPath.move(to: xArrowTopPoint)
            arrowPath.addLine(to: CGPoint(x: basePoint.x + xAxesWidth + dataItem.arrowBodyLength, y: basePoint.y - dataItem.arrowWidth / 2))
            arrowPath.addLine(to: CGPoint(x: basePoint.x + xAxesWidth + dataItem.arrowBodyLength, y: basePoint.y + dataItem.arrowWidth / 2))
            arrowPath.addLine(to: xArrowTopPoint)
            
            //y axes--------------------------------------
            axesPath.move(to: CGPoint(x: basePoint.x, y: basePoint.y))
            axesPath.addLine(to: CGPoint(x: basePoint.x, y: basePoint.y - yAxesHeight))
            
            //degrees in y axes
            let yDegreesNum: Int = Int((dataItem.yMax - (dataItem.yMax.truncatingRemainder(dividingBy: dataItem.yInterval))) / dataItem.yInterval)
            let yDegreeInterval: CGFloat = self.getYDegreeInterval()
            if dataItem.showYDegree {
                for i in 0..<yDegreesNum {
                    let degreeY: CGFloat = basePoint.y - yDegreeInterval * CGFloat(i + 1)
                    axesPath.move(to: CGPoint(x: basePoint.x, y: degreeY))
                    axesPath.addLine(to: CGPoint(x: basePoint.x +  dataItem.degreeLength, y: degreeY))
                }
            }
            
            //y axes arrow
            //arrow body
            axesPath.move(to: CGPoint(x: basePoint.x, y: basePoint.y - yAxesHeight))
            axesPath.addLine(to: CGPoint(x: basePoint.x, y: basePoint.y - yAxesHeight - dataItem.arrowBodyLength))
            //arrow head
            let yArrowTopPoint: CGPoint = CGPoint(x: basePoint.x, y: basePoint.y - yAxesHeight - dataItem.arrowBodyLength - dataItem.arrowHeight)
            arrowPath.move(to: yArrowTopPoint)
            arrowPath.addLine(to: CGPoint(x: basePoint.x - dataItem.arrowWidth / 2, y: basePoint.y - yAxesHeight - dataItem.arrowBodyLength))
            arrowPath.addLine(to: CGPoint(x: basePoint.x + dataItem.arrowWidth / 2, y: basePoint.y - yAxesHeight - dataItem.arrowBodyLength))
            arrowPath.addLine(to: yArrowTopPoint)
            
            axesPath.stroke()
            arrowPath.stroke()
            
            //axes tips------------------------------------
            //func getXAxesDegreeTipLabel(tipText: String, frame: CGRect, fontSize: CGFloat) -> UILabel {
            if (dataItem.xAxesDegreeTexts != nil) {
                for i in 0..<dataItem.xAxesDegreeTexts!.count {
                    let size: CGSize = CGSize(width: xDegreeInterval - dataItem.degreeTipMarginHorizon * 2, height: dataItem.degreeTipFontSize)
                    let center: CGPoint = CGPoint(x: basePoint.x + xDegreeInterval * CGFloat(i + 1), y: basePoint.y + dataItem.degreeTipMarginVertical + size.height / 2)
                    let label: UILabel = self.getXAxesDegreeTipLabel(dataItem.xAxesDegreeTexts![i], center: center, size: size, fontSize: dataItem.degreeTipFontSize)
                    dataItem.targetView.addSubview(label)
                }
            } else {
                for i in 0..<xDegreeNum {
                    let size: CGSize = CGSize(width: xDegreeInterval - dataItem.degreeTipMarginHorizon * 2, height: dataItem.degreeTipFontSize)
                    let center: CGPoint = CGPoint(x: basePoint.x + xDegreeInterval * CGFloat(i + 1), y: basePoint.y + dataItem.degreeTipMarginVertical + size.height / 2)
                    let label: UILabel = self.getXAxesDegreeTipLabel("\(CGFloat(i + 1) * dataItem.xInterval)", center: center, size: size, fontSize: dataItem.degreeTipFontSize)
                    dataItem.targetView.addSubview(label)
                }
            }
            
            if (dataItem.yAxesDegreeTexts != nil) {
                for i in 0..<dataItem.yAxesDegreeTexts!.count {
                    let size: CGSize = CGSize(width: dataItem.xAxesLeftMargin - dataItem.degreeTipMarginHorizon * 2, height: dataItem.degreeTipFontSize)
                    let center: CGPoint = CGPoint(x: dataItem.xAxesLeftMargin / 2, y: basePoint.y - yDegreeInterval * CGFloat(i + 1))
                    let label: UILabel = self.getYAxesDegreeTipLabel(dataItem.yAxesDegreeTexts![i], center: center, size: size, fontSize: dataItem.degreeTipFontSize)
                    dataItem.targetView.addSubview(label)
                }
            } else {
                for i in 0..<yDegreesNum {
                    let size: CGSize = CGSize(width: dataItem.xAxesLeftMargin - dataItem.degreeTipMarginHorizon * 2, height: dataItem.degreeTipFontSize)
                    let center: CGPoint = CGPoint(x: dataItem.xAxesLeftMargin / 2, y: basePoint.y - yDegreeInterval * CGFloat(i + 1))
                    let label: UILabel = self.getYAxesDegreeTipLabel("\(CGFloat(i + 1) * dataItem.yInterval)", center: center, size: size, fontSize: dataItem.degreeTipFontSize)
                    dataItem.targetView.addSubview(label)
                }
            }
        }
        
    }
}

