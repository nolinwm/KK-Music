//
//  AnimatedButton.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/28/21.
//

import Foundation
import UIKit

class AnimatedButton: UIButton {
    
    func push() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.075, delay: 0, options: .curveEaseOut) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }
    }
    
    func pull() {
        DispatchQueue.main.async {
            self.transform = .identity
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                push()
            } else {
                pull()
            }
        }
    }
}
