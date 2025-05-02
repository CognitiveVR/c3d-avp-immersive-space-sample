//
//  ImmersiveViewExtension.swift
//  Cognitive3D SDK Example
//
//  Created by Manjit Bedi on 2025-02-01.
//

import Cognitive3DAnalytics
import RealityKit
import SwiftUI

extension ImmersiveView {
    // MARK: C3D configure the dynamic objects in the scene
    func configureDynamicObjects(rootEntity: Entity) {

        print("configureDynamicObjects - register them with the C3D server for the current session")

        guard let objManager = Cognitive3DAnalyticsCore.shared.dynamicDataManager else {
            return
        }

        // get a list of all the dynamic objects
        let dynamicEntities = findEntitiesWithComponent(rootEntity, componentType: DynamicComponent.self)
        for (entity, comp) in dynamicEntities {
            print("add entity \(entity.name) with id \(comp.dynamicId)")
            // Register the object with the C3D SDK. This method will post the object's information.
            Task {
                await objManager.registerDynamicObject(id: comp.dynamicId, name: comp.name, mesh: comp.mesh)
            }
        }
    }

    /**
     Finds and optionally logs all entities with a specific component in a hierarchy.

     - Parameters:
       - entity: The root entity to start searching from.
       - componentType: The type of component to search for.
       - debugLogging: Whether to print debug information about found entities.
     - Returns: An array of tuples containing entities and their corresponding components.
     */
    func findEntitiesWithComponent<T: Component>(
        _ entity: Entity, componentType: T.Type, isDebug: Bool = false
    ) -> [(entity: Entity, component: T)] {
        var foundEntities: [(entity: Entity, component: T)] = []

        func searchEntities(_ currentEntity: Entity, depth: Int = 0) {
            let indent = String(repeating: "    ", count: depth)

            // Check if the entity has the specified component
            if let component = currentEntity.components[componentType] {
                foundEntities.append((entity: currentEntity, component: component))
                if isDebug {
                    print("\(indent)📦 \(currentEntity.name)")
                    print("\(indent)├── 🔧 \(componentType)")
                }
            }

            // Recursively search children
            for child in currentEntity.children {
                searchEntities(child, depth: depth + 1)
            }
        }

        // Start the search
        searchEntities(entity)

        return foundEntities
    }
}
