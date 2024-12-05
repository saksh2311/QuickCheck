//
//  TutorClassHomeViewController.swift
//  QuickCheck
//
//  Created by Vanshita Tilwani on 12/2/24.
//


import UIKit
import Firebase

class ClassHomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {

    var CurrentDetails : UIViewController.BasicDetails?

    struct studentObject {
        var studentName : String?
        var profilePath : String?
        var studentId : String?
        var isPresent : Bool?
    }
    
    var studentAttendanceList = [studentObject]()
    var studentsCount : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Home"
        
        self.edgesForExtendedLayout = []
        self.navigationController?.navigationBar.barStyle = .blackTranslucent

        view.backgroundColor = UIColor.white
        

        setupView()
        setDataToViews()
        populateLectureDetails()
        populateStudentsList()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set navigation items directly on the navigation item
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.searchController = nil
    }
    
    func populateLectureDetails(){
        
        let classId = (CurrentDetails?.ClassID)!
        let ref : DatabaseReference = Database.database().reference()
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            let currentClassSnap : DataSnapshot = snapshot.childSnapshot(forPath: "classes").childSnapshot(forPath: classId)
            
            var totalLectures = Int ((currentClassSnap.childSnapshot(forPath: "total_lectures").value as? String)!)
            let finishedLectures = Int (currentClassSnap.childSnapshot(forPath: "attendance").childrenCount) - 1
            var remainingLectures = totalLectures! - finishedLectures
            if remainingLectures < 0{
                totalLectures = finishedLectures
                remainingLectures = 0
            }
            self.courseDetailsID.text = "Class ID : \(classId)"
            self.totalLecturesLabel.text = "Total Lectures : \(totalLectures ?? 0)"
            self.presentLectureLabel.text = "Present Lecture : \(finishedLectures)"
            self.remainingLectureLabel.text = "Remaining Lectures : \(remainingLectures)"
        })
        
    }
    
    
    func populateStudentsList(){
        
        let classId = (CurrentDetails?.ClassID)!
        let ref : DatabaseReference = Database.database().reference()
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in

            
            let classSnap : DataSnapshot = snapshot.childSnapshot(forPath: "classes").childSnapshot(forPath: classId)
            
            self.studentsCount = Int (classSnap.childSnapshot(forPath: "students").childrenCount) - 1
            
            if self.studentsCount > 0{
                // class has students
                for student in (classSnap.childSnapshot(forPath: "students").children.allObjects as? [DataSnapshot])! {
                    
                    let studentId = student.key
                    if studentId != "default"{
                        let studentSnap = snapshot.childSnapshot(forPath: "students").childSnapshot(forPath: studentId)
                        
                        let name = studentSnap.childSnapshot(forPath: "user_name").value as? String
                        let profilePath = studentSnap.childSnapshot(forPath: "picture_path").value as? String
                        
                        let stdItem = studentObject(studentName: name, profilePath: profilePath, studentId: studentId, isPresent: false)
                        self.studentAttendanceList.append(stdItem)
                    }
                }
                
                // Call the attendance function
                self.startObservingTodaysAttendance()
                
            }
        })
    }
    
    
    
    func startObservingTodaysAttendance(){
        
        let classId = (CurrentDetails?.ClassID)!
        let ref : DatabaseReference = Database.database().reference()
        let classRef : DatabaseReference = ref.child("classes").child(classId)
        
        // Start observing
        classRef.observe(.value, with: { (snapshot) in
            
            let currentAttendanceId = (snapshot.childSnapshot(forPath: "latest_attendance").value as? String)!
            
            if (!currentAttendanceId.isEmpty){
                let attendanceSnapshot : DataSnapshot = snapshot.childSnapshot(forPath: "attendance").childSnapshot(forPath: currentAttendanceId)
                
                let presentCount = Int (attendanceSnapshot.childSnapshot(forPath: "students_present").childrenCount)
                
                
                // Set present and absent in my list
                for index in self.studentAttendanceList.indices{
                    let studentId = self.studentAttendanceList[index].studentId
                    
                    if attendanceSnapshot.childSnapshot(forPath: "students_present").hasChild(studentId!){
                        // Student Present
                        self.studentAttendanceList[index].isPresent = true
                    }
                    else{
                        // Student absent
                        self.studentAttendanceList[index].isPresent = false
                    }
                }
                
                // Get counts
                let totalStrength = self.studentAttendanceList.count
                let absentCount = totalStrength - presentCount
                
                // Set labels
                self.classStrengthLabel.text = " Total \n \(totalStrength)"
                self.presentTodayLabel.text = "Present \n \(presentCount)"
                self.absentTodayLabel.text = "Absent \n \(absentCount)"
                
                // Reload tableView
                self.studentsAttendanceTableView.reloadData()
            }
            
        })
        
        
    }
    
    
    func setDataToViews(){
        classNameLabel.text = CurrentDetails?.ClassName
        timestampLabel.text = getCurrentDate()
        
        self.downloadImageIntoView(imagePath: (CurrentDetails?.PosterURL)!, imageView: backgroundPosterImageView)
    }
    
    
    func getCurrentDate() -> String {
        let currentDateTime = Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        
        return formatter.string(from: currentDateTime)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentAttendanceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "studentCell", for: indexPath) as! MyCustomStudentCell
        
        cell.selectionStyle = .none
        
        cell.studentNameLabel.text = studentAttendanceList[indexPath.row].studentName
        
        if studentAttendanceList[indexPath.row].isPresent!{
            cell.cellBaseView.backgroundColor = UIColor.myGreenTint
            cell.statusImageView.image = UIImage(named: "blank_image")
        }
        else{
            cell.cellBaseView.backgroundColor = UIColor.myRedTint
            cell.statusImageView.image = UIImage(named: "blank_image")
        }

        return cell
    }
    
    
    // Custom TableView Cell Class
    class MyCustomStudentCell : UITableViewCell {
        
        // BaseView
        let cellBaseView : UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 25
            view.layer.masksToBounds = true
            return view
        }()
        
        let studentNameLabel : UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .left
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        let statusImageView : UIImageView = {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = UIImage(named: "blank_image")
            return imageView
        }()
        
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            addSubview(cellBaseView)
            cellBaseView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
            cellBaseView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
            cellBaseView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
            cellBaseView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
            cellBaseView.heightAnchor.constraint(equalToConstant: 50).isActive = true

            // Add other views to baseView
            cellBaseView.addSubview(studentNameLabel)
            studentNameLabel.centerYAnchor.constraint(equalTo: cellBaseView.centerYAnchor).isActive = true
            studentNameLabel.leftAnchor.constraint(equalTo: cellBaseView.leftAnchor, constant: 25).isActive = true
            
            cellBaseView.addSubview(statusImageView)
            statusImageView.centerYAnchor.constraint(equalTo: cellBaseView.centerYAnchor).isActive = true
            statusImageView.leftAnchor.constraint(equalTo: studentNameLabel.rightAnchor).isActive = true
            statusImageView.rightAnchor.constraint(equalTo: cellBaseView.rightAnchor, constant: -25).isActive = true
            statusImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            statusImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true


        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        
    }
    
    
    let backgroundBaseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Background class poster
    let backgroundPosterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // scroll view
    let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = true
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    
    let placeHolderView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // BaseView
    let baseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Round corners
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        // Border
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1.5
        // Shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 10.0
        view.layer.shadowOffset = CGSize(width: 0, height: -5)
        
        return view
    }()
    
    // base stackview
    let stackView : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
    
    // Class name label
    let classNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    
    // Timestamp label
    var timestampLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    
    // ClassDetails divider
    let classDetailsDivider : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.darkGray
        return view
    }()
    
    
    
    // Course Details views
    // Course details baseView
    let courseDetailsBaseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let courseDetailsStackView : UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 3
        return stackView
    }()

    
    // Class Details label
    var attendanceDetailsLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 25)
        label.textAlignment = .center
        label.text = "Your Recent Class"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    
    // Class strength label
    var classStrengthLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Total \n 0"
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Class strength label
    var presentTodayLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Present \n 0"
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Class strength label
    var absentTodayLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Absent \n 0"
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    let courseDetailsPlaceHolder : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    // Course Details label
    var courseDetailsLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 25)
        label.textAlignment = .center
        label.text = "Course Details"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Class ID
    var courseDetailsID : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Class ID : "
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    // Course Lectures Count label
    var totalLecturesLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Total Lectures : 0"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Current Lecture number label
    var presentLectureLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Present Lectures : 0"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Remaining lectures label
    var remainingLectureLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Remaining Lectures : 0"
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    // Course Details divider
    let courseDetailsDivider : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.darkGray
        return view
    }()
    
    
    let blankSpaceHolder : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    
    var studentsAttendanceTableView : UITableView = {
       let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    // Setting up the view
    func setupView() {
        // Setup content view for scroll view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
            
            // Setting up background view first
        setupBackgroundView()
            
            // Setup scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
            
            // ScrollView constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backgroundBaseView.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
            
        // Add base view to content view
        contentView.addSubview(baseView)
        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            baseView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8),
            baseView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
            baseView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
      
        
        // Add stackview to baseView
        baseView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: 8),
            stackView.leftAnchor.constraint(equalTo: baseView.leftAnchor, constant: 8),
            stackView.rightAnchor.constraint(equalTo: baseView.rightAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: -8)
        ])
        
        // Add all views to stackView
        stackView.addArrangedSubview(classNameLabel)
        stackView.addArrangedSubview(timestampLabel)
        stackView.addArrangedSubview(classDetailsDivider)
        classDetailsDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // Add Course Details Views
        setupCourseDetailsViews()
        stackView.addArrangedSubview(courseDetailsBaseView)
        
        // Add table View
        stackView.addArrangedSubview(studentsAttendanceTableView)
        studentsAttendanceTableView.heightAnchor.constraint(equalToConstant: CGFloat(studentAttendanceList.count * 60)).isActive = true
        
        studentsAttendanceTableView.rowHeight = 60
        studentsAttendanceTableView.isScrollEnabled = false
        
        studentsAttendanceTableView.delegate = self
        studentsAttendanceTableView.dataSource = self
        studentsAttendanceTableView.separatorStyle = .none
        studentsAttendanceTableView.register(MyCustomStudentCell.self, forCellReuseIdentifier: "studentCell")
        
        baseView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
        baseView.backgroundColor = UIColor.white
    }
    
    // Setting up the background ImageView
    func setupBackgroundView() {
        view.addSubview(backgroundBaseView)
        
        NSLayoutConstraint.activate([
            backgroundBaseView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundBaseView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundBaseView.rightAnchor.constraint(equalTo: view.rightAnchor),
            backgroundBaseView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        ])
        
        backgroundBaseView.addSubview(backgroundPosterImageView)
        NSLayoutConstraint.activate([
            backgroundPosterImageView.topAnchor.constraint(equalTo: backgroundBaseView.topAnchor),
            backgroundPosterImageView.leadingAnchor.constraint(equalTo: backgroundBaseView.leadingAnchor),
            backgroundPosterImageView.trailingAnchor.constraint(equalTo: backgroundBaseView.trailingAnchor),
            backgroundPosterImageView.bottomAnchor.constraint(equalTo: backgroundBaseView.bottomAnchor)
        ])
    }
    
    // Setting up Course Details Views
    func setupCourseDetailsViews(){
                
        courseDetailsBaseView.addSubview(courseDetailsStackView)
        courseDetailsStackView.topAnchor.constraint(equalTo: courseDetailsBaseView.topAnchor, constant: 8).isActive = true
        courseDetailsStackView.bottomAnchor.constraint(equalTo: courseDetailsBaseView.bottomAnchor, constant: -8).isActive = true
        courseDetailsStackView.leftAnchor.constraint(equalTo: courseDetailsBaseView.leftAnchor, constant: 8).isActive = true
        courseDetailsStackView.rightAnchor.constraint(equalTo: courseDetailsBaseView.rightAnchor, constant: -8).isActive = true

        
        // Add all the labels
        courseDetailsStackView.addArrangedSubview(courseDetailsLabel)
        courseDetailsStackView.addArrangedSubview(courseDetailsID)
        courseDetailsStackView.addArrangedSubview(totalLecturesLabel)
        courseDetailsStackView.addArrangedSubview(presentLectureLabel)
        courseDetailsStackView.addArrangedSubview(remainingLectureLabel)
        
        
        courseDetailsStackView.addArrangedSubview(courseDetailsPlaceHolder)
        courseDetailsPlaceHolder.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        courseDetailsPlaceHolder.addSubview(courseDetailsDivider)
        
        courseDetailsDivider.centerXAnchor.constraint(equalTo: courseDetailsPlaceHolder.centerXAnchor).isActive = true
        courseDetailsDivider.centerYAnchor.constraint(equalTo: courseDetailsPlaceHolder.centerYAnchor).isActive = true
        courseDetailsDivider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        courseDetailsDivider.widthAnchor.constraint(equalTo: courseDetailsPlaceHolder.widthAnchor, multiplier: 0.9).isActive = true

        
        courseDetailsStackView.addArrangedSubview(attendanceDetailsLabel)
        arrangeCountsViews()
    }
    
    
    func arrangeCountsViews(){
        
        // base stackview
        let counterStackView : UIStackView = {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 3
            return stack
        }()
        
        
        counterStackView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        courseDetailsStackView.addArrangedSubview(counterStackView)
        
        let totalView = makeCountLabelView(forLabel: classStrengthLabel)
        counterStackView.addArrangedSubview(totalView)
        
        let presentView = makeCountLabelView(forLabel: presentTodayLabel)
        counterStackView.addArrangedSubview(presentView)

        let absentView = makeCountLabelView(forLabel: absentTodayLabel)
        counterStackView.addArrangedSubview(absentView)
        
    }
    
    
    func makeCountLabelView(forLabel : UILabel) -> UIView {
        
        let baseCountView : UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor.lightWhite
            view.layer.cornerRadius = 5
            view.layer.masksToBounds = true
            return view
        }()
        
        baseCountView.addSubview(forLabel)
        forLabel.topAnchor.constraint(equalTo: baseCountView.topAnchor).isActive = true
        forLabel.bottomAnchor.constraint(equalTo: baseCountView.bottomAnchor).isActive = true
        forLabel.leftAnchor.constraint(equalTo: baseCountView.leftAnchor).isActive = true
        forLabel.rightAnchor.constraint(equalTo: baseCountView.rightAnchor).isActive = true
        
        return baseCountView
        
    }

}
