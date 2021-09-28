//
//  ViewController.swift
//  TestCamera
//
//  Created by myonghyuplim on 2021/08/31.
//

import UIKit

class ViewController: UIViewController, QRScanViewDelegate {
    
    func scanComplete(status: QRScanStatus) {
        switch status {
        case .stop(let isButtonTop):
            print(isButtonTop)
            break
        case .success(let code) :
            print(code)
            break
        default: break
            
        }
    }
    

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var scanView: QRScanView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scanView.delegate = self
        
        self.scanView.layer.masksToBounds = true
        self.scanView.layer.cornerRadius = 15
        
        qrImageView.image = generateQRCode(from: "https://daum.net")
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !self.scanView.isRunning {
            self.scanView.stop(isButtonTap: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        print("frame : \(scanView.frame)")
        print("bounds : \(scanView.bounds)")
    }
    
    @IBAction func scanButtonAction(_ sender: UIButton) {
        if self.scanView.isRunning {
            self.scanView.stop(isButtonTap: true)
        } else {
            self.scanView.start()
        }

        sender.isSelected = self.scanView.isRunning
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else {return nil}
            
            let transformScale = CGAffineTransform(scaleX: 5.0, y: 5.0)
            let scaledQRImage = QRImage.transformed(by: transformScale)
            
            return UIImage(ciImage: scaledQRImage)
        }
        return nil
    }
}

