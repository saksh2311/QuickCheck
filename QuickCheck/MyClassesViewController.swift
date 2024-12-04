//
//  MyClassesViewController.swift
//  QuickCheck
//
//  Created by Sakshi Patil on 12/1/24.
//

import UIKit
import Firebase

class MyClassesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let reuseIdentifier = "Cell"
    let defaultImageURL = "https://firebasestorage.googleapis.com/v0/b/cs5520-ios-project.firebasestorage.app/o/default_class_logo.png?alt=media&token=df28a7f3-c7be-4974-a7cb-7aca3ea33c87"

    struct ClassDetails {
        var ClassID : String?
        var ClassName : String?
        var PosterURL : String?
    }
    
    struct UserDetails {
        let UserName : String?
        let UserID : String?
        let UserType : String?
    }
    
    var CurrentUserDetails = UserDetails(UserName: "userName", UserID: "userId", UserType: "userType")
    
    var MyClassList = [ClassDetails]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        self.collectionView!.register(myCustomCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // If user is not logged in
        if Auth.auth().currentUser?.uid == nil {
            
        }
        else{
            
            self.navigationItem.title = "My Classes"
            
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            
            let addClassButton : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddClass))
            let config = UIImage.SymbolConfiguration(weight: .bold)
            let personImage = UIImage(systemName: "person.circle.fill")?
                    .withConfiguration(config)
                    .withTintColor(.black, renderingMode: .alwaysOriginal)
            let profileButton : UIBarButtonItem = UIBarButtonItem(image: personImage, style: .plain, target: self, action: #selector(handleProfile))
            
            self.navigationItem.leftBarButtonItem = profileButton
            self.navigationItem.rightBarButtonItem = addClassButton
            
        }

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if Auth.auth().currentUser?.uid != nil {
             getUserDetails()
        }

    }
    
    
    func getUserDetails(){
        let userId = Auth.auth().currentUser?.uid
        let ref : DatabaseReference = Database.database().reference()
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            var userType = ""
            if(snapshot.childSnapshot(forPath: "tutors").hasChild(userId!)){
                userType = "tutors"
            }
            else{
                userType = "students"
            }
            
            let currentUserSnaphot : DataSnapshot = snapshot.childSnapshot(forPath: userType).childSnapshot(forPath: userId!)
            let userName = currentUserSnaphot.childSnapshot(forPath: "user_name").value as? String ?? ""
            
            self.CurrentUserDetails = UserDetails(UserName: userName, UserID: userId, UserType: userType)
            
            self.populateMyClassesList()

        })
    }
    
    
    func populateMyClassesList(){
        MyClassList.removeAll()
        
        let usertype = CurrentUserDetails.UserType!
        let userid = CurrentUserDetails.UserID!
        
        let ref : DatabaseReference = Database.database().reference()
        ref.observeSingleEvent(of: .value, with: {(snapshot)
            in
            let myClassSnapshot = snapshot.childSnapshot(forPath: usertype).childSnapshot(forPath: userid).childSnapshot(forPath: "my_classes")
            
            if myClassSnapshot.childrenCount >= 1 {
                let enumerator = myClassSnapshot.children
                while let currentClass = enumerator.nextObject() as? DataSnapshot {
                    
                    let classId = currentClass.key
                    if !classId.contains("default"){
                        let className = snapshot.childSnapshot(forPath: "classes").childSnapshot(forPath: classId).childSnapshot(forPath: "class_name").value as? String
                        
                        
                        let currentClassDetails = ClassDetails.init(ClassID: classId, ClassName: className, PosterURL: self.defaultImageURL)
                        self.MyClassList.append(currentClassDetails)
                    }
                    
                }
                self.collectionView?.reloadData()
            }
        })
    }
    
    
    
    // For students to add new class using id
    func addClassUsingIdForStudents(){
        // Create the alert controller.
        let alert = UIAlertController(title: "Add New Class", message: "Please provide a valid code provided by your tutor of the class you wish to enroll.", preferredStyle: .alert)
        
        // Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Class Code"
        })
        
        // Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (action) -> Void in
            let textField = (alert?.textFields![0])! as UITextField
            let givenClassId = textField.text
            if !(givenClassId?.isEmpty)!{
                
                // Check if has invalid Character
                if (givenClassId?.hasInvalidCharacters())!{
                    self.showAlert(AlertTitle: "Enrollment failed", Message: "Class Code has invalid characters.")
                }
                else{
                    self.checkAndAddClass(givenClassId: givenClassId!)
                }
            }
            else{
                self.showAlert(AlertTitle: "Enrollment failed", Message: "Class Code cannot be blank.")
            }
        }))
        
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func checkAndAddClass(givenClassId : String){
        
        let studentId = CurrentUserDetails.UserID!
        let ref : DatabaseReference = Database.database().reference()

        
        
        // Check if this is a valid class id
        ref.observeSingleEvent(of: .value, with: {(snapshot)
            in
            
            let classesSnapshot : DataSnapshot = snapshot.childSnapshot(forPath: "classes")
            let currentClassSnapshot : DataSnapshot = classesSnapshot.childSnapshot(forPath: givenClassId)
            
            
            // Checking for valid class id
            if classesSnapshot.hasChild(givenClassId){
                // Class id is valid
                
                if givenClassId == "default"{
                    
                }
                
                else if currentClassSnapshot.hasChild(studentId){
                    // Student already enrolled
                    self.showAlert(AlertTitle: "Enrollment failed", Message: "You already enrolled to this class!")
                }
                
                else{
                    // New enrollment.. Add student to class
                    ref.child("classes").child(givenClassId).child("students").child(studentId).setValue("0")
                    
                    // Add this class to the students class list
                    ref.child("students").child(studentId).child("my_classes").child(givenClassId).setValue("0")
                    
                    // Reload the classes List
                     self.populateMyClassesList()
                }
                
            }
            
            else{
                // Invalid class Id
                self.showAlert(AlertTitle: "Invalid Class Code", Message: "The class code that you entered is invalid. Please make sure you use a valid Class Code to enroll into the class.")
            }
            
        })
    }
    
    
    @objc func handleAddClass(){
        print("Add class pressed")
        if CurrentUserDetails.UserType == "tutors"{
        self.navigationController?.pushViewController(AddClassViewController(), animated: true)
        }
        else if CurrentUserDetails.UserType == "students" {
            print("Students")
            addClassUsingIdForStudents()
        }
    }
    
    // Add handler for profile button
    @objc func handleProfile() {
        let profileVC = MyProfileViewController()
        let basicDetails = BasicDetails(UserName: self.CurrentUserDetails.UserName, UserID: self.CurrentUserDetails.UserID, UserType: self.CurrentUserDetails.UserType)
        profileVC.CurrentDetails = basicDetails
        self.navigationController?.pushViewController(profileVC, animated: true)
    }

    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MyClassList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! myCustomCell
        
        cell.posterImageView.image = nil
        
        let defaultImageURL = "https://firebasestorage.googleapis.com/v0/b/cs5520-ios-project.firebasestorage.app/o/default_class_logo.png?alt=media&token=df28a7f3-c7be-4974-a7cb-7aca3ea33c87"
        
        if let posterURL = MyClassList[indexPath.row].PosterURL {
            self.downloadImageIntoView(imagePath: posterURL, imageView: cell.posterImageView)
        } else {
            self.downloadImageIntoView(imagePath: defaultImageURL, imageView: cell.posterImageView)
        }
        
        cell.classNameLabel.text = MyClassList[indexPath.row].ClassName
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 150 , height: 200)
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let cellWidth : CGFloat = 150.0
        
        let numberOfCells = floor(self.view.frame.size.width / cellWidth)
        let edgeInsets = (self.view.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        return UIEdgeInsets(top: 20, left: edgeInsets, bottom: 0, right: edgeInsets)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let tabBarController : TabBarController = TabBarController()
        
        let details = UIViewController.BasicDetails(UserName: CurrentUserDetails.UserName, UserID: CurrentUserDetails.UserID, UserType: CurrentUserDetails.UserType, ClassID: MyClassList[indexPath.row].ClassID, ClassName: MyClassList[indexPath.row].ClassName, PosterURL: MyClassList[indexPath.row].PosterURL)
        
        tabBarController.CurrentDetails = details

        self.navigationController?.pushViewController(tabBarController, animated: true)
        
    }

}


