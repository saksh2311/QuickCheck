//
//  TutorMyStudentsViewController.swift
//  QuickCheck
//
//  Created by Vanshita Tilwani on 12/2/24.
//


import UIKit
import Firebase

class MyStudentsViewController: UITableViewController, UISearchResultsUpdating {
    
    var basicDetails : UIViewController.BasicDetails?

    var isSearching = false
    var searchKeyword = ""
    
    // Student details object
    struct studentDetailsObject {
        var StudentId : String?
        var StudentName : String?
        var ProfilePath : String?
        var ProfileImage : UIImage?
    }
    
    var studentsDetailsList = [studentDetailsObject]()
    var filteredStudentList = [studentDetailsObject]()
    
    
    var searchController = UISearchController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        tableView.backgroundColor = UIColor.white
        
        self.edgesForExtendedLayout = []
        self.navigationController?.navigationBar.barStyle = .blackTranslucent

        tableView.register(CustomStudentCell.self, forCellReuseIdentifier: "myCell")

        populateStudentDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.title = "My Students"
        setupSearchBar()
        
        let addClassButton = UIBarButtonItem(
            image: UIImage(systemName: "person.fill.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(handleAddStudent)
        )

        self.tabBarController?.navigationItem.rightBarButtonItem = addClassButton
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.tabBarController?.navigationItem.rightBarButtonItem = nil
        self.tabBarController?.navigationItem.searchController = nil
    }
    
