//
//  ContentView.swift
//  MNIST-ios
//
//  Created by yanadoo on 7/23/25.
//

import SwiftUI
import Sketch

struct ContentView: View {
    @StateObject private var controller = SketchViewController()
    
    @State private var classifier: DigitClassifier?
    @State private var statusMessage: String? = nil
    
    
    var body: some View {
        VStack {
            Spacer()
            SketchViewContainer(controller: controller)
                .frame(height: 400) // 원하는 크기 지정
            
            Spacer()
            if let statusMessage = statusMessage {
                Text("\(statusMessage)")
            }
            Spacer()
            Button("지우기", action: {
                controller.clear()
                self.statusMessage = "숫자를 그려주세요 :)"
            })
            Spacer()
        }
        .padding()
        .onAppear {
            DigitClassifier.newInstance { result in
                switch result {
                case let .success(classifier):
                    self.classifier = classifier
                    self.statusMessage = "초기화 성공"
                case .failure(_):
                    self.statusMessage = "초기화 실패"
                }
            }
            
            controller.onDrawEnded = {
                            classifyDrawing()
                        }
        }
    }
    
    private func classifyDrawing() {
        guard let classifier = self.classifier else { return }
        guard let sketchView = controller.sketchView else {
                self.statusMessage = "스케치 뷰가 없습니다."
                return
            }
            
        let size = sketchView.frame.size
        UIGraphicsBeginImageContext(size)
        controller.self.sketchView?.layer.render(in: UIGraphicsGetCurrentContext()!)
        let drawing = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard drawing != nil else {
            self.statusMessage = "입력이 잘못되었습니다."
            return
        }
        
        classifier.classify(image: drawing!) { result in
            switch result {
            case let .success(classificationResult):
                self.statusMessage = classificationResult
            case .failure(_):
                self.statusMessage = "분류에 실패했습니다."
            }
        }
    }
}

#Preview {
    ContentView()
}

class SketchViewController: NSObject, ObservableObject, SketchViewDelegate {
    
    fileprivate var sketchView: SketchView?
    var onDrawEnded: (() -> Void)?
    
    func clear() {
        print("결과 : clear")
        sketchView?.clear()
    }
    
    func drawView(_ view: SketchView, didEndDrawUsingTool tool: AnyObject) {
        onDrawEnded?()
    }
}

struct SketchViewContainer: UIViewRepresentable {
    @ObservedObject var controller: SketchViewController
    
    func makeUIView(context: Context) -> SketchView {
        let sketchView = SketchView()
        sketchView.backgroundColor = .black
        sketchView.lineColor = .white
        sketchView.lineWidth = 20
        sketchView.sketchViewDelegate = controller
        controller.sketchView = sketchView // 연결!
        
        return sketchView
    }
    
    func updateUIView(_ uiView: SketchView, context: Context) {}
}
