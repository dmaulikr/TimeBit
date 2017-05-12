//
//  HomeViewController.swift
//  TimeBit
//
//  Created by Anisha Jain on 4/28/17.
//  Copyright © 2017 BiteOfTime. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import UserNotifications
import UserNotificationsUI

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ActivityCellDelegate, AddNewActivityViewControllerDelegate, UICollectionViewDelegateFlowLayout, TimerViewDeleagte, DetailActivityViewControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timerView: TimerView!
    
    var roundButton = UIButton()
    var reusableView : UICollectionReusableView? = nil
    
    var activities: [Activity] = []
    var activitiesTodayLog: Dictionary<String, [ActivityLog]> = Dictionary()
    
    var currentActivityIndex: Int = -1
    var startDate: Date?
    var activityRunning: Dictionary = [String: Any]()
    var selectedCell = [IndexPath]()
    
    var initialIndexPath: IndexPath?
    var cellSnapshot: UIView?
    var longPressActive = false
    var touchLocation:CGPoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ActivityCell", bundle: nil), forCellWithReuseIdentifier: "ActivityCell")
        collectionView.allowsSelection = true
        
        collectionView.layer.borderWidth = 0.4
        collectionView.layer.borderColor = UIColor(red: 54/255, green: 69/255, blue: 86/255, alpha: 1.0).cgColor
