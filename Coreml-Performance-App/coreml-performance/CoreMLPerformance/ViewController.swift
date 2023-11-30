//
//  ViewController.swift
//  CoreMLPerformance
//
//  Created by Vladimir Chernykh on 14.05.2020.
//  Copyright © 2020 Vladimir Chernykh. All rights reserved.
//

import UIKit
import Vision
import UserNotifications
import GCDWebServer

class ViewController: UIViewController, ModelSelectionDelegate {
    let cpuLatencyLabel = UILabel()
    let gpuLatencyLabel = UILabel()
    let aneLatencyLabel = UILabel()
    let selectModelButton = UIButton(type: .system)
    let runInferenceButton = UIButton(type: .system)
    let screenOffInferenceButton = UIButton(type: .system)
    let modelLabel = UILabel()
    
    let cpuButton = UIButton(type: .system)
    let gpuButton = UIButton(type: .system)
    let aneButton = UIButton(type: .system)
    let allButton = UIButton(type: .system)
    var selectedDevices: [String] = []
    
    var selectedModel: String?
    var webServer: GCDWebServer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebServer()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting authorization for notifications: \(error)")
            }
        }
    }
    
    func setupWebServer() {
        let webServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET", path: "/runInference", request: GCDWebServerRequest.self) { [weak self] request in
            guard let model = request.query?["model"], let device = request.query?["device"] else {
                return GCDWebServerErrorResponse(statusCode: 400)
            }
                
            DispatchQueue.main.async {
                self?.startInference(modelName: model, deviceType: device)
            }
            
            return GCDWebServerDataResponse(text: "Starting inference for model \(model) on device \(device)")
        }

        webServer.start(withPort: 8080, bonjourName: "GCD Web Server")
        self.webServer = webServer
    }
    
    func startInference(modelName: String, deviceType: String) {
        self.selectedModel = modelName
        self.selectedDevices = [deviceType]
        DispatchQueue.main.async {
            self.performInference()
        }
    }

    func url(forResource fileName: String, withExtension ext: String) -> URL {
        let bundle = Bundle(for: ViewController.self)
        return bundle.url(forResource: fileName, withExtension: ext)!
    }

    func testPerformace(modelName: String, device: String, numIter: Int = 100) throws -> Double {
        let config = MLModelConfiguration()
        if device.lowercased() == "ane" {
            config.computeUnits = .all
        } else if device.lowercased() == "gpu" {
            config.computeUnits = .cpuAndGPU
        } else {
            config.computeUnits = .cpuOnly
        }
        let model = try Predictor(contentsOf: modelName, configuration: config)
        let inputName: String
        if model.model.modelDescription.inputDescriptionsByName["my_input"] != nil {
            inputName = "my_input"
        } else if model.model.modelDescription.inputDescriptionsByName["x_1"] != nil {
            inputName = "x_1"
        } else if model.model.modelDescription.inputDescriptionsByName["input"] != nil {
            inputName = "input"
        } else {
            throw NSError(domain: "MyErrorDomain", code: 100, userInfo: [NSLocalizedDescriptionKey: "Input name not found in model description"])
        }
        let imageFeatureValue = try MLFeatureValue(
            imageAt: url(forResource: "test01", withExtension: "jpg"),
            constraint: model.model.modelDescription.inputDescriptionsByName[inputName]!.imageConstraint!,
            options: [.cropAndScale: VNImageCropAndScaleOption.centerCrop.rawValue]
        )
        let input = try MLDictionaryFeatureProvider(
            dictionary: [inputName: imageFeatureValue.imageBufferValue!]
        )

        let startTime = CACurrentMediaTime()
        for _ in 0..<numIter {
            _ = try! model.prediction(input: input)
        }
        let endTime = CACurrentMediaTime()

        return (endTime - startTime) / Double(numIter)
    }

    func setupUI() {
        view.backgroundColor = .white
        
        cpuLatencyLabel.textAlignment = .center
        gpuLatencyLabel.textAlignment = .center
        aneLatencyLabel.textAlignment = .center
        modelLabel.textAlignment = .center
        modelLabel.text = ""
        
        selectModelButton.setTitle("Select Model", for: .normal)
        selectModelButton.addTarget(self, action: #selector(selectModelButtonTapped), for: .touchUpInside)
        selectModelButton.backgroundColor = .systemBlue
        selectModelButton.layer.cornerRadius = 10
        selectModelButton.setTitleColor(.white, for: .normal)
        
        runInferenceButton.setTitle("Run Inference", for: .normal)
        runInferenceButton.addTarget(self, action: #selector(runInferenceButtonTapped), for: .touchUpInside)
        runInferenceButton.backgroundColor = .systemBlue
        runInferenceButton.layer.cornerRadius = 10
        runInferenceButton.setTitleColor(.white, for: .normal)
        
        screenOffInferenceButton.setTitle("Screen Off Inference", for: .normal)
        screenOffInferenceButton.addTarget(self, action: #selector(screenOffInferenceButtonTapped), for: .touchUpInside)
        screenOffInferenceButton.backgroundColor = .systemBlue
        screenOffInferenceButton.layer.cornerRadius = 10
        screenOffInferenceButton.setTitleColor(.white, for: .normal)
        
        // Configure device selection buttons
        configureDeviceButton(cpuButton, title: "CPU")
        configureDeviceButton(gpuButton, title: "GPU")
        configureDeviceButton(aneButton, title: "ANE")
        configureDeviceButton(allButton, title: "All")
        
        let buttonStackView = UIStackView(arrangedSubviews: [cpuButton, gpuButton, aneButton, allButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 5
        buttonStackView.distribution = .fillEqually
        
        let stackView = UIStackView(arrangedSubviews: [buttonStackView, selectModelButton, runInferenceButton,                                                   screenOffInferenceButton, modelLabel, cpuLatencyLabel, gpuLatencyLabel, aneLatencyLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        ])
    }
    
    @objc func selectModelButtonTapped() {
        let modelSelectionVC = ModelSelectionTableViewController()
        modelSelectionVC.delegate = self
        let navigationController = UINavigationController(rootViewController: modelSelectionVC)
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func runInferenceButtonTapped() {
        performInference()
    }
    
    @objc func screenOffInferenceButtonTapped() {
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(proximityStateChanged(_:)), name: UIDevice.proximityStateDidChangeNotification, object: nil)
    }
    
    @objc func proximityStateChanged(_ notification: Notification) {
        if UIDevice.current.proximityState {
            // Proximity sensor is triggered (screen is covered)
            performInference()
            // Disable proximity monitoring and remove the observer
            UIDevice.current.isProximityMonitoringEnabled = false
            NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }
    }
    
    func performInference() {
        guard let selectedModel = selectedModel else {
            // Show an alert on the screen
            let alertController = UIAlertController(title: "No Model Selected", message: "Please select a model first.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // warmup
        _ = try! testPerformace(
            modelName: selectedModel,
            device: "CPU",
            numIter: 100
        )
        self.startRealTest()
    }
    
    func startRealTest() {
        for device in selectedDevices {
            // Notify Monsoon to start sampling right after warmup
            self.notifyMonsoonToStartSampling()
            let latency = try! testPerformace(
                modelName: selectedModel!,
                device: device,
                numIter: 500
            )
            self.notifyMonsoonToStopSampling()
            let latencyInMs = latency * 1000
            let latencyText = "Latency \(device): \(latencyInMs) ms"
            switch device {
            case "CPU":
                cpuLatencyLabel.text = latencyText
            case "GPU":
                gpuLatencyLabel.text = latencyText
            case "ANE":
                aneLatencyLabel.text = latencyText
            default:
                break
            }
        }
        modelLabel.text = "Selected model: " + String(selectedModel!)
//        sendNotification()
    }

    func didSelectModel(_ model: String) {
        selectedModel = model
    }
    
    func configureDeviceButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(deviceButtonTapped(_:)), for: .touchUpInside)
        button.backgroundColor = .systemPurple
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.black, for: .selected)
    }
    
    @objc func deviceButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        let device = sender.currentTitle!
        if sender.isSelected {
            if device == "All" {
                selectedDevices = ["CPU", "GPU", "ANE"]
                cpuButton.isSelected = true
                gpuButton.isSelected = true
                aneButton.isSelected = true
            } else {
                selectedDevices.append(device)
                if selectedDevices.contains("CPU") && selectedDevices.contains("GPU") && selectedDevices.contains("ANE") {
                    allButton.isSelected = true
                }
            }
        } else {
            if device == "All" {
                selectedDevices = []
                cpuButton.isSelected = false
                gpuButton.isSelected = false
                aneButton.isSelected = false
            } else {
                selectedDevices.removeAll { $0 == device }
                allButton.isSelected = false
            }
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Inference Completed"
        content.body = "The screen off inference has been completed."
        content.sound = UNNotificationSound.defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "inferenceComplete", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func notifyMonsoonToStartSampling() {
        guard let url = URL(string: "http://10.0.0.128:5002/start-sampling") else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error notifying Monsoon: \(error)")
            } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Monsoon notified successfully")
            }
        }
        task.resume()
    }
    func notifyMonsoonToStopSampling() {
        guard let url = URL(string: "http://10.0.0.128:5002/stop-sampling") else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error notifying Monsoon to stop sampling: \(error)")
            } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Monsoon stop sampling notification sent successfully")
            }
        }
        task.resume()
    }
}
