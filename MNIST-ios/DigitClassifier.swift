//
//  DigitClassifier.swift
//  MNIST-ios
//
//  Created by yanadoo on 7/24/25.
//

import TensorFlowLite

class DigitClassifier {
    private var interpreter: Interpreter
    private var inputImageWidth: Int
    private var inputImageHeight: Int
    
    init(interpreter: Interpreter, inputImageWidth: Int, inputImageHeight: Int) {
        self.interpreter = interpreter
        self.inputImageWidth = inputImageWidth
        self.inputImageHeight = inputImageHeight
    }
    
    static func newInstance(completion: @escaping (Result<DigitClassifier>) -> ()) {
        DispatchQueue.global(qos: .background).async {
            guard let modelPath = Bundle.main.path(forResource: "mnist_google", ofType: "tflite") else {
                DispatchQueue.main.async {
                    completion(.failure(InitError.invalidModel("mnist_google.tflite 파일을 불러올 수 없습니다.")))
                }
                return
            }
            
            var options = Interpreter.Options()
            options.threadCount = 2
            
            do {
                let interIntpreter = try Interpreter(modelPath: modelPath, options: options)
                try interIntpreter.allocateTensors()
                
                let inputShape = try interIntpreter.input(at: 0).shape
                let inputImageWidth = inputShape.dimensions[1]
                let inputImageHeight = inputShape.dimensions[2]
                
                let classifier = DigitClassifier(interpreter: interIntpreter,
                                                 inputImageWidth: inputImageWidth,
                                                 inputImageHeight: inputImageHeight)
                
                DispatchQueue.main.async {
                    completion(.success(classifier))
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(.failure(InitError.internalError(error)))
                }
                return
            }
        }
    }
    
    func classify(image: UIImage, completion: @escaping (Result<String>) -> ()) {
        DispatchQueue.global(qos: .background).async {
            let outputTensor: Tensor
            do {
                guard let rgbData = image.scaledData(with: CGSize(width: self.inputImageWidth, height: self.inputImageHeight)) else {
                    DispatchSerialQueue.main.async {
                        completion(.failure(ClassificationError.invalidImange))
                    }
                    return
                }
                
                try self.interpreter.copy(rgbData, toInputAt: 0)
                try self.interpreter.invoke()
                outputTensor = try self.interpreter.output(at: 0)
             
            } catch let error {
                DispatchQueue.main.async {
                    completion(.failure(ClassificationError.internalError(error)))
                }
                return
            }
            
            let results = outputTensor.data.toArray(type: Float32.self)
            let maxConfidence = results.max() ?? -1
            let maxIndex = results.firstIndex(of: maxConfidence) ?? -1
            let resultString = "예측값: \(maxIndex), 정확도: \(maxConfidence)"
            
            DispatchQueue.main.async {
                completion(.success(resultString))
            }
        }
    }
}

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum InitError: Error {
    case invalidModel(String)
    case internalError(Error)
}

enum ClassificationError: Error {
    case invalidImange
    case internalError(Error)
}
