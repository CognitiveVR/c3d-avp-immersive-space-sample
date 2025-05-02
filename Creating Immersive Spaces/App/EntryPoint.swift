/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI
import Cognitive3DAnalytics

@main
struct EntryPoint: App {
    init() {
        // Initialize the C3D SDK when app starts up
        cognitiveSDKInit()
    }
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        
        // Defines an immersive space as a part of the scene.
        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveView()
        }
    }
 
    func cognitiveSDKInit() {
        let sceneData = SceneData(
            sceneName: "Apple Immersive Space Scene",
            sceneId: "cf57b34e-f0bc-42ab-b903-728a5f3c8a19",
            versionNumber: 1,
            versionId: 1373
        )


        let core = Cognitive3DAnalyticsCore.shared

        let settings = CoreSettings()
        settings.customEventBatchSize = 64
        settings.defaultSceneName = sceneData.sceneName
        settings.allSceneData = [sceneData]

        settings.loggingLevel = .all
        settings.isDebugVerbose = false

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "APPLICATION_API_KEY") as? String ?? "default-value"
        settings.apiKey = apiKey

        // get the device UUID
        let uuidString = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "Unknown UUID"
        
        // core.setParticipantId("1234")
        core.setParticipantId(uuidString)
        
        // create a short list of random names in a string array
        let randomFirstNames = ["Alice", "Bob", "Charlie", "David", "Emma"]
        let randomLastNames = ["Anderson", "Brown", "Clark", "Davis", "Evans"]
        let randomFirstNameIndex = Int.random(in: 0..<randomFirstNames.count)
        let randomLastNameIndex = Int.random(in: 0..<randomLastNames.count)
        let randomFullName = "\(randomFirstNames[randomFirstNameIndex]) \(randomLastNames[randomLastNameIndex])"
        core.setParticipantFullName(randomFullName)

        // send some custom session properties
        Cognitive3DAnalyticsCore.shared.setSessionProperty(key: "stringProperty", value: "This is a lovely little string.")
        Cognitive3DAnalyticsCore.shared.setSessionProperty(key: "booleanTrueProperty", value: true)
        Cognitive3DAnalyticsCore.shared.setSessionProperty(key: "booleanFalseProperty", value: false)
        Cognitive3DAnalyticsCore.shared.setSessionProperty(key: "numericIntegerProperty", value: 42)
        Cognitive3DAnalyticsCore.shared.setSessionProperty(key: "numericFloatProperty", value: 55.1)

        // Start synchronous initialization
        Task {
            do {
                try await core.configure(with: settings)
                // Register code related to dynamic objects
                configureDynamicObject(settings)
                core.config?.shouldEndSessionOnBackground = false
            } catch {
                print("Failed to configure Cognitive3D Analytics: \(error)")
            }
        }
    }

    fileprivate func configureDynamicObject(_ settings: CoreSettings) {
        // To use the dynamic object component, we need to register it.
        DynamicComponent.registerComponent()

        // The component will be used with this custom system.
        DynamicObjectSystem.registerSystem()
    }
}

