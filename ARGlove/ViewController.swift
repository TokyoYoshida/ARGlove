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

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    let leftHandAnchor = AnchorEntity()
    let rightHandAnchor = AnchorEntity()
    var leftHandGlove: Experience.LeftHand!
    var rightHandGlove: Experience.RightHand!

    override func viewDidLoad() {
        func loadAnchor() {
            leftHandGlove = try! Experience.loadLeftHand()
            arView.scene.addAnchor(leftHandAnchor)
            rightHandGlove = try! Experience.loadRightHand()
            arView.scene.addAnchor(rightHandGlove)
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
