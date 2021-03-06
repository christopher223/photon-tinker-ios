//
//  DeviceInspectorController.swift
//  Particle
//
//  Created by Ido Kleinman on 6/27/16.
//  Copyright © 2016 spark. All rights reserved.
//

import Foundation

class DeviceInspectorViewController : UIViewController, UITextFieldDelegate, SparkDeviceDelegate {
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func actionButtonTapped(sender: UIButton) {
        // heading
        view.endEditing(true)
        let dialog = ZAlertView(title: "More Actions", message: nil, alertType: .MultipleChoice)
        

        
        dialog.addButton("Reflash Tinker", font: ParticleUtils.particleBoldFont, color: ParticleUtils.particleCyanColor, titleColor: ParticleUtils.particleAlmostWhiteColor) { (dialog : ZAlertView) in
            
            dialog.dismiss()
            self.reflashTinker()
            
        }
        
        
        dialog.addButton("Rename device", font: ParticleUtils.particleBoldFont, color: ParticleUtils.particleCyanColor, titleColor: ParticleUtils.particleAlmostWhiteColor) { (dialog : ZAlertView) in
            
            dialog.dismiss()
            self.renameDialog = ZAlertView(title: "Rename device", message: nil, isOkButtonLeft: true, okButtonText: "Rename", cancelButtonText: "Cancel",
                                    okButtonHandler: { [unowned self] alertView in
                                        
                                        let tf = alertView.getTextFieldWithIdentifier("name")
                                        self.renameDevice(tf!.text)
                                        alertView.dismiss()
                },
                                    cancelButtonHandler: { alertView in
                                        alertView.dismiss()
                }
            )
            self.renameDialog!.addTextField("name", placeHolder: self.device!.name!)
            let tf = self.renameDialog!.getTextFieldWithIdentifier("name")
            tf?.text = self.device?.name
            tf?.delegate = self
            tf?.tag = 100

            self.renameDialog!.show()
            tf?.becomeFirstResponder()
        }
        
       
        
        dialog.addButton("Refresh data", font: ParticleUtils.particleBoldFont, color: ParticleUtils.particleCyanColor, titleColor: ParticleUtils.particleAlmostWhiteColor) { (dialog : ZAlertView) in
            dialog.dismiss()
            
            self.refreshData()
        }
        
        
        dialog.addButton("Signal for 10sec", font: ParticleUtils.particleBoldFont, color: ParticleUtils.particleCyanColor, titleColor: ParticleUtils.particleAlmostWhiteColor) { (dialog : ZAlertView) in
            dialog.dismiss()
            
            self.device?.signal(true, completion: nil)
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.device?.signal(false, completion: nil)
            }
            
            
        }
        
        dialog.addButton("Support/Documentation", font: ParticleUtils.particleBoldFont, color: ParticleUtils.particleEmeraldColor, titleColor: ParticleUtils.particleAlmostWhiteColor) { (dialog : ZAlertView) in
            
            dialog.dismiss()
            self.popDocumentationViewController()
        }
        

