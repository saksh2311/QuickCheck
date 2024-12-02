//
//  TabBarController.swift
//  QuickCheck
//
//  Created by Sakshi Patil on 12/1/24.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    var CurrentDetails : UIViewController.BasicDetails?
    
    // Tutor Tabs
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        self.delegate = self

        tabBar.tintColor = UIColor.green
        tabBar.barTintColor = UIColor.darkText
        
    }

    
    

}
