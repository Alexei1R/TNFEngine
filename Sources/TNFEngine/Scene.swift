// Copyright (c) 2025 The Noughy Fox
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

public final class Scene {
    private let registry: Registry
    private var namedEntities: [String: Entity] = [:]

    public init() {
        self.registry = Registry()
    }

    @discardableResult
    public func create(named name: String? = nil) -> Entity {
        let entity = registry.createEntity()
        if let name = name {
            namedEntities[name] = entity
        }
        return entity
    }

    public func get(named name: String) -> Entity? {
        return namedEntities[name]
    }

    public func destroy(_ entity: Entity) {
        registry.destroyEntity(entity)
        namedEntities = namedEntities.filter { $0.value != entity }
    }

    public func destroy(named name: String) {
        if let entity = namedEntities[name] {
            registry.destroyEntity(entity)
            namedEntities.removeValue(forKey: name)
        }
    }

    @discardableResult
    public func add<T: Component>(_ component: T, to entity: Entity) -> T {
        registry.addComponent(component, to: entity)
    }

    public func get<T: Component>(for entity: Entity) -> T? {
        registry.getComponent(for: entity)
    }

    public func remove<T: Component>(_ type: T.Type, from entity: Entity) {
        registry.removeComponent(type: type, from: entity)
    }

    public func view<T: Component>(of type: T.Type) -> Registry.View<(T.Type)> {
        registry.view(requiring: type)
    }

    public func view<T1: Component, T2: Component>(_ type1: T1.Type, _ type2: T2.Type)
        -> Registry.View<(T1.Type, T2.Type)>
    {
        registry.view(requiring: type1, type2)
    }

    // Get all entities
    public var entities: [Entity] {
        Array(registry.entities)
    }

    // Get all named entities with their names
    public var namedEntityList: [(name: String, entity: Entity)] {
        Array(namedEntities).map { ($0.key, $0.value) }
    }
}