        dialog.addButton("Cancel", font: ParticleUtils.particleRegularFont, color: ParticleUtils.particleGrayColor, titleColor: UIColor.whiteColor()) { (dialog : ZAlertView) in
            dialog.dismiss()
        }
        
        
        dialog.show()
        
        
        
        
        
    }
    
    @IBOutlet weak var deviceOnlineIndicatorImageView: UIImageView!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    var renameDialog : ZAlertView?
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.tag == 100 {
            self.renameDevice(textField.text)
            renameDialog?.dismiss()
            
        }
        
        return true
    }
    

    func renameDevice(newName : String?) {
        self.device?.rename(newName!, completion: {[weak self] (error : NSError?) in
            
            if error == nil {
                if let s = self {
                    dispatch_async(dispatch_get_main_queue()) {
                        s.deviceNameLabel.text = newName!.stringByReplacingOccurrencesOfString(" ", withString: "_")
                        s.deviceNameLabel.setNeedsLayout()
                    }
                }
                
            }
        })
    }
    
    @IBAction func segmentControlChanged(sender: UISegmentedControl) {
        
        
        
//        [UIView transitionWithView:self.view duration:0.3 options: UIViewAnimationOptionTransitionCrossDissolve animations: ^ {
//            [self.view addSubview:blurView];
//            } completion:nil];
//        
        view.endEditing(true)
        
        UIView.animateWithDuration(0.25, delay: 0, options: .CurveLinear, animations: {
            self.infoContainerView.alpha = (sender.selectedSegmentIndex == 0 ? 1.0 : 0.0)
            self.deviceDataContainerView.alpha = (sender.selectedSegmentIndex == 1 ? 1.0 : 0.0)
            self.deviceEventsContainerView.alpha = (sender.selectedSegmentIndex == 2 ? 1.0 : 0.0)
            
                        
        }) { (finished: Bool) in
            
            var delayTime = dispatch_time(DISPATCH_TIME_NOW,0)
            if !finished {
                delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            }
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.infoVC!.view.hidden = (sender.selectedSegmentIndex == 0 ? false : true)
                self.dataVC!.view.hidden = (sender.selectedSegmentIndex == 1 ? false : true)
                self.eventsVC!.view.hidden = (sender.selectedSegmentIndex == 2 ? false : true)
            }
            
        }
        
        // since the embed segue already triggers the VC lifecycle functions - this is an override to re-call them on change of segmented view to trigger relevant inits or tutorial boxes
        
        if (sender.selectedSegmentIndex == 0) // info
        {
            self.infoVC!.showTutorial()
            SEGAnalytics.sharedAnalytics().track("Device Inspector: info view")
        }
        
        if (sender.selectedSegmentIndex == 1) // functions and variables
        {
            self.dataVC!.refreshVariableList()
            self.dataVC!.showTutorial()
            self.dataVC!.readAllVariablesOnce()
            SEGAnalytics.sharedAnalytics().track("Device Inspector: data view")
        }
        
        if (sender.selectedSegmentIndex == 2) // events
        {
            self.eventsVC!.showTutorial()
            SEGAnalytics.sharedAnalytics().track("Device Inspector: events view")
        }
 
        
    }
    
    @IBOutlet weak var modeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var deviceEventsContainerView: UIView!
    @IBOutlet weak var deviceDataContainerView: UIView!
    @IBOutlet weak var deviceInfoContainerView: UIView!
    
    var device : SparkDevice?
    
