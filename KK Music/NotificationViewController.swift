//
//  NotificationViewController.swift
//  KK Music
//
//  Created by Nolin McFarland on 10/25/21.
//

import UIKit

class NotificationViewController: UIViewController {

    @IBOutlet weak var containerView: UIVisualEffectView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var imageName = ""
    var notification = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 12
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        imageView.image = nil
        label.text = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        label.text = notification
        imageView.image = UIImage(systemName: imageName)
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 2.5, options: .curveEaseOut) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        } completion: { complete in
            UIView.animate(withDuration: 0.1, delay: 0.25, options: .curveEaseIn) {
                self.containerView.alpha = 0
            } completion: { complete in
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
}
