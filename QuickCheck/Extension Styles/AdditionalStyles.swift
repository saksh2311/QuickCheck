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
    
    // Creates a blank spacer view with adjustable height
    func makeBlankSpace(height: CGFloat = 16) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
    
    
    // Fade animation
    func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
