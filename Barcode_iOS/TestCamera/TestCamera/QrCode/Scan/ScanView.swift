//
//  ScanView.swift
//  아래 커스텀뷰에서 자신의 전체영역을 QRCode를 인식하는 화면으로 설정되어있음
//  사용방법
//  UIViewController에서 아래 QRScanView를 생성하고
//  QRScanViewDelegate로 콜백값을 받아 처리
//
//
//  Created by myonghyuplim on 2021/08/31.
//

import Foundation

import AVKit
import AVFoundation

class QRScanView : UIView {
    
    // 스캔 상태를 넘겨주기 위한 델리게이트
    weak var delegate: QRScanViewDelegate?
    
    // 카메라 프리뷰를 보여질 뷰의 프리뷰 레이어
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 프리뷰를 통한 비디오 이미지의 캡쳐 세션
    var captureSession: AVCaptureSession?

    private var cornerLength: CGFloat = 20
    private var cornerLineWidth: CGFloat = 6
    private var rectOfInterest: CGRect {
        CGRect(x: 0,
               y: 0,
                          width: frame.width, height: frame.height)
    }
    
    // 실행중 체크
    var isRunning: Bool {
        guard let captureSession = self.captureSession else {
            return false
        }
        return captureSession.isRunning
    }
    
    // 캡쳐 세션을 통한 프리뷰로 부터 어떤 메터정보를 검색할건지 메타정보 타입 설정
    let metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initSetup()
    }
    
    private func initSetup() {
        // 뷰전체에 바운딩
        self.clipsToBounds = true
        
        // 캡쳐 세션 생성
        self.captureSession = AVCaptureSession()
        
        // 비디오 디바이스로 캡쳐 세션 생성
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        // 캡쳐 입력 선언
        let videoInput: AVCaptureInput
        
        do {
            // 비디오 캡쳐 디바이스 입력을 캡쳐 인풋으로 생성
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch let error {
            print(error.localizedDescription)
            return
        }
            
        // 캡쳐 세션 생성에 성공한 경우 체크
        guard let captureSession = self.captureSession else { self.fail(); return }
        
        // 캡쳐 세선으로 입력받을 비디오 입력을 추가 가능한 경우 추가
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            self.fail()
            return
        }
                
        // 캡쳐 세션의 메타정보를 아웃풋으로 주는 인스턴스 생성
        let metadataOutput = AVCaptureMetadataOutput()
                
        // 캡쳐 세션에 아웃풋 메타정보 추가하여 실제 스캔 정보는 이메타정보를 통해서 취득
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
                    
            // 메터정보를 받을 콜백 설정(메인쓰레드에서 처리)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = self.metadataObjectTypes
            
        } else {
            self.fail()
            return
        }
                
        self.setPreviewLayer()
        self.setFocusZoneCornerLayer()
        /*
         // QRCode 인식 범위 설정하기
         metadataOutput.rectOfInterest 는 AVCaptureSession에서 CGRect 크기만큼 인식 구역으로 지정합니다.
         !! 단 해당 값은 먼저 AVCaptureSession를 running 상태로 만든 후 지정해주어야 정상적으로 작동합니다 !!
         */
        self.start()
        print(rectOfInterest)
        metadataOutput.rectOfInterest = previewLayer!.metadataOutputRectConverted(fromLayerRect: rectOfInterest)
    }
    
    /// 중앙에 사각형의 Focus Zone Layer을 설정합니다.
    private func setPreviewLayer() {
        let readingRect = rectOfInterest
        
        guard let captureSession = self.captureSession else {
            return
        }
        
        /*
         AVCaptureVideoPreviewLayer를 구성.
         */
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = self.layer.bounds

        // MARK: - Scan Focus Mask
        /*
         Scan 할 사각형(Focus Zone)을 구성하고 해당 자리만 dimmed 처리를 하지 않음.
         */
        /*
         CAShapeLayer에서 어떠한 모양(다각형, 폴리곤 등의 도형)을 그리고자 할 때 CGPath를 사용한다.
         즉 previewLayer에다가 ShapeLayer를 그리는데
         ShapeLayer의 모양이 [1. bounds 크기의 사각형, 2. readingRect 크기의 사각형]
         두개가 그려져 있는 것이다.
         */
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addRect(readingRect)

        /*
         그럼 Path(경로? 모양?)은 그렸으니 Layer의 특징을 정하고 추가해보자.
         먼저 CAShapeLayer의 path를 위에 지정한 path로 설정해주고,
         QRReader에서 백그라운드 색이 dimmed 처리가 되어야 하므로 layer의 투명도를 0.6 정도로 설정한다.
         단 여기서 QRCode를 읽을 부분은 dimmed 처리가 되어 있으면 안 된다.
         이럴때 fillRule에서 evenOdd를 지정해주는데
         Path(도형)이 겹치는 부분(여기서는 readingRect, QRCode 읽는 부분)은 fillColor의 영향을 받지 않는다
         */
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        maskLayer.fillRule = .evenOdd

        previewLayer.addSublayer(maskLayer)
        
        
        self.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
    
    private func setFocusZoneCornerLayer() {
            var cornerRadius = previewLayer?.cornerRadius ?? CALayer().cornerRadius
            if cornerRadius > cornerLength { cornerRadius = cornerLength }
            if cornerLength > rectOfInterest.width / 2 { cornerLength = rectOfInterest.width / 2 }

            // Focus Zone의 각 모서리 point
            let upperLeftPoint = CGPoint(x: rectOfInterest.minX - cornerLineWidth / 2, y: rectOfInterest.minY - cornerLineWidth / 2)
            let upperRightPoint = CGPoint(x: rectOfInterest.maxX + cornerLineWidth / 2, y: rectOfInterest.minY - cornerLineWidth / 2)
            let lowerRightPoint = CGPoint(x: rectOfInterest.maxX + cornerLineWidth / 2, y: rectOfInterest.maxY + cornerLineWidth / 2)
            let lowerLeftPoint = CGPoint(x: rectOfInterest.minX - cornerLineWidth / 2, y: rectOfInterest.maxY + cornerLineWidth / 2)
            
            // 각 모서리를 중심으로 한 Edge를 그림.
            let upperLeftCorner = UIBezierPath()
            upperLeftCorner.move(to: upperLeftPoint.offsetBy(dx: 0, dy: cornerLength))
            upperLeftCorner.addArc(withCenter: upperLeftPoint.offsetBy(dx: cornerRadius, dy: cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
            upperLeftCorner.addLine(to: upperLeftPoint.offsetBy(dx: cornerLength, dy: 0))

            let upperRightCorner = UIBezierPath()
            upperRightCorner.move(to: upperRightPoint.offsetBy(dx: -cornerLength, dy: 0))
            upperRightCorner.addArc(withCenter: upperRightPoint.offsetBy(dx: -cornerRadius, dy: cornerRadius),
                                  radius: cornerRadius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
            upperRightCorner.addLine(to: upperRightPoint.offsetBy(dx: 0, dy: cornerLength))

            let lowerRightCorner = UIBezierPath()
            lowerRightCorner.move(to: lowerRightPoint.offsetBy(dx: 0, dy: -cornerLength))
            lowerRightCorner.addArc(withCenter: lowerRightPoint.offsetBy(dx: -cornerRadius, dy: -cornerRadius),
                                     radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
            lowerRightCorner.addLine(to: lowerRightPoint.offsetBy(dx: -cornerLength, dy: 0))

            let bottomLeftCorner = UIBezierPath()
            bottomLeftCorner.move(to: lowerLeftPoint.offsetBy(dx: cornerLength, dy: 0))
            bottomLeftCorner.addArc(withCenter: lowerLeftPoint.offsetBy(dx: cornerRadius, dy: -cornerRadius),
                                    radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
            bottomLeftCorner.addLine(to: lowerLeftPoint.offsetBy(dx: 0, dy: -cornerLength))
            
            // 그려진 UIBezierPath를 묶어서 CAShapeLayer에 path를 추가 후 화면에 추가
            let combinedPath = CGMutablePath()
            combinedPath.addPath(upperLeftCorner.cgPath)
            combinedPath.addPath(upperRightCorner.cgPath)
            combinedPath.addPath(lowerRightCorner.cgPath)
            combinedPath.addPath(bottomLeftCorner.cgPath)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = combinedPath
            shapeLayer.strokeColor = UIColor.white.cgColor
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = cornerLineWidth
            shapeLayer.lineCap = .square

            self.previewLayer!.addSublayer(shapeLayer)
        }
}

enum QRScanStatus {
    case success(_ code: String?)
    case fail
    case stop(_ isButtonTap: Bool)
}

protocol QRScanViewDelegate: class {
    func scanComplete(status: QRScanStatus)
}

// MARK: - ReaderView Running Method
extension QRScanView {
    func start() {
        print("# AVCaptureSession Start Running")
        self.captureSession?.startRunning()
    }
    
    func stop(isButtonTap: Bool) {
        self.captureSession?.stopRunning()
        
        self.delegate?.scanComplete(status: .stop(isButtonTap))
    }
    
    func fail() {
        self.delegate?.scanComplete(status: .fail)
        self.captureSession = nil
    }
    
    func found(code: String) {
        self.delegate?.scanComplete(status: .success(code))
    }
}

// MARK: - AVCapture Output
extension QRScanView : AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        print("# GET metadataOutput")
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue else {
                return
            }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
            print("## Found metadata Value\n + \(stringValue)\n")
            stop(isButtonTap: true)
        }
    }
}

internal extension CGPoint {

    // MARK: - CGPoint+offsetBy
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        var point = self
        point.x += dx
        point.y += dy
        return point
    }
}
