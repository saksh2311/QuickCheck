//
//  TabBarController.swift
//  QuickCheck
//
//  Created by Rumjhum Singru on 12/3/24.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    var CurrentDetails : UIViewController.BasicDetails?
    
    let classHomeViewController : ClassHomeViewController = ClassHomeViewController()
    let QRCodeViewController : GenerateQRCodeViewController = GenerateQRCodeViewController()
    let MyStudentViewController : MyStudentsViewController = MyStudentsViewController()
    let ProfileViewController : MyProfileViewController = MyProfileViewController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        self.delegate = self

        tabBar.tintColor = UIColor.green
        tabBar.barTintColor = UIColor.darkText
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        if CurrentDetails?.UserType == "tutors"{
            initiateTutorTabs()
        }
        
        else if CurrentDetails?.UserType == "students"{
            initiateStudentTabs()
        }
    }

    // Animations
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView: UIView = viewController.view
        
        if fromView == toView {
            return false
        }
        
        if let tappedIndex = tabBarController.viewControllers?.index(of: viewController) {
            if tappedIndex > tabBarController.selectedIndex {
                UIView.transition(from: fromView, to: toView, duration: 0.5, options: UIView.AnimationOptions.transitionFlipFromLeft, completion: nil)
            } else {
                UIView.transition(from: fromView, to: toView, duration: 0.5, options: UIView.AnimationOptions.transitionFlipFromRight, completion: nil)
            }
        }
        return true
    }
    
    func initiateTutorTabs(){
        // Class Home viewController
        classHomeViewController.CurrentDetails = CurrentDetails
        let classHomeTab = UINavigationController(rootViewController: classHomeViewController)
        classHomeTab.tabBarItem.title = "Home"
        classHomeTab.tabBarItem.image = UIImage(systemName: "house.fill")

        
        // QR Code viewController
        QRCodeViewController.CurrentDetails = CurrentDetails
        let qrCodeTab = UINavigationController(rootViewController: QRCodeViewController)
        qrCodeTab.tabBarItem.title = "Generate QR"
        qrCodeTab.tabBarItem.image = UIImage(systemName: "qrcode")

        // My Students viewController
        MyStudentViewController.basicDetails = CurrentDetails
        let myStudentTab = UINavigationController(rootViewController: MyStudentViewController)
        myStudentTab.tabBarItem.title = "My Students"
        myStudentTab.tabBarItem.image = UIImage(systemName: "person.3.fill")

        // My profile viewController
        ProfileViewController.CurrentDetails = CurrentDetails
        let profileTab = UINavigationController(rootViewController: ProfileViewController)
        profileTab.tabBarItem.title = "My Profile"
        profileTab.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        
        
        viewControllers = [classHomeTab, qrCodeTab, myStudentTab, profileTab]
    }
    
    
    func initiateStudentTabs(){
        
        let qrScannerViewController : StudentGetQRCodeViewController = StudentGetQRCodeViewController()
        qrScannerViewController.CurrentDetails = CurrentDetails
        let qrScannerTab = UINavigationController(rootViewController: qrScannerViewController)
        qrScannerTab.tabBarItem.title = "Scan QR"
        qrScannerTab.tabBarItem.image = UIImage(systemName: "qrcode.viewfinder")
        
        let myAttendanceViewController : StudentMyAttendanceViewController = StudentMyAttendanceViewController()
        myAttendanceViewController.CurrentDetails = CurrentDetails
        
        let myAttendanceTab = UINavigationController(rootViewController: myAttendanceViewController)
        myAttendanceTab.tabBarItem.title = "My Attendance"
        myAttendanceTab.tabBarItem.image = UIImage(systemName: "checkmark.rectangle.fill")
        
        
        ProfileViewController.CurrentDetails = CurrentDetails
        let profileTab = UINavigationController(rootViewController: ProfileViewController)
        profileTab.tabBarItem.title = "My Profile"
        profileTab.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        
        
         viewControllers = [myAttendanceTab, qrScannerTab, profileTab]
    }
    

}
