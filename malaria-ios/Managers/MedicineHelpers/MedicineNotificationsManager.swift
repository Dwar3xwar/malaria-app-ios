import Foundation
import UIKit

/// Manages notifications for medicine
public class MedicineNotificationsManager : NotificationManager{
    /// Notification category
    override public var category: String { get{ return MedicineNotificationsManager.NotificationCategory } }

    /// Notification alert body
    override public var alertBody: String { get{
        let medicineName = MedicineManager(context: context).getCurrentMedicine()!.name
        return "Did you take \(medicineName) today?" }
    }
    
    /// Notification alert action
    override public var alertAction: String { get{ return "Take pill"} }
    
    private let medicine: Medicine
    
    /// If for Yes in interactive notifications
    public static let TookPillId = "TookPill"
    /// Yes aciton string for interactive notifications
    public static let TookPillTitle = "Yes"
    /// Id for No in interactive notifications
    public static let DidNotTakePillId = "DidNotTakePillId"
    /// No action string for interactive notifications
    public static let DidNotTakePillTitle = "No"
    /// notification category
    public static let NotificationCategory = "PILL_REMINDER"
    
    /// Init
    public init(context: NSManagedObjectContext, medicine: Medicine){
        self.medicine = medicine
        super.init(context: context)
    }
    
    /// Schedule notification and stores the fireTime in the medicine object
    ///
    /// :param: `NSDate`: trigger time
    public override func scheduleNotification(fireTime: NSDate) {
        medicine.notificationTime = fireTime
        CoreDataHelper.sharedInstance.saveContext(self.context)
        super.unsheduleNotification()
        super.scheduleNotification(fireTime)
    }
    
    /// Unshedule notification and sets the fireTime in medicine object as nil
    public override func unsheduleNotification(){
        super.unsheduleNotification()
        
        medicine.notificationTime = nil
        CoreDataHelper.sharedInstance.saveContext(self.context)
    }

    /// Reschedule the pill according to the medicine interval
    /// So, if on monday, 1/1/2014, and interval is 4 days then
    /// it will resheduled to (1 + 4) / 1 / 2014
    public func reshedule(){
        if var nextTime = medicine.notificationTime{
            nextTime += medicine.interval.day
            medicine.notificationTime = nextTime
            
            unsheduleNotification()
            scheduleNotification(nextTime)
            
            return
        }
        
        if medicine.isCurrent{
            Logger.Error("Error: there should be already a fire date")
        }
    }
    
    /// Returns interactive notifications settings to be added in the AppDelegate
    ///
    /// :returns: `UIMutableUserNotificationCategory`: Configuration
    public static func setup() -> UIMutableUserNotificationCategory {
        var notificationActionOk = UIMutableUserNotificationAction()
        notificationActionOk.identifier = TookPillId
        notificationActionOk.title = TookPillTitle
        notificationActionOk.destructive = false
        notificationActionOk.authenticationRequired = false
        notificationActionOk.activationMode = .Background
        
        var notificationActionCancel = UIMutableUserNotificationAction()
        notificationActionCancel.identifier = DidNotTakePillId
        notificationActionCancel.title = DidNotTakePillTitle
        notificationActionCancel.destructive = true
        notificationActionCancel.authenticationRequired = false
        notificationActionCancel.activationMode = .Background
        
        var notificationCategory = UIMutableUserNotificationCategory()
        notificationCategory.identifier = NotificationCategory
        notificationCategory.setActions([notificationActionOk, notificationActionCancel], forContext: .Default)
        notificationCategory.setActions([notificationActionOk, notificationActionCancel], forContext: .Minimal)
        
        return notificationCategory
    }
}