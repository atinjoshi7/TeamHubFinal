//
//  EmployeeLocalDataSource.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 24/03/26.
//

import Foundation
import CoreData


protocol EmployeeLocalDataSourceProtocol {

    // Save in DB
    func save(_ employees: [Employee])
    
    // Fetch from DB
    func fetch(limit: Int, offset: Int) -> [Employee]
    
    func count() -> Int
    
    // Update in DB
    func update(_ employee: Employee)

    // ONLY DB METHODS
    func search(query: String) -> [Employee]

    func fetchFiltersFromDB() -> Filters

    func fetchFiltered(
        designations: [String],
        departments: [String],
        statuses: [String]
    ) -> [Employee]
    
    // Add new employee in DB
    func add(_ employee: Employee)
    
    // Delete from DB
    func delete(_ id: String)
    
    
    func fetchPendingSync() -> [Employee]
    func markSynced(_ id: String)
    func getSyncAction(for id: String) -> String
}
final class EmployeeLocalDataSource: EmployeeLocalDataSourceProtocol {

    

    private let stack: CoreDataStacking

    init(stack: CoreDataStacking) {
        self.stack = stack
    }
    
    func search(query: String) -> [Employee] {

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()

        req.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR designation CONTAINS[cd] %@ OR department CONTAINS[cd] %@",
            query, query, query
        )

