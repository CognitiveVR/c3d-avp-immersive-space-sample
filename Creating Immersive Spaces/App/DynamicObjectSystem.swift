//
//  DynamicObjectSystem.swift
//  Cognitive3D SDK Example
//
//  Created by Manjit Bedi on 2025-01-31.
//

import RealityKit
import Cognitive3DAnalytics

/// This class works with the Dynamic object manager in the C3D SDK to record dynamic object data for the active analytics session.
public final class DynamicObjectSystem: System {
    // Query to find all entities with DynamicComponent
    private static let query = EntityQuery(where: .has(DynamicComponent.self))
    private var inactiveStates: [String: Bool] = [:]
    private let dynamicManager: DynamicDataManager

    var isDebugVerbose = false

    // Required initializer for RealityKit System
    public required init(scene: Scene) {
        self.dynamicManager = Cognitive3DAnalyticsCore.shared.dynamicDataManager!
    }

    // Using a system, update the transforms of dynamic objects. The data gets posted to the C3D servers.
    public func update(context: SceneUpdateContext) {
        Task {
            await processEntities(context: context)
        }
    }

    private func processEntities(context: SceneUpdateContext) async {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            // Safely extract component information
            guard let dynamicComponent = await extractDynamicComponent(from: entity) else {
                continue
            }

            // Capture current entity state
            let isParentNil = await isEntityParentNil(entity)
            let isEntityActive = await checkEntityActive(entity)

            if isParentNil || !isEntityActive {
                await handleEndabledStateChange(entity, component: dynamicComponent)
                continue
            }

            let properties = [["enabled": AnyCodable(true)]]

            // Safely capture entity properties
            let position = await entity.position
            let rotation = await entity.orientation
            let scale = await entity.scale

            await dynamicManager.recordDynamicObject(
                id: dynamicComponent.dynamicId,
                position: position,
                rotation: rotation,
                scale: scale,
                positionThreshold: dynamicComponent.positionThreshod,
                rotationThreshold: dynamicComponent.rotationThreshod,
                scaleThreshold: dynamicComponent.scaleThreshold,
                updateRate: dynamicComponent.updateRate,
                properties: properties
            )
        }
    }

    // Helper methods to safely access entity properties across actor boundaries
    private func extractDynamicComponent(from entity: Entity) async -> DynamicComponent? {
        return await MainActor.run {
            entity.components[DynamicComponent.self]
        }
    }

    private func isEntityParentNil(_ entity: Entity) async -> Bool {
        return await MainActor.run {
            entity.parent == nil
        }
    }

    private func checkEntityActive(_ entity: Entity) async -> Bool {
        return await MainActor.run {
            entity.isActive
        }
    }

    private func handleEndabledStateChange(_ entity: Entity, component: DynamicComponent) async {
        let isDisabled = await MainActor.run {
            !entity.isEnabled || !entity.isActive
        }

        if isDisabled {
            // Perform both check and update atomically on the MainActor
            let shouldRemove = await MainActor.run {
                // If not already inactive, mark as inactive and return true
                if inactiveStates[component.dynamicId] != true {
                    inactiveStates[component.dynamicId] = true
                    return true
                }
                return false
            }

            // Only remove if we successfully marked it as inactive
            if shouldRemove {
                if isDebugVerbose {
                    print("Entity '\(await entity.name)' with dynamic ID \(component.dynamicId) is being removed from tracking.")
                }
                await dynamicManager.removeDynamicObject(id: component.dynamicId)
            }
        }
    }
}
