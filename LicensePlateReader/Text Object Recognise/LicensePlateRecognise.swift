//
//  LicensePlateRecognise.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 12.08.2023.
//

import Foundation
import Vision


class LicensePlateRecognise
{
    var completionHandler:((_ result:String?) -> Void)? = nil

    
    init() {
        
    }
    
    
    func getLicensePlateNumber(image:CGImage? ,completion:@escaping (_ resuls:String?) -> Void)
    {
        completionHandler = completion
        if let image = image {

            let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler(request:error:))
            request.recognitionLevel = .fast // set to fast for real-time performance
            request.usesLanguageCorrection = false // license plates aren't usually words
            //request.regionOfInterest = regionx // only process the area within the region of interest
            
            let requestHandler = VNImageRequestHandler(cgImage: image,
                                                       orientation: .currentRearCameraOrientation,
                                                       options: [:])
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error recognizing text in photo \(error)")
            }
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let candidates = results.compactMap { $0.topCandidates(1).first }
        for text in candidates
        {
            print("candidate: " + text.string)
            // Regex for License Plates in Turkey
            let newString = text.string.replacingOccurrences(of: " ", with: "")
            let pattern = #"^(0[1-9]|[1-7][0-9]|8[0-1])(([A-PR-VYZ]{1})(?!0{4,5}$)\d{4,5}|([A-PR-VYZ]{2})(?!0{3,4}$)\d{3,4}|([A-PR-VYZ]{3})(?!0{2,3}$)\d{2,3})$"#
            let resultOfRegEx = newString.range(of: pattern, options: .regularExpression)
            if((resultOfRegEx) != nil){
                print("TEXT----------------")
                print("PL: " + text.string)
                if let ch = completionHandler
                {
                    ch(text.string)
                }
            }
        }
        
    }
    
}
