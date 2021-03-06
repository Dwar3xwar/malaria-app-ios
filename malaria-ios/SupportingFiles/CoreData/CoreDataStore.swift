import Foundation
import CoreData

/// Manages `NSPersistentStoreCoordinator`. Contains storeName and storeFileName and manages options for auto migration
public class CoreDataStore{
    /// Singleton
    public static let sharedInstance = CoreDataStore()
    
    private let storeName = "Model"
    private let storeFilename = "malaria-ios.sqlite"
    
    internal lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
        }()
    
    internal lazy var managedObjectModel: NSManagedObjectModel = {
        // Get model
        let modelURL = NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")!
        var model = NSManagedObjectModel(contentsOfURL: modelURL)!
        
        return model
        }()
    
    internal lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.storeFilename)
        
        do {
            try coordinator.addPersistentStoreWithType(
                        NSSQLiteStoreType,
                        configuration: nil,
                        URL: url,
                        options: [
                            NSInferMappingModelAutomaticallyOption: true,
                            NSMigratePersistentStoresAutomaticallyOption: true
                        ])
        } catch var error as NSError {
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        } catch {
            fatalError()
        }

        return coordinator
        }()
}