//        collectionView.layer.shadowOpacity = 1.0
//        collectionView.layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
//        collectionView.layer.shadowRadius = 10
//        collectionView.layer.shadowColor = UIColor.white.cgColor
            //UIColor(red: 2/255, green: 11/255, blue: 23/255, alpha: 1.0).cgColor
        
        //collectionView.register(UINib(nibName: "ActivityHeader",bundle: nil), forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, withReuseIdentifier: "ActivityHeader")
        
        navigationItem.title = "TimeBit"
        //Floating round button to add a new activity
        self.roundButton = UIButton(type: .custom)
        self.roundButton.setTitleColor(UIColor.orange, for: .normal)
        self.roundButton.addTarget(self, action: #selector(ButtonClick(_:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(roundButton)
        timerView.delegate = self
        
        loadActivities()
        addLongPressGesture()
        addTapGesture()
        self.becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if timerView.isRunning {
                print("Stopping timer on shake detection")
                let passedSeconds = timerView.onStopTimer()
                timerView.isRunning = false
                timerView(onStop: passedSeconds)
            }
            print("Shaking")
        }
    }
    
    func loadActivities () {
        if User.currentUser == nil {
            print("User is looged in for first time")
            let activities = defaultActivitiesList()
            // Save default activities
            
            ParseClient.sharedInstance.saveMultipleActivities(activities: activities as [Activity?]) { (PFObject, Error) -> () in
                if Error != nil {
                    NSLog("Error saving to Parse")
                } else {
                    NSLog("Saved activity to Parse")
                    ParseClient.sharedInstance.getActivities() { (activities: [Activity]?, error: Error?) -> Void in
                        if error != nil {
                            NSLog("Error getting activities from Parse")
                        } else {
                            NSLog("Items from Parse")
                            self.activities = activities!
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
            
        } else {
            print("User already logged in")
            ParseClient.sharedInstance.getActivities() { (activities: [Activity]?, error: Error?) -> Void in
                if error != nil {
                    NSLog("Error getting activities from Parse")
                } else {
                    NSLog("getActivities from Parse")
                    self.activities = activities!
                    let currentDate = Utils.formatDate(dateString: String(describing: Date()))
                    let params = ["activity_event_date": currentDate!] as [String : Any]
                    ParseClient.sharedInstance.getTodayCountForAllActivities(params: params as NSDictionary?) { (activities: [ActivityLog]?, error: Error?) -> Void in
                        if error != nil {
                            NSLog("Error getting activities from Parse")
                        } else {
                            for activity in activities! {
                                var activityLogs = self.activitiesTodayLog[activity.activity_name!] ?? []
                                activityLogs.append(activity)
                                self.activitiesTodayLog[activity.activity_name!] = activityLogs
                                
                            }
                            NSLog("Items from Parse for getTodayCountForActivity \(self.activitiesTodayLog)")
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
            
        }
    }
    
    func defaultActivitiesList () -> [Activity] {
        return [Activity("Work", "Work", #imageLiteral(resourceName: "Work")),
                Activity("Eat", "Eat", #imageLiteral(resourceName: "Eat")),
                Activity("Sleep", "Sleep", #imageLiteral(resourceName: "Sleep")),
                Activity("Read", "Read", #imageLiteral(resourceName: "Read")),
                Activity("Walk", "Walk", #imageLiteral(resourceName: "Walk")),
                Activity("Internet", "Internet", #imageLiteral(resourceName: "Internet")),
                Activity("Shop", "Shop", #imageLiteral(resourceName: "Shop")),
                Activity("Excercise", "Excercise", #imageLiteral(resourceName: "Exercise")),
                Activity("Sport", "Sport", #imageLiteral(resourceName: "Sport"))]
    }
    
    func convertToPFFile(_ uiImage:UIImage, activityName: String) -> PFFile? {
        let imageData = UIImagePNGRepresentation(uiImage)
        let image = PFFile(name: "\(activityName).png", data: imageData!)
        return image
    }
    
    func addNewActivityViewController(onSaveActivity newActivity: Activity) {
        activities.append(newActivity)
        ParseClient.sharedInstance.getActivities() { (activities: [Activity]?, error: Error?) -> Void in
            if error != nil {
                NSLog("Error getting activities from Parse")
            } else {
                NSLog("Items from Parse")
                self.activities = activities!
                self.collectionView.reloadData()
            }
        }
    }
    
    func addLongPressGesture() {
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGesture(sender:)))
        collectionView.addGestureRecognizer(longpress)
    }
    
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture(sender:)))
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    func onTapGesture(sender: UITapGestureRecognizer) {
        if longPressActive {
            longPressActive = false
            collectionView.reloadData()
        } else {
            let locationInView = sender.location(in: collectionView)
            let indexPath = collectionView.indexPathForItem(at: locationInView)
            
            let detailActivityViewController = DetailActivityViewController(nibName: "DetailActivityViewController", bundle: nil)
            detailActivityViewController.activity_name = activities[(indexPath?.row)!].activityName!
            print("passing the value of isTimerOn to detailVC \(currentActivityIndex)")
            detailActivityViewController.isTimerOn = currentActivityIndex
            detailActivityViewController.currentHour = self.timerView.hours
            detailActivityViewController.currentMinute = self.timerView.minutes
            detailActivityViewController.currentSec = self.timerView.seconds
            detailActivityViewController.trackPassedSecond = self.timerView.passedSeconds
            detailActivityViewController.activityStartTimeFromHomeScreen = self.startDate ?? Date()
            detailActivityViewController.delegate = self
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            navigationController?.pushViewController(detailActivityViewController, animated: true)
            
        }
    }
    
    func onLongPressGesture(sender: UILongPressGestureRecognizer) {
        
        let locationInView = sender.location(in: view)
        let locationInCollectionView = sender.location(in: collectionView)
        let collectionViewLocation = collectionView.convert(collectionView.bounds.origin, to: view)
        
        if sender.state == .began {
            touchLocation = locationInView
            let indexPath = collectionView.indexPathForItem(at: locationInCollectionView)
            if indexPath != nil {
                initialIndexPath = indexPath
                let cell = collectionView.cellForItem(at: indexPath!)
                cellSnapshot = snapshotOfCell(inputView: cell!)
                cell?.isHidden = true
                
                let locationOnScreen = cell!.convert(cell!.bounds.origin, to: view)
                let cellBounds = cell!.bounds
                let center = CGPoint(x:(locationOnScreen.x + cellBounds.size.width / 2),
                                     y : (locationOnScreen.y + cellBounds.size.height / 2))
                    
                cellSnapshot?.center = center
                cellSnapshot?.alpha = 1.0
                cellSnapshot?.transform = (self.cellSnapshot?.transform.scaledBy(x: 1.05, y: 1.05))!
                view.addSubview(cellSnapshot!)
                longPressActive = true
                collectionView.reloadData()
            }
        } else if sender.state == .changed {
            
            let isInsideCollectionView = locationInView.y > collectionViewLocation.y
            
            var center = cellSnapshot?.center
            center?.y = center!.y + (locationInView.y - touchLocation!.y)
            center?.x = center!.x + (locationInView.x - touchLocation!.x)
            touchLocation = locationInView
            cellSnapshot?.center = center!
            if (isInsideCollectionView) {
                let indexPath = collectionView.indexPathForItem(at: locationInCollectionView)
                if ((indexPath != nil) && (indexPath != initialIndexPath)) {
                    swap(&activities[indexPath!.row], &activities[initialIndexPath!.row])
                    collectionView.moveItem(at: initialIndexPath!, to: indexPath!)
                    initialIndexPath = indexPath
                }
            }
        } else if sender.state == .ended {
            touchLocation = nil
            let cell = collectionView.cellForItem(at: initialIndexPath!) as! ActivityCell
            let isInsideCollectionView = locationInView.y > collectionViewLocation.y
            //print("location in view", locationInView)
            //print("collection view location", collectionViewLocation)
            
            if (isInsideCollectionView) {
                //let indexPath = collectionView.indexPathForItem(at: locationInCollectionView)
                
                let locationOnScreen = cell.convert(cell.bounds.origin, to: view)
                let cellBounds = cell.bounds
                let center = CGPoint(x:(locationOnScreen.x + cellBounds.size.width / 2),
                                     y : (locationOnScreen.y + cellBounds.size.height / 2))
                
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.cellSnapshot?.center = center
                }, completion: { (finished) -> Void in
                    if finished {
                        self.initialIndexPath = nil
                        self.cellSnapshot?.removeFromSuperview()
                        self.cellSnapshot = nil
                        self.collectionView.reloadData()
                    }
                })
            }

            else {
                longPressActive = false
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.cellSnapshot?.transform = (self.cellSnapshot?.transform.scaledBy(x: 0.4, y: 0.4))!
                    self.cellSnapshot?.alpha = 0
                }, completion: { (finished) -> Void in
                    if finished {
                        let cellIndex = self.initialIndexPath?.row
                        self.initialIndexPath = nil
                        self.cellSnapshot?.removeFromSuperview()
                        self.cellSnapshot = nil
                        self.startTimer(activityName: cell.activityNameLabel.text!, cellIndex: cellIndex!)
                        
                        self.collectionView.reloadData()
                    }
                })
                
            }
        
        }
    }
    
    func snapshotOfCell(inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let cellSnapshot = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 5.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activities.count
    }
    
    func changeColorOfCell(activityCell: ActivityCell, index: Int) {
        let mod = index % 6
        switch mod {
        case 0:
            // blue
            activityCell.activityImage.backgroundColor = UIColor(red: 255/255, green: 55/255, blue: 96/255, alpha: 1.0)
        case 1:
            // red
            activityCell.activityImage.backgroundColor = UIColor(red: 10/255, green: 204/255, blue: 247/255, alpha: 1.0)
        case 2:
            // yellow
            activityCell.activityImage.backgroundColor = UIColor(red: 255/255, green: 223/255, blue: 0/255, alpha: 1.0)
        case 3:
            // green
            activityCell.activityImage.backgroundColor = UIColor(red: 66/255, green: 188/255, blue: 88/255, alpha: 1.0)
        case 4:
            //purple
            activityCell.activityImage.backgroundColor = UIColor(red: 196/255, green: 44/255, blue: 196/255, alpha: 1.0)
        default:
            //orange
            activityCell.activityImage.backgroundColor = UIColor(red: 232/255, green: 134/255, blue: 3/255, alpha: 1.0)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActivityCell", for: indexPath) as! ActivityCell
        cell.delegate = self
        
        cell.layer.borderColor = UIColor(red: 54/255, green: 69/255, blue: 86/255, alpha: 1.0).cgColor
        cell.layer.borderWidth = 0.4
        if currentActivityIndex != indexPath.row {
            changeColorOfCell(activityCell: cell, index: indexPath.row)
        }
        
        cell.activityImage.isSelected = indexPath.row == currentActivityIndex
        
        //Loading PFFile to PFImageView
        let activity = activities[indexPath.row]
        let pfImage = activity.activityImageFile
        if let imageFile : PFFile = pfImage{
            imageFile.getDataInBackground(block: { (data, error) in
                if error == nil {
                    let image = UIImage(data: data!)
                    cell.activityImage.setImage(image, for: UIControlState.normal)
                    cell.activityImage.setImage(image, for: UIControlState.selected)
                } else {
                    print(error!.localizedDescription)
                }
            })
        }
        
        cell.activityNameLabel.text = activity.activityName
        let activityLog = activitiesTodayLog[activity.activityName!]
        let totalTimeSpentToday = getTimeSpentToday(activityLog: activityLog )
        if totalTimeSpentToday == "0" {
            cell.timeSpentLabel.isHidden = true
        } else {
            cell.timeSpentLabel.isHidden = false
            cell.timeSpentLabel.text = totalTimeSpentToday
        }
        
        if longPressActive && initialIndexPath == indexPath {
            cell.isHidden = true
        } else {
            cell.isHidden = false
        }
        
        if longPressActive && cell.transform == CGAffineTransform.identity {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                cell.transform = (cell.transform.scaledBy(x: 0.9, y: 0.9))
            })
            cell.deleteActivityButton.isHidden = false
        } else if !cell.deleteActivityButton.isHidden {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
            })
            cell.deleteActivityButton.isHidden = true
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width/2, height: 120);
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailActivityViewController = DetailActivityViewController(nibName: "DetailActivityViewController", bundle: nil)

        detailActivityViewController.activity_name = activities[indexPath.row].activityName!
        print("passing the value of isTimerOn to detailVC \(currentActivityIndex)")

        detailActivityViewController.currentHour = self.timerView.hours
        detailActivityViewController.currentMinute = self.timerView.minutes
        detailActivityViewController.currentSec = self.timerView.seconds
        detailActivityViewController.trackPassedSecond = self.timerView.passedSeconds
        detailActivityViewController.activityStartTimeFromHomeScreen = self.startDate ?? Date()
        detailActivityViewController.delegate = self
        
        navigationController?.pushViewController(detailActivityViewController, animated: true)
        navigationController?.pushViewController(detailActivityViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = .blue
    }
    
    func getTimeSpentToday(activityLog: [ActivityLog]?) -> String {
        if(activityLog == nil || activityLog?.count == 0) {
            return "0"
        }
        var totalTimeSpentToday: Int64 = 0
        for log in activityLog! {
            if log.activity_duration != nil {
                totalTimeSpentToday += Int64(log.activity_duration!)
            }
        }
        let seconds = totalTimeSpentToday % 60
        let minutes = totalTimeSpentToday / 60
        let hours = totalTimeSpentToday / 3600
        //print("totalTimeSpentToday:", totalTimeSpentToday)
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)hr \(minutes)min today" : "\(hours)hr today"
        }
        
        if minutes > 0 {
            return seconds > 0  ? "\(minutes)min \(seconds)sec today" : "\(minutes)min today"
        }
        
        
        return "\(seconds)sec today"
        
    }
    func detailActivityViewController(stopActivityDetails: Dictionary<String, Any>) {
        currentActivityIndex = -1
        timerView.activityNameLabel.text = "Start an Activity"
        
        timerView.isRunning = false
        timerView.timer.invalidate()
        timerView.resetTimer()
        
        let activityName = stopActivityDetails["activity_name"] as! String
        var activityLogs = self.activitiesTodayLog[activityName] ?? []
        activityLogs.append(ActivityLog(dictionary: stopActivityDetails))
        self.activitiesTodayLog[activityName] = activityLogs
        self.collectionView.reloadData()
    }
    
    func detailActivityViewController(startActivityName: String) {
        currentActivityIndex = 0
        print("Timer started")
        startDate = Date()
        activityRunning["activity_name"] = startActivityName
        activityRunning["activity_start_time"] = startDate
        timerView.activityNameLabel.text = startActivityName.capitalized
        //timerView.stopLabel.isHidden = false
        timerView.onStartTimer()
    }
    
    func startTimer(activityName: String, cellIndex: Int) {
        if currentActivityIndex == -1 {
            //activityCell.activityImage.isSelected = true
            currentActivityIndex = cellIndex
            print("Timer started")
            startDate = Date()
            activityRunning["activity_name"] = activityName
            activityRunning["activity_start_time"] = startDate
            timerView.activityNameLabel.text = activityName.capitalized
            //timerView.stopLabel.isHidden = false
            timerView.onStartTimer()
        }
    }
    
    func timerView(onStop passedSeconds: Int64) {
        if currentActivityIndex == currentActivityIndex {
            //activityCell.activityImage.isSelected = false
            currentActivityIndex = -1
            //print("Timer Stopped")
            //timerView.stopLabel.isHidden = true
            timerView.activityNameLabel.text = "Start an Activity"
            let currentDate = Utils.formatDate(dateString: String(describing: Date()))
            let activityName = activityRunning["activity_name"] as! String
            if (!activityName.isEmpty) {
                let params = ["activity_name": activityName, "activity_start_time":activityRunning["activity_start_time"]!, "activity_end_time": Date(), "activity_duration": passedSeconds, "activity_event_date": currentDate!] as Dictionary
                
                //Showing locally
                var activityLogs = self.activitiesTodayLog[activityName] ?? []
                activityLogs.append(ActivityLog(dictionary: params))
                self.activitiesTodayLog[activityName] = activityLogs
                self.collectionView.reloadData()
                
                ParseClient.sharedInstance.saveActivityLog(params: params as NSDictionary?) { (PFObject, Error) -> () in
                    if Error != nil {
                        NSLog("Error saving to the log for the activity")
                    } else {
                        NSLog("Saved the activity for", activityName)
                    }
                }
            }
            
            startDate = nil
        }

    }
    
//    func activityCell(onStartStop activityCell: ActivityCell) {
//        let clickActivityIndex = collectionView.indexPath(for: activityCell)!.row
//        if currentActivityIndex == -1 {
//            activityCell.activityImage.isSelected = true
//            currentActivityIndex = (collectionView.indexPath(for: activityCell)?.row)!
//            //print("Timer started")
//            startDate = Date()
//            timerView.timerRunning = true
//            timerView.onStartTimer()
//        } else if currentActivityIndex == currentActivityIndex {
//            activityCell.activityImage.isSelected = false
//            currentActivityIndex = -1
//            //print("Timer Stopped")
//            let passedSeconds = timerView.onStopTimer()
//            
//            let currentDate = Utils.formatDate(dateString: String(describing: Date()))
//            
//            if (!(activityCell.activityNameLabel.text?.isEmpty)!) {
//                let params = ["activity_name": activityCell.activityNameLabel.text!, "activity_start_time": startDate!, "activity_end_time": Date(), "activity_duration": passedSeconds, "activity_event_date": currentDate!] as Dictionary
//                
//                //Showing locally
//                var activityLogs = self.activitiesTodayLog[activityCell.activityNameLabel.text!] ?? []
//                activityLogs.append(ActivityLog(dictionary: params))
//                self.activitiesTodayLog[activityCell.activityNameLabel.text!] = activityLogs
//                self.collectionView.reloadData()
//                
//                ParseClient.sharedInstance.saveActivityLog(params: params as NSDictionary?) { (PFObject, Error) -> () in
//                    if Error != nil {
//                        NSLog("Error saving to the log for the activity")
//                    } else {
//                        NSLog("Saved the activity for", activityCell.activityNameLabel.text!)
//                    }
//                }
//            }
//            
//            startDate = nil
//        }
//    }
    
    func activityCell(onDeleteActivity activityCell: ActivityCell) {
        let alert = UIAlertController(title: "TimeBit",
                                      message: "Do you really want delete '\(activityCell.activityNameLabel!.text!)' activity?",
            preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: { (action) -> Void in
            
            let index = self.collectionView.indexPath(for: activityCell)!.row
            self.activities.remove(at: index)
            let params = ["activityName": activityCell.activityNameLabel!.text!] as [String : Any]
            ParseClient.sharedInstance.deleteActivity(params: params as NSDictionary?, completion: { (PFObject, Error) -> () in
                if Error != nil {
                    NSLog("Error deleting activity from Parse")
                } else {
                    print("Deleted activity from Parse")
                }
            })
            ParseClient.sharedInstance.deleteGoal(params: params as NSDictionary?, completion: { (PFObject, Error) -> () in
                if Error != nil {
                    NSLog("Error deleting goal from Parse")
                } else {
                    print("Deleted activity goal from Parse")
                }
            })
            ParseClient.sharedInstance.deleteActivityLog(params: params as NSDictionary?, completion: { (PFObject, Error) -> () in
                if Error != nil {
                    NSLog("Error deleting activity logs from Parse")
                } else {
                    print("Deleted activity logs from Parse")
                }
            })
            //Delete the correspnding notification
            print("Removing all pending notifications for the activity")
            let center = UNUserNotificationCenter.current()
            let notificationIdentifier = activityCell.activityNameLabel!.text!
            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            self.collectionView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillLayoutSubviews() {
        roundButton.layer.cornerRadius = roundButton.layer.frame.size.width / 2
        roundButton.backgroundColor = UIColor.clear
        roundButton.clipsToBounds = true
        roundButton.setImage(UIImage(named:"Add"), for: .normal)
        roundButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roundButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            roundButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -3),
            roundButton.widthAnchor.constraint(equalToConstant: 40),
            roundButton.heightAnchor.constraint(equalToConstant:40)])
    }
    
    @IBAction func ButtonClick(_ sender: UIButton){
        let addNewActivityViewController = AddNewActivityViewController(nibName: "AddNewActivityViewController", bundle: nil)
         self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(addNewActivityViewController, animated: true)
        
        addNewActivityViewController.delegate = self
        
    }
}