    @objc func handleAddStudent(){
        // Create the alert controller.
        let alert = UIAlertController(title: "Add New Student", message: "Please provide a valid student code.", preferredStyle: .alert)
        
        // Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Student Code"
        })
        
        // Grab the value from the text field when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (action) -> Void in
            let textField = (alert?.textFields![0])! as UITextField
            let givenStudentCode = textField.text
            if !(givenStudentCode?.isEmpty)!{
                
                // Check if givenCode has invalid characters
                if (givenStudentCode?.hasInvalidCharacters())!{
                    self.showAlert(AlertTitle: "Invalid Code", Message: "Class Code has invalid characters.")
                }
                else{
                    self.checkAndAddStudent(givenStudentCode: givenStudentCode!)
                }
                
            }
            else{
//                self.showAlert(AlertTitle: "Cannot add student", Message: "Student Code cannot be blank.")
            }
        }))
        
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func populateStudentDetails(){
        
        studentsDetailsList.removeAll()
        
        let classId = basicDetails?.ClassID!
        let ref : DatabaseReference = Database.database().reference()
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            // My Snapshots
            let currentClassSnapshot : DataSnapshot = snapshot.childSnapshot(forPath: "classes").childSnapshot(forPath: classId!)
            let myStudentsSnapshot : DataSnapshot = currentClassSnapshot.childSnapshot(forPath: "students")
            
            if myStudentsSnapshot.hasChildren(){
                print("This class has children")
                
                for studentSnap in (myStudentsSnapshot.children.allObjects as? [DataSnapshot])!{
                    let currentStudentId = studentSnap.key
                    if currentStudentId != "default"{
                        let studentSnapshot : DataSnapshot = snapshot.childSnapshot(forPath: "students").childSnapshot(forPath: currentStudentId)
                        let studentName = studentSnapshot.childSnapshot(forPath: "user_name").value as? String
                        let profilePath = studentSnapshot.childSnapshot(forPath: "picture_path").value as? String
                        
                        let studentItem = studentDetailsObject(StudentId: currentStudentId, StudentName: studentName, ProfilePath: profilePath, ProfileImage: nil)
                        self.studentsDetailsList.append(studentItem)
                    }
                }
                self.tableView.reloadData()
            }
            
            else{
                print("No students in this class")
            }
            
        })
        
    }
    
    
    func checkAndAddStudent(givenStudentCode : String){
        
        let classId = (basicDetails?.ClassID)!
        
        let ref : DatabaseReference =  Database.database().reference()
        let studentRef : DatabaseReference = ref.child("students")
        let classStudentsRef : DatabaseReference = ref.child("classes").child(classId).child("students")
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            let studentSnap : DataSnapshot = snapshot.childSnapshot(forPath: "students")
            
            // Check if provided Student ID actually exists
            let isStudentIdValid = studentSnap.hasChild(givenStudentCode)
            if isStudentIdValid {
                
                // Check if student already enrolled
                let isStudentEnrolled = studentSnap.childSnapshot(forPath: givenStudentCode).childSnapshot(forPath: "my_classes").hasChild(classId)
                
                if isStudentEnrolled{
                    // Student already enrolled
                    self.showAlert(AlertTitle: "Already Enrolled", Message: "This student is already enrolled in your class.")
                }
                else{
                    // Student not enrolled yet. Enroll the student
                    studentRef.child(givenStudentCode).child("my_classes").child(classId).setValue("0")
                    classStudentsRef.child(givenStudentCode).setValue("0", withCompletionBlock: {
                        (error, ref) in
                        print("Student added!")
                        self.populateStudentDetails()
                    })
                }
            }
            
            else{
                self.showAlert(AlertTitle: "Invalid Student Id", Message: "There is no student with this Id. Please provide a valid student id.")
            }
        })
    }
    

    func setupSearchBar(){
        searchController = UISearchController(searchResultsController: nil)
        self.tabBarController?.navigationItem.searchController = searchController
        self.tabBarController?.navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search for students enrolled in class",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField,
        let leftView = textField.leftView as? UIImageView {
            leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
            leftView.tintColor = UIColor.gray
        }
        searchController.searchResultsUpdater = self
        searchController.definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false

        searchController.searchBar.barTintColor = UIColor.black
        searchController.searchBar.backgroundImage = UIImage()
        
        if searchKeyword != ""{
            searchController.searchBar.text = searchKeyword
            isSearching = true
        }
        
        else{
            isSearching = false
        }
        
        
    }
    
    
    // Search controller delegate method
    func updateSearchResults(for searchController: UISearchController) {
        
        let keyword = (searchController.searchBar.text!).lowercased()
        searchKeyword = keyword
        
        if !keyword.isEmpty{
        isSearching = true
        filteredStudentList.removeAll()
        
        var counter = 0
        for student in studentsDetailsList{
            let name = student.StudentName!
            if name.lowercased().contains(keyword){
                print(name)
                let cell = tableView.cellForRow(at: [0, counter]) as? CustomStudentCell
                let profile = cell?.profileImageView.image
                
                let stdItem = studentDetailsObject(StudentId: student.StudentId, StudentName: student.StudentName, ProfilePath: student.ProfilePath, ProfileImage: profile)
                
                filteredStudentList.append(stdItem)
            }
            counter += 1
        }
            
        }
        else{
            isSearching = false
        }
        tableView.reloadData()
    }
    
    // SearchBar helper methods
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching{
            return filteredStudentList.count
        }
        else{
            return studentsDetailsList.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as! CustomStudentCell
        let config = UIImage.SymbolConfiguration(hierarchicalColor: .black)
        
        var studentName, profilePath : String?
        cell.profileImageView.image = UIImage(systemName: "person.circle", withConfiguration: config)
        
        if isSearching{
            studentName = filteredStudentList[indexPath.row].StudentName
            profilePath = filteredStudentList[indexPath.row].ProfilePath
            if let image = filteredStudentList[indexPath.row].ProfileImage{
                cell.profileImageView.image = image
            }
            else{
                self.downloadImageIntoView(imagePath: profilePath!, imageView: cell.profileImageView)
            }
            
        }
        else{
            studentName = studentsDetailsList[indexPath.row].StudentName
            profilePath = studentsDetailsList[indexPath.row].ProfilePath
            self.downloadImageIntoView(imagePath: profilePath!, imageView: cell.profileImageView)
        }
        
        cell.studentNameLabel.text = studentName
       
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var selectedStdId = ""
        var selectedStdName = ""
        
        if isSearching{
            selectedStdId = filteredStudentList[indexPath.row].StudentId!
            selectedStdName = filteredStudentList[indexPath.row].StudentName!
        }
        
        else{
            selectedStdId = studentsDetailsList[indexPath.row].StudentId!
            selectedStdName = studentsDetailsList[indexPath.row].StudentName!
        }
        
        
        let Details = BasicDetails(UserName: selectedStdName, UserID: selectedStdId, UserType: "tutors", ClassID: basicDetails?.ClassID, ClassName: basicDetails?.ClassName, PosterURL: basicDetails?.PosterURL)
        
        
        // Open Student Details ViewController
        let AttendanceDetails : StudentMyAttendanceViewController = StudentMyAttendanceViewController()
        AttendanceDetails.CurrentDetails = Details
        AttendanceDetails.ViewTitle = selectedStdName
        
        self.tabBarController?.navigationController?.pushViewController(AttendanceDetails, animated: true)
        
        
    }
    
    // My Custom Table View cell
    
    class CustomStudentCell : UITableViewCell {
        
        // My views
        // Base View
        let baseCellView : UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor.white
            return view
        }()
        
        
        // profile imageView
        var profileImageView  : UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = UIImage(systemName: "person.circle")
            
            imageView.layer.cornerRadius = 30
            imageView.layer.masksToBounds = true
            
            return imageView
        }()
        
        
        // Student Name label
        var studentNameLabel : UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .left
            label.adjustsFontSizeToFitWidth = true
            label.textColor = UIColor.black
            return label
        }()
        
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            addSubview(baseCellView)
            baseCellView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            baseCellView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            baseCellView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            baseCellView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            baseCellView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            
            
            
            baseCellView.addSubview(profileImageView)
            profileImageView.centerYAnchor.constraint(equalTo: baseCellView.centerYAnchor).isActive = true
            profileImageView.leftAnchor.constraint(equalTo: baseCellView.leftAnchor, constant: 16).isActive = true
            profileImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            profileImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
            
            baseCellView.addSubview(studentNameLabel)
            studentNameLabel.centerYAnchor.constraint(equalTo: baseCellView.centerYAnchor).isActive = true
            studentNameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 16).isActive = true
            studentNameLabel.rightAnchor.constraint(equalTo: baseCellView.rightAnchor, constant: -16).isActive = true
            studentNameLabel.widthAnchor.constraint(equalTo: baseCellView.widthAnchor, constant: -108).isActive = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
}
