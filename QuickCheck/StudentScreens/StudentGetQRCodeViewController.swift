//
//  StudentGetQRCodeViewController.swift
//  QuickCheck
//
//  Created by Rumjhum Singru on 12/3/24.
//

import Foundation
import UIKit
import Firebase
import AVFoundation
import CoreLocation
import MapKit


class StudentGetQRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CLLocationManagerDelegate {

    
    var CurrentDetails : UIViewController.BasicDetails?

    var isError = false
    
    let locationManager = CLLocationManager()
    var myLongitude : Double = 0.0, myLatitude : Double = 0.0
    
    
    var videoLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    
    let qrFrameImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = #imageLiteral(resourceName: "qr_frame")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barStyle = .blackTranslucent

        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        if captureDevice == nil{
            isError = true
            self.showAlert(AlertTitle: "Camera Error", Message: "This feature needs camera to work.")
        }
        else{
            isError = false
            
        do{
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            session.addInput(input)
        }
        catch{
            
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        view.addSubview(qrFrameImageView)
        qrFrameImageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        qrFrameImageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        qrFrameImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        qrFrameImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)
            self.view.bringSubviewToFront(qrFrameImageView)
        
        session.startRunning()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.title = "QR Scanner"
        
        if !isError{
            initiateLocationServices()
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if !isError {
            session.stopRunning()
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func initiateLocationServices(){
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        if (myLongitude != locValue.longitude && myLatitude != locValue.latitude){
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            myLongitude = locValue.longitude
            myLatitude = locValue.latitude
        }
    }

    func prefilterQRCodeString(rawStringData : String){
        let invalidChars: Set<Character> = [".", "#", "$", "[", "]" ]
        let hasInvalidChars = invalidChars.isDisjoint(with: rawStringData)
        if !hasInvalidChars {
            showAlertAndResumeScanner(Title: "Invalid QR Code", Message: "Please scan a valid QR Code")
        }
        else{
            checkAndAddAttendance(AttendanceId: rawStringData)
        }
    }
    
    
    func checkAndAddAttendance(AttendanceId : String){
        let classId = (CurrentDetails?.ClassID)!
        let userId = (CurrentDetails?.UserID)!
        let ref : DatabaseReference = Database.database().reference()
        
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            
            let attendanceSnapshot : DataSnapshot = snapshot.childSnapshot(forPath: "classes").childSnapshot(forPath: classId).childSnapshot(forPath: "attendance")

            if attendanceSnapshot.hasChild(AttendanceId){
                let currentAttendanceSnapshot : DataSnapshot = attendanceSnapshot.childSnapshot(forPath: AttendanceId)
                let validityDate = currentAttendanceSnapshot.childSnapshot(forPath: "validity_till").value as? String
                
                
                if (currentAttendanceSnapshot.childSnapshot(forPath: "students_present").hasChild(userId)) {
                    self.showAlertAndResumeScanner(Title: "Attendance already marked!", Message: "You already got attendance for this class.")
                }
                
                
                else if (self.isAttendanceActive(ValidityDateString: validityDate!)) {
                    let long = currentAttendanceSnapshot.childSnapshot(forPath: "class_location").childSnapshot(forPath: "longitude").value as? String
                    let lat = currentAttendanceSnapshot.childSnapshot(forPath: "class_location").childSnapshot(forPath: "latitude").value as? String
                    let classSize = currentAttendanceSnapshot.childSnapshot(forPath: "classroom_size").value as? String
                    
                    let inRange = self.isClassroomInRange(longitude: long!, latitude: lat!, classroomSize: classSize!)
                    if inRange {
                    ref.child("classes").child(classId).child("attendance").child(AttendanceId).child("students_present").child(userId).setValue("0")
                        
                        self.showAlertAndResumeScanner(Title: "Success", Message: "Your attendance has been marked for today.")
                        
                    }
                }
            }
            
            else{
                self.showAlertAndResumeScanner(Title: "Invalid QR Code", Message: "Please scan a valid QR Code")
            }
            
        })
    }
    
    func isAttendanceActive(ValidityDateString : String) -> Bool{
        let validityDate : Date = ValidityDateString.toMyDate()
        
        var currentDate : Date = Date()
        let currentDateStr = currentDate.toString()
        
        currentDate = currentDateStr.toMyDate()
        
        print("Validity date : \(validityDate) and Current Date: \(currentDate)")
        
        if currentDate > validityDate{
            showAlertAndResumeScanner(Title: "Attendance Expired", Message: "This QR Code has expired")
        }
            
        else if currentDate <= validityDate{
            return true
        }
        return false
    }
    

    func isClassroomInRange(longitude : String, latitude : String, classroomSize : String) -> Bool{
        
        let classRange : Double = getClassroomRangeFor(classSize: classroomSize)
        let classLongitude = Double (longitude)!
        let classLatitude = Double (latitude)!
        
        let myLocation = CLLocation(latitude: myLatitude, longitude: myLongitude)
        let classLocation = CLLocation(latitude: classLatitude, longitude: classLongitude)
        
        let distance = myLocation.distance(from: classLocation)

        print("Class Range in meters : \(classRange).\nClass Location lat:\(latitude), long:\(longitude).\n Distance between student and classroom: \(distance)")
        
        if distance <= classRange{
            return true
        }
        
        else{
            self.showAlertAndResumeScanner(Title: "Not in Range Error", Message: "You are not in range of classroom. Please go closer to the class to get the attendance")
            return false
        }
    }
    
    
    func getClassroomRangeFor(classSize : String) -> Double{
        var rangeInMeters : Double = 50.00
        
        switch (classSize){
        case "Large":
            rangeInMeters = 120.00
            break
            
        case "Medium":
            rangeInMeters = 60.00
            break
            
        case "Small":
            rangeInMeters = 15.00
            break
            
        default:
            rangeInMeters = 50.00
            break
        }
        
        return rangeInMeters
    }

    func showAlertAndResumeScanner(Title : String, Message : String){
        let alert = UIAlertController(title: Title, message: Message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(nil) in
            self.session.startRunning()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.configureVideoOrientation()
    }
    
    private func configureVideoOrientation() {
        if let connection =  self.videoLayer.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        videoLayer.frame = self.view.bounds
    }
    

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0{
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject{
                if object.type == AVMetadataObject.ObjectType.qr{
                    let qrData = object.stringValue
                    session.stopRunning()
                    prefilterQRCodeString(rawStringData: qrData!)
                }
            }
        }
    }
}
