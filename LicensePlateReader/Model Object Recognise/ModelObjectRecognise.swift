//
//  LicensePlateManager.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 5.08.2023.
//

import Foundation
import Vision



class ModelObjectRecognise
{
    private var requests = [VNRequest]()
    
    var model:MLModel!
    var completionHandler:((_ results:[VNRecognizedObjectObservation]) -> Void)? = nil

    init (model:MLModel)
    {
        self.model = model
        self.setUpVision(model: self.model)
    }
    
    private func setUpVision(model:MLModel) {
        
        //let visionModel = try VNCoreMLModel(for: LicensePlateDetector().model)
        guard let visionModel = try? VNCoreMLModel(for: model) else { return }

        let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            self?.processResults(results)
        }
        
        self.requests = [objectRecognition]
    }
    
    func startMLRequest(sampleBuffer: CMSampleBuffer, completion:@escaping (_ results:[VNRecognizedObjectObservation]) -> Void)
    {
        completionHandler = completion

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: .currentRearCameraOrientation,
                                                        options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    private func processResults(_ results: [VNRecognizedObjectObservation]) {

        if let ch = completionHandler
        {
            ch(results)
        }
    }
    
}
