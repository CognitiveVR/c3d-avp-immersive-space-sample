/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A RealityKit view that creates a ring of asteroids that orbit around the person.
*/

import SwiftUI
import RealityKit
import Cognitive3DAnalytics

/// A view that creates an entity filled with rocks that rotate around the average height of a human.
struct ImmersiveView: View {
    /// The average human height in meters.
    let avgHeight: Float = 1.70

    /// The rate of movement at which the rocks orbit.
    let speed: TimeInterval = 0.03

    var body: some View {
        // Initiate a `RealityView` to create a ring
        // of rocks to orbit around a person.
        RealityView { content in
            /// The entity to contain the models.
            let rootEntity = Entity()

            // Set the y-axis position to the average human height.
            rootEntity.position.y += avgHeight

            // Create the halo effect with the `addHalo` method.
            rootEntity.addHalo()

            // Set the rotation speed for the rocks.
            rootEntity.components.set(TurnTableComponent(speed: speed))

            // Register the `TurnTableSystem` to handle the rotation logic.
            TurnTableSystem.registerSystem()
            
            // add one asteroid in the middle of the halo to test dynamic objects
//            let dynamicObjectEntity = createDynamicObjectEntity()
//            rootEntity.addChild(dynamicObjectEntity)

            // create a cube in the middle of the asteroid halo
            let cubeEntity = createCube()
            rootEntity.addChild(cubeEntity)
            configureDynamicObjects(rootEntity: cubeEntity)
            
            // Add the entity to the view.
            content.add(rootEntity)
            // MARK: C3D SDK
            // This is needed to perform ray casts & collision detection with the gaze tracker.
            // If a gaze collides with a dynamic object, the dynamic object id gets added to the gaze record.
            // The gaze record gets posted to the C3D back end.
            if let entity = content.entities.first {
                let core = Cognitive3DAnalyticsCore.shared
                core.contentEntity = entity
            }
            

//            if let firstEntity = content.entities.first {
//                print("C3D session state \(Cognitive3DAnalyticsCore.shared.isSessionActive)")
//                configureDynamicObjects(rootEntity: firstEntity)
//            }

        }
        .onDisappear() {
            // End the session
            Task {
                await Cognitive3DAnalyticsCore.shared.endSession()
            }
        }.gesture(tapGesture)
    }
    
    func createDynamicObjectEntity() -> Entity {
        let entity = Entity()

        return entity
    }
    
    // MARK: - RealityKit working with entities
    /// Create a cube & add a `DynamicComponent` to it.
    /// For hit detection to work, we need to add: an input target and collision component.
    private func createCube() -> ModelEntity {
        let size: Float = 0.3 // Cube with 30 cm sides

        let cubeEntity = ModelEntity(mesh: .generateBox(size: size))

        // Apply material to the cube
        let material = SimpleMaterial(color: .purple, isMetallic: true)
        cubeEntity.model?.materials = [material]

        // Set the position of the cube (center of the asteroid halo)
        cubeEntity.position = [0, 0, 0]

        // Add collision component - this is needed for raycasts
        cubeEntity.collision = CollisionComponent(
            shapes: [.generateBox(size: SIMD3(repeating: size))],
            mode: .default,
            filter: .default
        )

        // Add input component - this is needed for spatial taps
        cubeEntity.components.set(InputTargetComponent())

        // Now to add a custom component to facilitate dynamic object snapshot recording.
        var component = DynamicComponent()
        component.name = "Asteroid" // this is the dynamic object name on the Cognitive3D dashboard
        component.mesh = "asteroid" // this is the mesh file name that loads the GLTF on the Cognitive3D dashboard
        component.dynamicId = "d46cdb90-25a7-4bd6-ba44-9227aff95135"
        cubeEntity.components.set(component)
        return cubeEntity
    }

    /// Momentarily change the material on the entity.
    private func objectSpatialTapFeedback(_ modelComponent: inout ModelComponent, _ tappedEntity: Entity) {
//        print("entity tapped on \(tappedEntity)")

        // Store the original materials before changing them
        let originalMaterials = modelComponent.materials

        let highlightMaterial = SimpleMaterial(
            color: .green,
            roughness: 0.5,
            isMetallic: false
        )

        // Apply the new material
        modelComponent.materials = [highlightMaterial]
        tappedEntity.components[ModelComponent.self] = modelComponent
        var tappedEntityPosition = tappedEntity.position
        let randomLength = Float.random(in: 0...0.1)
        tappedEntityPosition += [0,0,randomLength]
        tappedEntity.position = tappedEntityPosition

        Task {
            try? await Task.sleep(for: .seconds(0.1))

            // Restore the original materials
            if var updatedModelComponent = tappedEntity.components[ModelComponent.self] {
                updatedModelComponent.materials = originalMaterials
                tappedEntity.components[ModelComponent.self] = updatedModelComponent
            }
        }
    }

    // MARK: Tap gesture
    /// Test if the tapped object has a dynamic object component & also if it has a collision component.
    /// The collision component is needed for doing gaze tracking with ray casts.
    var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
//                print("Spatial tag gesture")

                let tappedEntity = value.entity

                // Test to find component and its value
                if let component = tappedEntity.components[DynamicComponent.self] {
//                    print("Found dynamicId: \(component.dynamicId)")
                    createDynamicObjectEvent(dynamicId: component.dynamicId)
                }

                // Check if the entity has a ModelComponent
                if var modelComponent = tappedEntity.components[ModelComponent.self] {
                    objectSpatialTapFeedback(&modelComponent, tappedEntity)
                }
            }
    }

    // MARK: C3D analytics
    private func createDynamicObjectEvent(dynamicId: String) {
        let core = Cognitive3DAnalyticsCore.shared

        let event = CustomEvent(
            name: "tapEvent",
            properties: [
                "description": "dynamic object tapped"
            ],
            dynamicObjectId: dynamicId,
            core: core
        )

        Task {
            _ =  event.sendWithHighPriority()
//            print("custom event \(success)")
        }
    }
}
