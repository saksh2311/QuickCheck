//
//  AddClassViewController.swift
//  QuickCheck
//
//  Created by Sakshi Patil on 12/1/24.
//

import UIKit
import Firebase

class AddClassViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let defaultImageURL = "https://firebasestorage.googleapis.com/v0/b/cs5520-ios-project.firebasestorage.app/o/class_logo.jpg?alt=media&token=506aafdc-e321-40f7-88b2-e219516503d2"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        self.avoidKeyboardObstruction()
        view.backgroundColor = UIColor.white
        
        self.navigationItem.title = "Create Class"

        setupViews()
    }

    
    
    
    
    
    // Action handlers
    
    @objc func handleCreateClass(){
        print("create class touched")
        checkUserInput()
    }
    
    @objc func handlePosterTap(){
        print("Poster imageview clicked")
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
        imagePicker.allowsEditing = true
        
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    
    
    
    
    
    
    // Helper methods
    
    func checkUserInput(){
        let className = classNameTextField.text
        let totalLectures = lecturesCountTextField.text
        var isError = true
        var errorMessage = "" , errorTitle = ""
        
        // Check for errors
        if (className?.isEmpty)! || (totalLectures?.isEmpty)! {
            isError = true
            errorTitle = "Input Error"
            errorMessage = "Please fill the mandatory input fields"
        }
        else{
            isError = false
        }
        
        // Handle the error
        if(isError){
            self.showAlert(AlertTitle: errorTitle, Message: errorMessage)
        }
        else{
            addClassToFirebase()
        }
    }
    
    
    // Add this new class to the database
    func addClassToFirebase() {
        let loadingScreen = UIViewController.displaySpinner(onView: self.view, Message: "Creating class")
        
        guard let tutorId = Auth.auth().currentUser?.uid else {
            UIViewController.removeSpinner(spinner: loadingScreen)
            return
        }
        
        let className = classNameTextField.text ?? ""
        let totalLectures = lecturesCountTextField.text ?? ""
        let classLocation = classLocationTextField.text ?? ""
        let classPosterImage: UIImage = posterImageView.image ?? UIImage(named: "blank_image") ?? UIImage()
        
        let defaultChildren = ["default": "default"]
        
        let ref: DatabaseReference = Database.database().reference()
        let newClassRef = ref.child("classes").childByAutoId()
        
        guard let classId = newClassRef.key else {
            UIViewController.removeSpinner(spinner: loadingScreen)
            return
        }
        
        let posterName = classId + ".jpg"
        
        // Adding values to the Firebase
        newClassRef.child("tutor_id").setValue(tutorId)
        newClassRef.child("class_name").setValue(className)
        newClassRef.child("total_lectures").setValue(totalLectures)
        newClassRef.child("class_location").setValue(classLocation)
        newClassRef.child("students").setValue(defaultChildren)
        newClassRef.child("attendance").setValue(defaultChildren)
        newClassRef.child("latest_attendance").setValue("")
        
        // Add this class to the current tutor
        ref.child("tutors").child(tutorId).child("my_classes").child(classId).setValue("0")
        let defaultImage = UIImage(named: "blank_image") ?? UIImage()
        if classPosterImage.pngData() == defaultImage.pngData() {
            print("No image uploaded")
            newClassRef.child("poster_path").setValue(defaultImageURL)
            UIViewController.removeSpinner(spinner: loadingScreen)
            self.navigationController?.popViewController(animated: true)
        }else {
            // Now upload the profile image
            let storageRef = Storage.storage().reference().child("class_posters").child(posterName)
            
            if let uploadImage = classPosterImage.jpegData(compressionQuality: 0.1) {
                storageRef.putData(uploadImage, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print(error)
                        UIViewController.removeSpinner(spinner: loadingScreen)
                        return
                    }
                    
                    // Get download URL using the new method
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            print(error)
                            UIViewController.removeSpinner(spinner: loadingScreen)
                            return
                        }
                        
                        if let imageURL = url?.absoluteString {
                            newClassRef.child("poster_path").setValue(imageURL)
                            UIViewController.removeSpinner(spinner: loadingScreen)
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    // Image Picker methods
    // On Cancelling the image upload
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image upload cancelled")
        dismiss(animated: true, completion: nil)
    }
    // Image picker functions
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("Got the image")
        dismiss(animated: true, completion: nil)
        
        var selectedImageFromPicker : UIImage?
        
        // Check if image is edited
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            print("Got edited image")
            selectedImageFromPicker = editedImage
        }
            
            // If not take the original image
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            print("Got original image")
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            posterImageView.image = selectedImage
        }
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // My Views
    
    // ScrollView
    let scrollView : UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Base Stack View
    let stackView : UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .vertical
        v.spacing = 8
        return v
    }()
    
    
    // class poster base view
    var posterBaseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    
    // class poster imageview
    lazy var posterImageView : UIImageView = {
        let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handlePosterTap))
            imageView.addGestureRecognizer(tap)
            imageView.isUserInteractionEnabled = true
            
            // Use the default image URL instead
            if let defaultImageURL = URL(string: defaultImageURL) {
                URLSession.shared.dataTask(with: defaultImageURL) { (data, response, error) in
                    if let imageData = data {
                        DispatchQueue.main.async {
                            imageView.image = UIImage(data: imageData)
                        }
                    }
                }.resume()
            }
            
            return imageView
    }()
    
    //textFields and their views
    // Class Name textfield
    
    // baseView for text fields
    var classNameView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
        let classNameStackView : UIStackView = {
            let v = UIStackView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.axis = .vertical
            v.spacing = 2
            return v
        }()
    
        // Review Content label
        let classNameLabel : UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Class Name: *"
            label.font = UIFont.boldSystemFont(ofSize: 10)
            return label
        }()
    
        var classNameTextField : UITextField = {
            let text = UITextField()
            text.translatesAutoresizingMaskIntoConstraints = false
            text.adjustsFontSizeToFitWidth = true
            return text
        }()
    
    
    
    // baseView for text fields
    var lecturesCountView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
        let lecturesCountStackView : UIStackView = {
            let v = UIStackView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.axis = .vertical
            v.spacing = 2
            return v
        }()
    
        // Lecture Count label
        let lecturesCountLabel : UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Lectures Count: *"
            label.font = UIFont.boldSystemFont(ofSize: 10)
            return label
        }()
    
        // Number of lectures textfield
        var lecturesCountTextField : UITextField = {
            let text = UITextField()
            text.translatesAutoresizingMaskIntoConstraints = false
            text.adjustsFontSizeToFitWidth = true
            text.keyboardType = .numberPad
            return text
        }()
    
    
    // baseView for text fields
    var classLocationView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
        let classLocationStackView : UIStackView = {
            let v = UIStackView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.axis = .vertical
            v.spacing = 2
            return v
        }()
    
        // Class Location label
        let classLocationLabel : UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Class Location:"
            label.font = UIFont.boldSystemFont(ofSize: 10)
            return label
        }()
    
        // Classroom location textfield
        var classLocationTextField : UITextField = {
            let text = UITextField()
            text.translatesAutoresizingMaskIntoConstraints = false
            text.adjustsFontSizeToFitWidth = true
            return text
        }()
    
    // Create class button
    var createClassButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Create Class", for: .normal)
        button.addTarget(self, action: #selector(handleCreateClass), for: .touchUpInside)
        
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.green.cgColor
        button.setTitleColor(UIColor.green, for: .normal)
        
        return button
    }()
    
    
    
    
    func setupViews(){
        
        // Add the scroll view
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        // Setting base stackview
        scrollView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true
        stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        
        // Adding other views to stackview
        stackView.addArrangedSubview(posterBaseView)
        posterBaseView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor).isActive = true
        posterBaseView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
        posterBaseView.addSubview(posterImageView)
        posterImageView.centerXAnchor.constraint(equalTo: posterBaseView.centerXAnchor).isActive = true
        posterImageView.centerYAnchor.constraint(equalTo: posterBaseView.centerYAnchor).isActive = true
        posterImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45).isActive = true
        posterImageView.widthAnchor.constraint(equalTo: posterImageView.heightAnchor, multiplier: 2.0).isActive = true
        
        
        // Add classname textfield
        stackView.addArrangedSubview(classNameView)

        makeTextFieldViewWith(baseView: classNameView, stackView: classNameStackView, label: classNameLabel, textField: classNameTextField)

        stackView.addArrangedSubview(lecturesCountView)
        makeTextFieldViewWith(baseView: lecturesCountView, stackView: lecturesCountStackView, label: lecturesCountLabel, textField: lecturesCountTextField)
        
        stackView.addArrangedSubview(classLocationView)
        makeTextFieldViewWith(baseView: classLocationView, stackView: classLocationStackView, label: classLocationLabel, textField: classLocationTextField)

        let createClassButtonView = createClassButton.getStyledButtonView()
        stackView.addArrangedSubview(createClassButtonView)
        
        // Adding a blank space
        let blankSpace = UIView().makeBlankSpace()
        stackView.addArrangedSubview(blankSpace)
        blankSpace.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5, constant: -200).isActive = true
        
        
    }
    
    // Takes required views and
    func makeTextFieldViewWith(baseView : UIView, stackView : UIStackView, label: UILabel, textField : UITextField){
        
        // Setting up baseview
        baseView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        baseView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
        
        // adding up stackView
        baseView.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: baseView.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: baseView.centerYAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: baseView.leftAnchor, constant: 8).isActive = true
        stackView.rightAnchor.constraint(equalTo: baseView.rightAnchor, constant: -8).isActive = true
        stackView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: 4).isActive = true
        stackView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: -4).isActive = true
        
        // Adding stack subviews
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textField)
        
    }
}
