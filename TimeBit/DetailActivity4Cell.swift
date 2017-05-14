//
//  DetailActivity4Cell.swift
//  TimeBit
//
//  Created by Namrata Mehta on 4/29/17.
//  Copyright © 2017 BiteOfTime. All rights reserved.
//

import UIKit

@objc protocol DetailActivity4CellDelegate {
    @objc optional func detailActivity4Cell(detailActivity4Cell:DetailActivity4Cell, didChangeValue value: Bool)
    @objc optional func detailActivity4Cell(stopActivityDetails: Dictionary<String, Any>)
    @objc optional func detailActivity4Cell(startActivityName: String)
}

class DetailActivity4Cell: UITableViewCell {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var lineView: UIView!
    
    weak var delegate: DetailActivity4CellDelegate?
    var activity_name: String!
    
    var startActivity: Bool = false
    var isActivityRunning: Bool = false
    var anyActivityRunning: Bool = false
    var isActivityPaused: Bool = false
    var passedSeconds: Int64 = 0
    var startDate: Date?
    var quitDate: Date?
    var activityTimer: Timer?
    var totalduration: Int = 0
    
    var hours: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0
    var trackPassedSecond: Int64 = 0
    var startNewTimer: Bool = true

    override func awakeFromNib() {
        super.awakeFromNib()
        let shadowSize : CGFloat = 5.0
        let shadowPath = UIBezierPath(rect: CGRect(x: -shadowSize / 2,
                                                   y: -shadowSize / 2,
                                                   width: self.lineView.frame.size.width + shadowSize,
                                                   height: self.lineView.frame.size.height + shadowSize))
        lineView.layer.masksToBounds = false
        lineView.layer.shadowColor = UIColor(red: 0.12, green: 0.67, blue: 1.0, alpha: 1.0).cgColor
        lineView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        lineView.layer.shadowRadius = 2
        lineView.layer.shadowOpacity = 0.3
        lineView.layer.shadowPath = shadowPath.cgPath
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func onButtonClick(_ sender: Any) {
        print("Button is clicked before \(startActivity)")
        startActivity = !startActivity
        if(startActivity && startNewTimer) {
            startButton.setTitle("STOP", for: UIControlState())
            startButton.layer.cornerRadius = 16.0
            startDate = Date()
            passedSeconds = 0
            invalidateTimer()
            startActivityTimer()
            delegate?.detailActivity4Cell?(startActivityName: activity_name)
        } else {
            startButton.setTitle("START", for: UIControlState())
            startButton.layer.cornerRadius = 16.0
            invalidateTimer()
            isActivityRunning = false
            minuteLabel.text = "00"
            hourLabel.text = "00"
            secondLabel.text = "00"
            
            var currentDate = formatDate(dateString: String(describing: Date()))
            
            print("Saving the activity in db")
            print("startDate \(startDate)")
            print("endDate \(Date())")
            print("duration \(passedSeconds)")
            
            if (!activity_name.isEmpty) {
                let params = ["activity_name": activity_name, "activity_start_time": startDate!, "activity_end_time": Date(), "activity_duration": passedSeconds, "activity_event_date": currentDate] as [String : Any]
                ParseClient.sharedInstance.saveActivityLog(params: params as NSDictionary?) { (PFObject, Error) -> () in
                    if Error != nil {
                        NSLog("Error saving to the log for the activity \(self.activity_name)")
                    } else {
                        NSLog("Saved the activity for \(self.activity_name)")
                    }
                }
                delegate?.detailActivity4Cell?(stopActivityDetails: params)
            }
            
            startDate = nil
            passedSeconds = 0
            UserDefaults.standard.set(isActivityRunning, forKey:"quitActivityRunning")
            UserDefaults.standard.synchronize()
        }
        print("Button is clicked after \(startActivity)")
        delegate?.detailActivity4Cell?(detailActivity4Cell: self, didChangeValue: startActivity)
    }
    
    
    func invalidateTimer() {
        if let timer = activityTimer {
            timer.invalidate()
        }
    }
    
    func startActivityTimer() {
        activityTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DetailActivity4Cell.updateLabel), userInfo: nil, repeats: true)
    }
    
    
    func updateLabel() {
        passedSeconds += 1
        
        let second = passedSeconds % 60
        let minutes = (passedSeconds / 60) % 60
        let hours = passedSeconds / 3600
        
        if second <= 9 {
            secondLabel.text = "0" + String(second)
        } else {
            secondLabel.text = String(second)
        }
        
        if minutes <= 9 {
            minuteLabel.text = "0" + String(minutes)
        } else {
            minuteLabel.text = String(minutes)
        }
        
        if hours <= 9 {
            hourLabel.text = "0" + String(hours)
        } else {
            hourLabel.text = String(hours)
        }
    }
    
    
    func formatDate(dateString: String) -> String? {
        
        let formatter = DateFormatter()
        let currentDateFormat = DateFormatter.dateFormat(fromTemplate: "MMddyyyy", options: 0, locale: NSLocale(localeIdentifier: "en-GB") as Locale)
        
        formatter.dateFormat = currentDateFormat
        let formattedDate = formatter.string(from: Date())
        // gbSwiftDayString now contains the string "02/06/2014".
        
        return formattedDate
    }
    
}