        return (try? stack.viewContext.fetch(req))?.map { $0.toDomain() } ?? []
    }

    // MARK: - SAVE (Batch Insert + Protect Local Edits)
    func save(_ employees: [Employee]) {

        let ctx = stack.viewContext

        employees.forEach { emp in

            let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", emp.id)

            let existing = try? ctx.fetch(req).first

            let entity: EmployeeEntity

            if let existing = existing {
                // 🔥 UPDATE
                entity = existing
                print("✏️ Updating employee: \(emp.id)")
            } else {
                // 🔥 CREATE
                entity = EmployeeEntity(context: ctx)
                entity.id = emp.id
                print("🆕 Creating employee: \(emp.id)")
            }
            

            entity.name = emp.name
            entity.designation = emp.designation
            entity.department = emp.department
            entity.isActive = emp.isActive
            entity.imgURL = emp.imgUrl
            entity.email = emp.email
            entity.city = emp.city
            entity.country = emp.country

            // Phones reset
            if let old = entity.phones as? Set<PhoneEntity> {
                old.forEach { ctx.delete($0) }
            }

            emp.phones.forEach { phone in
                let p = PhoneEntity(context: ctx)
                p.id = phone.id
                p.type = phone.type
                p.number = phone.number
                p.employee = entity
            }
        }

        stack.save(context: ctx)
    }
    // MARK: - UPDATE (User Edit)

    func update(_ employee: Employee) {

        let ctx = stack.viewContext

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()

        req.predicate = NSPredicate(format: "id == %@", employee.id)

        let entity: EmployeeEntity

        if let existing = try? ctx.fetch(req).first {
            entity = existing
            print("✏️ Updating existing:", employee.id)
        } else {
            entity = EmployeeEntity(context: ctx)
            entity.id = employee.id
            print("🆕 Creating during update:", employee.id)
        }

        // MARK: - Update fields
        entity.name = employee.name
        entity.designation = employee.designation
        entity.department = employee.department
        entity.isActive = employee.isActive
        entity.email = employee.email
        entity.city = employee.city
        entity.country = employee.country

        // 🔥 CRITICAL (YOU MUST HAVE THIS)
        entity.needSync = true
        entity.syncAction = "update"
        entity.updatedAt = Date()
        entity.isDelete = false
        print("🔥 needSync:", entity.needSync)
        print("🔥 syncAction:", entity.syncAction ?? "")
        // MARK: - Phones
        if let old = entity.phones as? Set<PhoneEntity> {
            old.forEach { ctx.delete($0) }
        }

        employee.phones.forEach { phone in
            let p = PhoneEntity(context: ctx)
            p.id = phone.id
            p.type = phone.type
            p.number = phone.number
            p.employee = entity
            entity.addToPhones(p)
        }

        stack.save(context: ctx)
    }
    // MARK: - FETCH
    func fetch(limit: Int, offset: Int) -> [Employee] {
        let ctx = stack.viewContext

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        req.fetchLimit = limit
        req.fetchOffset = offset
        req.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        req.returnsObjectsAsFaults = false

        return (try? ctx.fetch(req))?.map { $0.toDomain() } ?? []
    }

    // MARK: - COUNT
    func count() -> Int {
        (try? stack.viewContext.count(for: EmployeeEntity.fetchRequest())) ?? 0
    }

    func fetchFiltersFromDB() -> Filters {

        let ctx = stack.viewContext

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()

        let employees = (try? ctx.fetch(req)) ?? []

        let designations = Set(employees.compactMap { $0.designation })
        let departments = Set(employees.compactMap { $0.department })

        let statuses = Set(employees.map { $0.isActive ? "active" : "inactive" })

        return Filters(
            designations: Array(designations),
            departments: Array(departments),
            statuses: Array(statuses)
        )
    }
    func fetchFiltered(
        designations: [String],
        departments: [String],
        statuses: [String]
    ) -> [Employee] {

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()

        var predicates: [NSPredicate] = []

        if !designations.isEmpty {
            predicates.append(NSPredicate(format: "designation IN %@", designations))
        }

        if !departments.isEmpty {
            predicates.append(NSPredicate(format: "department IN %@", departments))
        }

        if !statuses.isEmpty {
            let boolValues = statuses.map { $0 == "active" }
            predicates.append(NSPredicate(format: "isActive IN %@", boolValues))
        }

        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        return (try? stack.viewContext.fetch(req))?.map { $0.toDomain() } ?? []
    }
    func add(_ employee: Employee) {

        let ctx = stack.viewContext

        let entity = EmployeeEntity(context: ctx)

        entity.id = employee.id
        entity.name = employee.name
        entity.designation = employee.designation
        entity.department = employee.department
        entity.isActive = employee.isActive
        entity.imgURL = employee.imgUrl
        entity.email = employee.email
        entity.city = employee.city
        entity.country = employee.country

        entity.needSync = true
        entity.syncAction = "create"
        entity.updatedAt = Date()
        entity.isDelete = false

        employee.phones.forEach { phone in
            let p = PhoneEntity(context: ctx)
            p.id = phone.id
            p.type = phone.type
            p.number = phone.number
            p.employee = entity
            entity.addToPhones(p)
        }

        stack.save(context: ctx)
    }
    func delete(_ id: String) {

        let ctx = stack.viewContext

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)

        guard let entity = try? ctx.fetch(req).first else { return }

        entity.isDelete = true
        entity.needSync = true
        entity.syncAction = "delete"
        entity.updatedAt = Date()

        stack.save(context: ctx)
    }
    func fetchPendingSync() -> [Employee] {

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()

        req.predicate = NSPredicate(format: "needSync == true")

        return (try? stack.viewContext.fetch(req))?.map { $0.toDomain() } ?? []
    }
    func markSynced(_ id: String) {

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)

        guard let entity = try? stack.viewContext.fetch(req).first else { return }

        entity.needSync = false
        entity.syncAction = "none"

        stack.save(context: stack.viewContext)
    }
    func getSyncAction(for id: String) -> String {

        let req: NSFetchRequest<EmployeeEntity> = EmployeeEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)

        let entity = try? stack.viewContext.fetch(req).first

        return entity?.syncAction ?? ""
    }
}
extension EmployeeEntity {
    func toDomain() -> Employee {
        let phones = (self.phones as? Set<PhoneEntity> ?? [])
              let sortedPhones = phones.sorted {
                  ($0.id ?? "") < ($1.id ?? "")
              }

        return Employee(
            id: id ?? "",
            name: name ?? "",
            designation: designation ?? "",
            department: department ?? "",
            isActive: isActive,
            imgUrl: imgURL,
            email: email ?? "",
            city: city ?? "",
            joiningDate: joiningDate ?? "",
            country: country ?? "",
            phones: sortedPhones.map {
                Phone(
                    id: $0.id ?? "",
                    type: $0.type ?? "",
                    number: $0.number ?? ""
                )
            }
        )
    }
  
}
