//
//  Audio.swift
//  SCDemo
//
//  Created by Mars Geldard on 14/6/19.
//  Copyright © 2019 Mars Geldard. All rights reserved.
//

import CoreML
import AVFoundation
import SoundAnalysis

class ResultsObserver: NSObject, SNResultsObserving {
    private var completion: (String?) -> ()
    init(completion: @escaping (String?) -> ()) {
        self.completion = completion
    }
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let results = result as? SNClassificationResult,
            let result = results.classifications.first else {return}
        let label = result.confidence > 0.7 ? result.identifier : nil
        DispatchQueue.main.async {
            self.completion(label)
        }
    }
    func request(_ request: SNRequest, didFailWithError error: Error) {
        completion(nil)
    }
}

class AudioClassifier {
    
    // TODO: implement object able to tap input audio stream and
    // classify it as per the model we have trained
}