//    var frameView: UIView!
    
    override func viewDidLoad() {

        SEGAnalytics.sharedAnalytics().track("Device Inspector: started")
       
        let font = UIFont(name: "Gotham-book", size: 15.0)
        
        let attrib = [NSFontAttributeName : font!]
        
        self.modeSegmentedControl.setTitleTextAttributes(attrib, forState: .Normal)
        
        self.infoContainerView.alpha = 1
        
        if let ivc = self.infoVC {
            ivc.view.hidden = false
        }
        self.view.bringSubviewToFront(infoContainerView)


    }
    
    override func viewDidAppear(animated: Bool) {
        showTutorial()
    }
    
    var infoVC : DeviceInspectorInfoViewController?
    var dataVC : DeviceInspectorDataViewController?
    var eventsVC : DeviceInspectorEventsViewController?
    
    
    // happens right as Device Inspector is displayed as all VCs are in an embed segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // if its either the info data or events VC then set the device to what we are inspecting
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            if let vc = segue.destinationViewController as? DeviceInspectorChildViewController {
                vc.device = self.device
                
                if let i = vc as? DeviceInspectorInfoViewController {
                    self.infoVC = i
                    dispatch_async(dispatch_get_main_queue()) {
                        i.view.hidden = false
                    }
                }
                
                if let d = vc as? DeviceInspectorDataViewController {
                    self.dataVC = d
                    dispatch_async(dispatch_get_main_queue()) {
                        d.view.hidden = true
                    }
                }
                
                if let e = vc as? DeviceInspectorEventsViewController {
                    self.eventsVC = e
                    dispatch_async(dispatch_get_main_queue()) {
                        e.view.hidden = true
                    }
                }
                
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        self.deviceNameLabel.text = self.device?.name
        self.device!.delegate = self
        ParticleUtils.animateOnlineIndicatorImageView(self.deviceOnlineIndicatorImageView, online: self.device!.connected, flashing: self.device!.isFlashing)
    }
    
    var flashedTinker : Bool = false
    
    func sparkDevice(device: SparkDevice, didReceiveSystemEvent event: SparkDeviceSystemEvent) {
        ParticleUtils.animateOnlineIndicatorImageView(self.deviceOnlineIndicatorImageView, online: self.device!.connected, flashing: self.device!.isFlashing)
        if self.flashedTinker && event == .FlashSucceeded {
            
            SEGAnalytics.sharedAnalytics().track("Device Inspector: reflash Tinker success")
            dispatch_async(dispatch_get_main_queue()) {
                TSMessage.showNotificationWithTitle("Flashing successful", subtitle: "Your device has been flashed with Tinker firmware successfully", type: .Success)
            }
            self.flashedTinker = false
//            self.refreshData()
            
        }
        
        self.refreshData()
    }
    
    
    
    
    func refreshData() {
        self.device?.refresh({[weak self] (err: NSError?) in
            
            SEGAnalytics.sharedAnalytics().track("Device Inspector: refreshed data")
            // test what happens when device goes offline and refresh is triggered
            if (err == nil) {
                
                if let s = self {
                    s.viewWillAppear(false)
                    
                    if let info = s.infoVC {
                        info.device = s.device
                        info.updateDeviceInfoDisplay()
                    }
                    
                    if let data = s.dataVC {
                        data.device = s.device
                        data.refreshVariableList()
                    }
                    
                    if let events = s.eventsVC {
                        events.unsubscribeFromDeviceEvents()
                        events.device = s.device
                        if !events.paused {
                            events.subscribeToDeviceEvents()
                        }
                        
                    }
                }
            }
            })
    }
    
    
    // 2
    func reflashTinker() {

//        if !self.device!.connected {
//            TSMessage.showNotificationWithTitle("Device offline", subtitle: "Device must be online to be flashed", type: .Error)
//            return
//        }
        SEGAnalytics.sharedAnalytics().track("Device Inspector: reflash Tinker start")
        
        func flashTinkerBinary(binaryFilename : String?)
        {
            let bundle = NSBundle.mainBundle()
            let path = bundle.pathForResource(binaryFilename, ofType: "bin")
            let binary = NSData(contentsOfURL: NSURL(fileURLWithPath: path!))
            let filesDict = ["tinker.bin" : binary!]
            self.flashedTinker = true
            self.device!.flashFiles(filesDict, completion: { [weak self] (error:NSError?) -> Void in
                if let e=error
                {
                    if let s = self {
                        s.flashedTinker = false
                        TSMessage.showNotificationWithTitle("Flashing error", subtitle: "Error flashing device. Are you sure it's online? \(e.localizedDescription)", type: .Error)
                    }
                    
                }
            })
        }
        
        
        switch (self.device!.type)
        {
        case .Core:
            //                                        SEGAnalytics.sharedAnalytics().track("Tinker: Reflash Tinker",
            SEGAnalytics.sharedAnalytics().track("Tinker: Reflash Tinker", properties: ["device":"Core"])
            self.flashedTinker = true
            self.device!.flashKnownApp("tinker", completion: { (error:NSError?) -> Void in
                if let e=error
                {
                    TSMessage.showNotificationWithTitle("Flashing error", subtitle: "Error flashing device: \(e.localizedDescription)", type: .Error)
                }
            })
            
        case .Photon:
            SEGAnalytics.sharedAnalytics().track("Tinker: Reflash Tinker", properties: ["device":"Photon"])
            flashTinkerBinary("photon-tinker")
            
        case .Electron:
            SEGAnalytics.sharedAnalytics().track("Tinker: Reflash Tinker", properties: ["device":"Electron"])
            
            let dialog = ZAlertView(title: "Flashing Electron", message: "Flashing Tinker to Electron via cellular will consume data from your data plan, are you sure you want to continue?", isOkButtonLeft: true, okButtonText: "No", cancelButtonText: "Yes",
                                    okButtonHandler: { alertView in
                                        alertView.dismiss()
                                        
                },
                                    cancelButtonHandler: { alertView in
                                        alertView.dismiss()
                                        flashTinkerBinary("electron-tinker")
                                        
                }
            )
            
            
            
            dialog.show()
            
        default:
            TSMessage.showNotificationWithTitle("Reflash Tinker", subtitle: "Cannot flash Tinker to a non-Particle device", type: .Warning)
            
            
        }
        
    }
    
    
    func popDocumentationViewController() {

        SEGAnalytics.sharedAnalytics().track("Device Inspector: documentation")
        self.performSegueWithIdentifier("help", sender: self)
//        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc : UIViewController = storyboard.instantiateViewControllerWithIdentifier("help")
//        self.navigationController?.pushViewController(vc, animated: true)
    }


    @IBOutlet weak var infoContainerView: UIView!
    
    @IBOutlet weak var moreActionsButton: UIButton!
    
    func showTutorial() {
        
        if ParticleUtils.shouldDisplayTutorialForViewController(self) {
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                
                if self.navigationController?.visibleViewController == self {
                    // viewController is visible
                    
                    // 3
//                    var tutorial = YCTutorialBox(headline: "Additional actions", withHelpText: "Tap the three dots button for more actions such as reflashing the Tinker firmware, force refreshing the device info/data, signal the device (LED shouting rainbows), changing device name and easily accessing Particle documentation and support portal.")
//                    tutorial.showAndFocusView(self.moreActionsButton)
//                    
//                    // 2
//                    tutorial = YCTutorialBox(headline: "Modes", withHelpText: "Device inspector has 3 modes - tap 'Info' to see your device network parameters, tap 'data' to interact with your device exposed functions and variables, tap 'events' to view a searchable list of the device published events.")
//                    
//                    tutorial.showAndFocusView(self.modeSegmentedControl)
                    
                    
                    // 1
                    let tutorial = YCTutorialBox(headline: "Welcome to Device Inspector", withHelpText: "See advanced information on your device. Tap the blue clipboard icon to copy device ID or ICCID field to the clipboard.", withCompletionBlock: {
                        // 2
                        let tutorial = YCTutorialBox(headline: "Modes", withHelpText: "Device inspector has 3 modes:\n\nInfo - see your device network parameters.\n\nData - interact with your device's functions and variables.\n\nEvents - view a real-time searchable list of published events.", withCompletionBlock:  {
                            let tutorial = YCTutorialBox(headline: "Additional actions", withHelpText: "Tap the additional actions button for reflashing Tinker firmware, force refreshing the device info and data, signal (identify a device by its LED color-cycling), renaming a device and easily accessing Particle documentation and support portal.")
                            
                            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
                            dispatch_after(delayTime, dispatch_get_main_queue()) {
                                tutorial.showAndFocusView(self.moreActionsButton)
                            }
                            

                        })
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                        
                            tutorial.showAndFocusView(self.modeSegmentedControl)
                        }

                    })
                    
                    tutorial.showAndFocusView(self.infoContainerView)
                    
                    ParticleUtils.setTutorialWasDisplayedForViewController(self)
                }
                
            }
        }
    }
    
    
    
}