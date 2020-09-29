//
//  ViewController.swift
//  ARGlove
//
//  Created by TokyoYoshida on 2020/09/29.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import ReplayKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var button: UIButton!
    
    let leftHandAnchor = AnchorEntity()
    let rightHandAnchor = AnchorEntity()
    var leftHandGlove: Experience.LeftHand!
    var rightHandGlove: Experience.RightHand!
    var nowRecording: Bool = false

    override func viewDidLoad() {
        func loadAnchor() {
            leftHandGlove = try! Experience.loadLeftHand()
            rightHandGlove = try! Experience.loadRightHand()

            arView.scene.addAnchor(leftHandAnchor)
            arView.scene.addAnchor(rightHandAnchor)
        }
        super.viewDidLoad()
        loadAnchor()
    }

    override func viewDidAppear(_ animated: Bool) {
        func configureARKit() {
            guard ARBodyTrackingConfiguration.isSupported else {
                    fatalError("This feature is only supported on devices with an A12 chip")
            }
            arView.session.delegate = self

            let configuration = ARBodyTrackingConfiguration()
            arView.session.run(configuration)

            arView.debugOptions = [.showWorldOrigin]
        }
        super.viewDidAppear(animated)
        configureARKit()
    }
    
    @IBAction func tappedButton(_ sender: Any) {
        if nowRecording {
            nowRecording = false
            button.setTitle("Start", for: .normal)
            stopRecording()
        } else {
            nowRecording = true
            button.setTitle("Stop", for: .normal)
            startRecording()
        }
    }
}

extension ViewController: ARSessionDelegate{

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            guard let leftHandTransform = bodyAnchor.skeleton.modelTransform(for: .leftHand) else { continue }
            guard let rightHandTransform = bodyAnchor.skeleton.modelTransform(for: .rightHand) else { continue }
            if leftHandGlove.parent == nil {
                leftHandAnchor.addChild(leftHandGlove)
                rightHandAnchor.addChild(rightHandGlove)
            }
            let leftHandTrans = bodyAnchor.transform * leftHandTransform
            leftHandAnchor.transform = Transform(matrix: leftHandTrans)
            let rightHandTrans = bodyAnchor.transform * rightHandTransform
            rightHandAnchor.transform = Transform(matrix: rightHandTrans)
        }
    }
}

extension ViewController {
    func startRecording() {
        guard !RPScreenRecorder.shared().isRecording else { return }
        RPScreenRecorder.shared().startRecording(handler: { (error) in
            if let error = error {
                debugPrint(#function, "recording something failed", error)
            }
        })
    }

    func stopRecording() {
        guard RPScreenRecorder.shared().isRecording else { return }
        RPScreenRecorder.shared().stopRecording(handler: { (previewViewController, error) in
            guard let previewViewController = previewViewController else { return }
            previewViewController.previewControllerDelegate = self

            self.present(previewViewController, animated: true, completion: nil)
        })
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async {
            previewController.dismiss(animated: true, completion: nil)
        }
    }
}
