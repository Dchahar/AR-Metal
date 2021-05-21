//
//  ViewController.swift
//  AR+Metal
//
//  Created by Dheeraj Chahar on 17/05/21.
//

import UIKit
import MetalKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.delegate = self
        self.sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.sceneView.session.pause()
    }
    
    @IBAction func resetAR(_ sender: UIButton) {
        self.sceneView.session.pause()
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
    
// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        
        for anchor in currentFrame.anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            guard let node = self.sceneView.node(for: planeAnchor) else { continue }
            
            DispatchQueue.main.async {
                let planeNode = planeAnchor.findPlaneNode(on: node)
                guard let material = planeNode?.geometry?.firstMaterial else { return }
                self.updateTime(time, for: material)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        
        // Shaders for the material
        let program = SCNProgram()
        program.vertexFunctionName = "scnVertexShader"
        program.fragmentFunctionName = "scnFragmentShader"

        planeAnchor.addPlaneNode(on: node, contents: program)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        planeAnchor.updatePlaneNode(on: node)
    }
    
    private func updateTime(_ time: TimeInterval, for material: SCNMaterial) {
        var floatTime = Float(time)
        let timeData = Data(bytes: &floatTime, count: MemoryLayout<Float>.size)
        material.setValue(timeData, forKey: "time")
    }
}
