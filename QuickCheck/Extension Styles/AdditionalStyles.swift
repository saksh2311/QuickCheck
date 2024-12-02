//
//  AdditionalStyles.swift
//  QuickCheck
//
//  Created by Sakshi Patil on 12/1/24.
//
import Foundation
import UIKit

extension UIButton {
    func getStyledButtonView(cornerRadius: CGFloat = 8, borderColor: UIColor = .clear, borderWidth: CGFloat = 0, shadowColor: UIColor = .black, shadowOpacity: Float = 0.2, shadowRadius: CGFloat = 4, shadowOffset: CGSize = .zero) -> UIView {
        
        // Create the base view
        let buttonBaseView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            // Add shadow properties
            view.layer.shadowColor = shadowColor.cgColor
            view.layer.shadowOpacity = shadowOpacity
            view.layer.shadowRadius = shadowRadius
            view.layer.shadowOffset = shadowOffset
            return view
        }()
        
        // Style the button
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        self.clipsToBounds = true
        
        // Add button to the base view
        buttonBaseView.addSubview(self)
        
        // Constraints for base view
        buttonBaseView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Constraints for button
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 48).isActive = true
        self.widthAnchor.constraint(equalTo: buttonBaseView.widthAnchor, multiplier: 0.6).isActive = true
        self.centerXAnchor.constraint(equalTo: buttonBaseView.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: buttonBaseView.centerYAnchor).isActive = true
        
        return buttonBaseView
    }
}

extension UIView {
    
    func makeBlankSpace() -> UIView {
        
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }
    
    
    // Fade animation
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
                                                            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: "fade")
    }
}

extension String {
    // Get the string before a character
    func getStringBeforeCharacter(lastCharacter : String) -> String {
        var result = ""
        let OriginalString = self
        if let range = OriginalString.range(of: lastCharacter) {
            result =  String(OriginalString[(OriginalString.startIndex)..<range.lowerBound])
        }
        return result
    }
}

extension String
{
    func toMyDate() -> Date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MMM/dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return dateFormatter.date(from: self)!
    }
    
    
    func toMyDateString() -> String
    {
        
        let day = self.toMyDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: day)
    }
    
    
    // Check for invalid character in the QRCode
    func hasInvalidCharacters() -> Bool{
        let invalidChars: Set<Character> = [".", "#", "$", "[", "]" ]
        let hasInvalidChars = invalidChars.isDisjoint(with: self)
        if !hasInvalidChars {
            // Has invalid characters
            return true
        }
        else{
            return false
        }
    }
    
}

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MMM/dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