class myCustomCell : UICollectionViewCell {
    
    // Background image
    var myImage : UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints  = false
        image.contentMode = .scaleToFill
        image.image = UIImage(named: "blank_image")
        return image
    }()
    
    // BaseView
    let baseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Book Poster imageView
    let posterImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    // Class name label
    var classNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(myImage)
        myImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        myImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        myImage.heightAnchor.constraint(equalToConstant: 200).isActive = true
        myImage.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        // Setting the baseView
        addSubview(baseView)
        baseView.leftAnchor.constraint(equalTo: leftAnchor, constant: 22).isActive = true
        baseView.rightAnchor.constraint(equalTo: rightAnchor, constant: -9).isActive = true
        baseView.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
        baseView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11).isActive = true
        
        
        // Setting the poster ImageView
        addSubview(posterImageView)
        posterImageView.centerXAnchor.constraint(equalTo: baseView.centerXAnchor).isActive = true
        posterImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        posterImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        posterImageView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: 5).isActive = true

        // Setting the class name label
        addSubview(classNameLabel)
        classNameLabel.centerXAnchor.constraint(equalTo: baseView.centerXAnchor).isActive = true
        classNameLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor).isActive = true
        classNameLabel.leftAnchor.constraint(equalTo: baseView.leftAnchor, constant: 4).isActive = true
        classNameLabel.rightAnchor.constraint(equalTo: baseView.rightAnchor, constant: -4).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
