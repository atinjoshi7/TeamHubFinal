//
//  File.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 29/03/26.
//

import Foundation
import CoreData

protocol CoreDataStacking {
    var viewContext: NSManagedObjectContext { get }

    func save(context: NSManagedObjectContext)
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}


final class CoreDataStack: CoreDataStacking {

    static let shared = CoreDataStack()

    private let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {

        container = NSPersistentContainer(name: "TeamHub") // ⚠️ your .xcdatamodeld name

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ CoreData load error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }

        do {
            try context.save()
            print(" CoreData saved")
        } catch {
            print("CoreData save error:", error)
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(ctx)

            do {
                if ctx.hasChanges {
                    try ctx.save()
                }
            } catch {
                print("❌ Background save error:", error)
            }
        }
    }
}
