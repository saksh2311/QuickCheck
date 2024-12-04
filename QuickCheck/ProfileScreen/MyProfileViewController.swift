//
//  MyProfileViewController.swift
//  QuickCheck
//
//  Created by Vanshita Tilwani on 12/2/24.
//


import UIKit
import Firebase

class MyProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    
    var imagePicker = UIImagePickerController()
    var CurrentDetails : UIViewController.BasicDetails?

    var userType = "", currentUserId = ""
    var UserName, PhoneNumber, SchoolName, AboutMe, ProfilePath : String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.navigationItem.searchController?.isActive = false
        
        self.navigationController?.navigationBar.barStyle = .blackTranslucent
        
        self.hideKeyboardWhenTappedAround()
        self.avoidKeyboardObstruction()
        
        userType = (CurrentDetails?.UserType!)!
        currentUserId = (CurrentDetails?.UserID!)!
        
        setupViews()
        fetchDataFromDB()
    }
    
    let idLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "ID"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Name"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()

    let schoolLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "School"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()

    let phoneLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Phone Number"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()

    let aboutLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "About Me"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.title = "My Profile"
        self.tabBarController?.navigationItem.rightBarButtonItem = nil
        self.tabBarController?.navigationItem.searchController = nil
    }
    
    @objc func handleSave(){
        print("Save pressed")
        if(usernameText.text?.isEmpty)!{
            let alert = UIAlertController(title: "Unable to save", message: "User's name cannot be empty.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else{
            saveDetailsToDB()
        }
    }
    
    
    @objc func handleLogout(){
        // Logging out the user
        // Show the alert with a confirmation action for logging out
        self.showLogoutAlert(AlertTitle: "Log Out", Message: "Are you sure you want to log out?", confirmAction: {
            // Remove the user token and synchronize UserDefaults
            UserDefaults.standard.removeObject(forKey: "userToken")
            UserDefaults.standard.synchronize()

            // Sign out the user from Firebase
            do {
                try Auth.auth().signOut()
            } catch let error {
                print("Error signing out: \(error.localizedDescription)")
            }

            // Reset the root view controller to the login screen
            let loginPage = ViewController()
            let navigationController = UINavigationController(rootViewController: loginPage)
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
            }
        })
    }
    
    
    @objc func handleProfileTapped(){
        print("Profile image clicked")
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
        imagePicker.allowsEditing = true
        
        self.present(imagePicker, animated: true, completion: nil)
        
        
    }
    
    // Gets the data of current user from the Firebase
    func fetchDataFromDB() {
        let ref : DatabaseReference = Database.database().reference()
        ref.child(userType).child(currentUserId).observeSingleEvent(of: .value, with: {(snapshot) in
            let value = snapshot.value as? NSDictionary
            self.UserName = value?["user_name"] as? String ?? ""
            self.PhoneNumber = value?["phone_no"] as? String ?? ""
            self.SchoolName = value?["school_name"] as? String ?? ""
            self.AboutMe = value?["about_me"] as? String ?? ""
            self.ProfilePath = value?["picture_path"] as? String ?? ""
            self.studentIdText.text = self.currentUserId  // Set the student ID
            self.setDataIntoViews()
        })
    }

    
    
    // Sets the data into the Views
    func setDataIntoViews(){
        
        // Set data only if available
        if(UserName != ""){
            usernameText.text = UserName
        }
        if(PhoneNumber != ""){
            phoneNumberText.text = PhoneNumber
        }
        if(SchoolName != ""){
            schoolNameText.text = SchoolName
        }
        if(AboutMe != ""){
            aboutMeText.text = AboutMe
        }
        
        if(ProfilePath != "" && ProfilePath != "No_image"){
            self.downloadImageIntoView(imagePath: ProfilePath!, imageView: profileImageView)
        }
    }
    
    // Save data to the database
    func saveDetailsToDB() {
        let loadingScreen = UIViewController.displaySpinner(onView: self.view, Message: "Saving Profile")
        
        let ref: DatabaseReference = Database.database().reference().child(userType).child(currentUserId)
        let newUserName = usernameText.text ?? ""
        let newPhoneNumber = phoneNumberText.text ?? ""
        let newSchoolName = schoolNameText.text ?? ""
        let newAboutMe = aboutMeText.text ?? ""
        let profileImageName = currentUserId + ".jpg"
        
        // Upload to database only if values changed
        if newUserName != UserName {
            ref.child("user_name").setValue(newUserName)
        }
        if newPhoneNumber != PhoneNumber {
            ref.child("phone_no").setValue(newPhoneNumber)
        }
        if newSchoolName != SchoolName {
            ref.child("school_name").setValue(newSchoolName)
        }
        if newAboutMe != AboutMe {
            ref.child("about_me").setValue(newAboutMe)
        }
        
        // Check if new image is uploaded
        if profileImageView.image != UIImage(named: "blank_profile") && profileImageView.image != UIImage(systemName: "person.circle.fill") {
            let storageRef = Storage.storage().reference().child("profile_images").child(profileImageName)
            
            if let uploadImage = profileImageView.image?.jpegData(compressionQuality: 0.5) {
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                
                storageRef.putData(uploadImage, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading image: \(error.localizedDescription)")
                        UIViewController.removeSpinner(spinner: loadingScreen)
                        return
                    }
                    
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            UIViewController.removeSpinner(spinner: loadingScreen)
                            return
                        }
                        
                        if let imageURL = url?.absoluteString {
                            ref.child("picture_path").setValue(imageURL) { (error, _) in
                                UIViewController.removeSpinner(spinner: loadingScreen)
                                if let error = error {
                                    print("Error saving image URL: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        } else {
            ref.child("picture_path").setValue("No_image")
            UIViewController.removeSpinner(spinner: loadingScreen)
        }
    }
    
    // On Cancelling the image upload
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image upload cancelled")
        dismiss(animated: true, completion: nil)
    }
    // Image picker functions
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
    }
    
    //Base Scroll View
    let scrollView : UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        return view
    }()
    
    // StackView
    let stackView : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    
    
    // Profile ImageView holder
    let profileImageViewHolder : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    
    
    // Profile ImageVIew
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "blank_profile") ?? UIImage(systemName: "person.circle.fill")
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileTapped))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    // Blank view for spacing
    let blankSpaceOne : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    // baseview for all textFields
    let textFieldsBaseView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        
        return view
    }()
    
    // textFields base stackView
    let textFieldStackView : UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()
    
    
    // User name textfield and divider
    var usernameText : UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "Name"
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    let usernameDivider : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Student ID text field and divider
    var studentIdText : UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "Student ID"
        view.isEnabled = false  // Make it read-only
        view.textColor = .gray  // Visual indication that it's non-editable
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    let studentIdDivider : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    // Company name text field and divider
    var schoolNameText : UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "School Name"
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    let schoolNameDivider : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Phone number text field and divider
    var phoneNumberText : UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "Phone Number"
        view.keyboardType = .numberPad
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    let phoneNumberDivider : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    
    // About me text view
    var aboutMeText : UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "About me"
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    
    // Blank view for spacing
    let blankSpaceTwo : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Login button
    let saveButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.green.cgColor
        button.setTitleColor(UIColor.green, for: .normal)
        
        return button
    }()
    

    
    // Login button
    let logoutButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Logout", for: UIControl.State.normal)
        button.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.red.cgColor
        button.setTitleColor(UIColor.red, for: .normal)
        
        return button
    }()
    
    
    
    func setupViews(){
        // Base ScrollView
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        // Adding StackView to the scrollView
        scrollView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true
        stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9).isActive = true
        
        // Adding other views to stackView
        stackView.addArrangedSubview(profileImageViewHolder)
        profileImageViewHolder.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45).isActive = true
        
        profileImageViewHolder.addSubview(profileImageView)
        profileImageView.centerYAnchor.constraint(equalTo: profileImageViewHolder.centerYAnchor).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: profileImageViewHolder.centerXAnchor).isActive = true
        profileImageView.heightAnchor.constraint(equalTo: profileImageViewHolder.heightAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true

        
        stackView.addArrangedSubview(blankSpaceOne)
        blankSpaceOne.heightAnchor.constraint(equalToConstant: 20).isActive = true
        

        // Adding all textFields into the StackView
        arrangeTextFields()
        

        stackView.addArrangedSubview(blankSpaceTwo)
        blankSpaceTwo.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        // Adding the save button
        let saveButtonView = saveButton.getStyledButtonView()
        stackView.addArrangedSubview(saveButtonView)
        
        let logoutButtonView = logoutButton.getStyledButtonView()
        stackView.addArrangedSubview(logoutButtonView)
        
    }
    
    
    func arrangeTextFields() {
        stackView.addArrangedSubview(textFieldsBaseView)
        textFieldsBaseView.addSubview(textFieldStackView)
        
        // Setup constraints for textFieldStackView
        NSLayoutConstraint.activate([
            textFieldStackView.topAnchor.constraint(equalTo: textFieldsBaseView.topAnchor, constant: 8),
            textFieldStackView.bottomAnchor.constraint(equalTo: textFieldsBaseView.bottomAnchor, constant: -8),
            textFieldStackView.leftAnchor.constraint(equalTo: textFieldsBaseView.leftAnchor, constant: 8),
            textFieldStackView.rightAnchor.constraint(equalTo: textFieldsBaseView.rightAnchor, constant: -8)
        ])
        let idContainer = createFieldContainer(label: idLabel, field: studentIdText, divider: studentIdDivider)
        textFieldStackView.addArrangedSubview(idContainer)
        
        // Name field with label
        let nameContainer = createFieldContainer(label: nameLabel, field: usernameText, divider: usernameDivider)
        textFieldStackView.addArrangedSubview(nameContainer)
        
        // School field with label
        let schoolContainer = createFieldContainer(label: schoolLabel, field: schoolNameText, divider: schoolNameDivider)
        textFieldStackView.addArrangedSubview(schoolContainer)
        
        // Phone field with label
        let phoneContainer = createFieldContainer(label: phoneLabel, field: phoneNumberText, divider: phoneNumberDivider)
        textFieldStackView.addArrangedSubview(phoneContainer)
        
        // About field with label
        let aboutContainer = createFieldContainer(label: aboutLabel, field: aboutMeText, divider: nil)
        textFieldStackView.addArrangedSubview(aboutContainer)
    }

    // Helper function to create consistent field containers
    private func createFieldContainer(label: UILabel, field: UITextField, divider: UIView?) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        container.addSubview(field)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.leftAnchor.constraint(equalTo: container.leftAnchor),
            
            field.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            field.leftAnchor.constraint(equalTo: container.leftAnchor),
            field.rightAnchor.constraint(equalTo: container.rightAnchor)
        ])
        
        if let divider = divider {
            container.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                divider.leftAnchor.constraint(equalTo: container.leftAnchor),
                divider.rightAnchor.constraint(equalTo: container.rightAnchor),
                divider.heightAnchor.constraint(equalToConstant: 1),
                divider.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
            ])
        } else {
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8).isActive = true
        }
        
        return container
    }

    
}
