//
//  RectangleOverlayView.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 11.08.2023.
//

import Foundation
import UIKit

class RectangleOverlayView: UIView {
    var rectangleCoordinates: CGRect? {
        didSet {
            setNeedsDisplay()
            updateLabelPosition()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.clear(rect)
        
        if let rectangle = rectangleCoordinates {
            context.setStrokeColor(UIColor.red.cgColor)
            context.setLineWidth(5)
            context.stroke(rectangle)
        }
    }
    
    var labelText: String? {
        didSet {
            label.text = labelText
        }
    }
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.numberOfLines = 0 // Allow label to wrap text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.bottomAnchor.constraint(equalTo: topAnchor, constant: -5), // Adjust as needed
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -10) // Adjust as needed
        ])
    }
    
    private func updateLabelPosition() {
        if let rectangle = rectangleCoordinates {
            let labelCenterX = rectangle.midX
            let labelCenterY = rectangle.minY
            
            label.center = CGPoint(x: labelCenterX, y: labelCenterY)
            label.isHidden = false // Show the label when rectangleCoordinates are set
        } else {
            label.isHidden = true // Hide the label when rectangleCoordinates are not set
            label.text = ""
        }
    }

       
}
