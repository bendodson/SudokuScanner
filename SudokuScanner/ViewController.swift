//
//  ViewController.swift
//  SudokuScanner
//
//  Created by Ben Dodson on 29/07/2020.
//

import UIKit
import AVFoundation
import Vision

struct DetectedCell {
    var row: Int
    var column: Int
    var text: String
}

class ViewController: UIViewController {
    
    var imageSize: CGFloat = 0
    var cellSize: CGFloat = 0
    
    @IBOutlet weak var debugImageView: UIImageView!
    
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en_US"]
        return request
    }()

    @IBAction func takePhoto(_ sender: Any) {
        presentImagePicker(.camera)
    }
    
    @IBAction func importImage(_ sender: Any) {
        presentImagePicker(.photoLibrary)
    }
    
    private func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        imageSize = image.size.width
        cellSize = image.size.width / 9
        let requests = [textDetectionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
    private func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            print("Error: \(error)")
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No text found")
            return
        }
        
        var cells = [DetectedCell]()
        
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    
                    let x = observation.boundingBox.origin.x * imageSize
                    let y = ((observation.boundingBox.origin.y * -1) + 1) * imageSize
                    let text = text.string
                    
                    let column = Int((x / cellSize).rounded(.down))
                    let row = Int((y / cellSize).rounded(.down))
                    
                    let cell = DetectedCell(row: row, column: column, text: text)
                    cells.append(cell)
                }
            }
        }
        
        cells.sort { (a, b) -> Bool in
            if a.row == b.row {
                return a.column < b.column
            }
            return a.row < b.row
        }
        
        var lines = Array(repeating: Array(repeating: "0", count: 9), count: 9)
        for cell in cells {
            let number = Int(cell.text) ?? 0
            if number > 0, number <= 9 {
                lines[cell.row][cell.column] = "\(number)"
            }
        }
        
        let string = lines.map({$0.joined(separator: "")}).joined(separator: "\n")
        print(string + "\n")
        
        DispatchQueue.main.async {
            UIPasteboard.general.string = string
            let controller = UIAlertController(title: nil, message: "Sudoku copied to clipboard", preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private func presentImagePicker(_ sourceType: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = sourceType
        controller.allowsEditing = true
        present(controller, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        guard let image = info[.editedImage] as? UIImage else { return }
        debugImageView.image = image
        process(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
