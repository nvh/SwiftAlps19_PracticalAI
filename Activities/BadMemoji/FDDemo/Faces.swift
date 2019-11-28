//
//  Faces.swift
//  FDDemo
//
//  Created by Mars Geldard on 20/6/19.
//  Copyright © 2019 Mars Geldard. All rights reserved.
//

import UIKit
import Vision

extension UIImage {
    // Give UIImage some way to detect faces within it
    func detectFaces(completion: @escaping ([VNFaceObservation]?) -> ()) {
        guard let image = self.cgImage else { return completion(nil) }
        let request = VNDetectFaceLandmarksRequest()
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(cgImage: image, orientation: self.cgImageOrientation)
            try? handler.perform([request])
            guard let observations = request.results as? [VNFaceObservation] else {return completion([])}
            completion(observations)
        }
    }
}


// Once landmarked, draw emoji on face detections
extension Collection where Element == VNFaceObservation {
    func drawOn(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        guard let _ = UIGraphicsGetCurrentContext() else { return nil }
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let imageSize: (width: Int, height: Int) = (Int(image.size.width), Int(image.size.height))
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -image.size.height)
        let padding: CGFloat = 0.3
        for observation in self {
            guard let anchor = observation.landmarks?.anchorPointInImage(image) else {
                continue
            }
            guard let center = anchor.center?.applying(transform) else {
                continue
            }
            let overlayRect = VNImageRectForNormalizedRect(observation.boundingBox, imageSize.width, imageSize.height).applying(transform).centeredOn(center)
            let insets = (
                x: overlayRect.size.width * padding,
                y: overlayRect.size.height * padding)
                
            let paddedOverlayRect = overlayRect.insetBy(dx: -insets.x, dy: -insets.y)
            let randomEmoji = ["💩","😁", "🧐", "🥰", "😸", "😆", "🙁", "😕", "😢", "🤠"].randomElement()!
            if var overlayImage = randomEmoji.image(of: paddedOverlayRect.size) {
                if let angle = anchor.angle, let rotatedImages = overlayImage.rotatedBy(degrees: angle) {
                    overlayImage = rotatedImages
                }
                overlayImage.draw(in: paddedOverlayRect)
            }
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}



// Once detected, get landmarks from face as anchor points
extension VNFaceLandmarks2D {
    func anchorPointInImage(_ image: UIImage) -> (center: CGPoint?, angle: CGFloat?) {
        // centre each set of points that may have been detected,
        // if present
        let allPoints = self.allPoints?.pointsInImage(imageSize: image.size).centerPoint
        let leftPupil = self.leftPupil?.pointsInImage(imageSize: image.size).centerPoint
        let leftEye = self.leftEye?.pointsInImage(imageSize: image.size).centerPoint
        let leftEyebrow = self.leftEyebrow?.pointsInImage(imageSize: image.size).centerPoint
        let rightPupil = self.rightPupil?.pointsInImage(imageSize: image.size).centerPoint
        let rightEye = self.rightEye?.pointsInImage(imageSize: image.size).centerPoint
        let rightEyebrow = self.rightEyebrow?.pointsInImage(imageSize: image.size).centerPoint
        let outerLips = self.outerLips?.pointsInImage(imageSize: image.size).centerPoint
        let innerLips = self.innerLips?.pointsInImage(imageSize: image.size).centerPoint
        let leftEyeCenter = leftPupil ?? leftEye ?? leftEyebrow
        let rightEyeCenter = rightPupil ?? rightEye ?? rightEyebrow
        let mouthCenter = innerLips ?? outerLips
        if let leftEyePoint = leftEyeCenter,
            let rightEyePoint = rightEyeCenter,
            let mouthPoint = mouthCenter {
            let triadCenter = [leftEyePoint, rightEyePoint, mouthPoint].centerPoint
            let eyesCenter = [leftEyePoint, rightEyePoint].centerPoint
             return (eyesCenter, triadCenter.rotationDegreesTo(eyesCenter))
        }
        // else fallback
        return (allPoints, 0.0)
    }
}
