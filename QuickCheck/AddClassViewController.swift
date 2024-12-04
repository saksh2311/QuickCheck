//
//  AddClassViewController.swift
//  QuickCheck
//
//  Created by Sakshi Patil on 12/1/24.
//

import UIKit
import Firebase

class AddClassViewController: UIViewController {
    private let scrollView: UIScrollView = {
            let view = UIScrollView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor.white
            self.navigationItem.title = "Create Class"
            setupViews()
            setupKeyboardHandling()
        }
    private func setupKeyboardHandling() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tap)
            
            // Set keyboard dismiss mode
            scrollView.keyboardDismissMode = .onDrag
        }
        
    @objc internal override func dismissKeyboard() {
            view.endEditing(true)
        }
    
    // Action handlers
    @objc func handleCreateClass() {
        checkUserInput()
    }
    
    // Helper methods
    func checkUserInput() {
        let className = classNameTextField.text
        let totalLectures = lecturesCountTextField.text
        var isError = true
        var errorMessage = "", errorTitle = ""
        
        if (className?.isEmpty)! || (totalLectures?.isEmpty)! {
            isError = true
            errorTitle = "Input Error"
            errorMessage = "Please fill the mandatory input fields"
        } else {
            isError = false
        }
        
        if(isError) {
            self.showAlert(AlertTitle: errorTitle, Message: errorMessage)
        } else {
            addClassToFirebase()
        }
    }
    
    // Add class to Firebase
    func addClassToFirebase() {
        let loadingScreen = UIViewController.displaySpinner(onView: self.view, Message: "Creating class")
        guard let tutorId = Auth.auth().currentUser?.uid else {
            UIViewController.removeSpinner(spinner: loadingScreen)
            return
        }
        
        let className = classNameTextField.text ?? ""
        let totalLectures = lecturesCountTextField.text ?? ""
        let classLocation = classLocationTextField.text ?? ""
        let defaultChildren = ["default": "default"]
        
        let ref: DatabaseReference = Database.database().reference()
        let newClassRef = ref.child("classes").childByAutoId()
        guard let classId = newClassRef.key else {
            UIViewController.removeSpinner(spinner: loadingScreen)
            return
        }
        
        // Adding values to Firebase
        newClassRef.child("tutor_id").setValue(tutorId)
        newClassRef.child("class_name").setValue(className)
        newClassRef.child("total_lectures").setValue(totalLectures)
        newClassRef.child("class_location").setValue(classLocation)
        newClassRef.child("students").setValue(defaultChildren)
        newClassRef.child("attendance").setValue(defaultChildren)
        newClassRef.child("latest_attendance").setValue("")
        
        // Add class to current tutor
        ref.child("tutors").child(tutorId).child("my_classes").child(classId).setValue("0")
        
        UIViewController.removeSpinner(spinner: loadingScreen)
        self.navigationController?.popViewController(animated: true)
    }
    
    // UI Components
    let stackView: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .vertical
        v.spacing = 8
        return v
    }()
    
    // Class Name Components
    var classNameTextField: UITextField = {
        let text = UITextField()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.placeholder = "Enter class name"
        text.borderStyle = .roundedRect
        return text
    }()
    
    // Lectures Count Components
    var lecturesCountTextField: UITextField = {
        let text = UITextField()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.placeholder = "Enter number of lectures"
        text.keyboardType = .numberPad
        text.borderStyle = .roundedRect
        return text
    }()
    
    // Class Location Components
    var classLocationTextField: UITextField = {
        let text = UITextField()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.placeholder = "Enter class location"
        text.borderStyle = .roundedRect
        return text
    }()
    
    // Create Class Button
    var createClassButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Create Class", for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(handleCreateClass), for: .touchUpInside)
        return button
    }()
    
    func setupViews() {
            // Add scrollView to main view
            view.addSubview(scrollView)
            
            // Setup scrollView constraints
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            // Add stackView to scrollView
            scrollView.addSubview(stackView)
            
            // Setup stackView constraints
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
            ])
            
            // Add your existing views to stackView
            stackView.addArrangedSubview(classNameTextField)
            stackView.addArrangedSubview(lecturesCountTextField)
            stackView.addArrangedSubview(classLocationTextField)
            stackView.addArrangedSubview(createClassButton)
        }
}
