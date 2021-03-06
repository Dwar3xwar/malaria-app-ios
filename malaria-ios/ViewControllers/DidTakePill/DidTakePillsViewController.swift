import UIKit
import AVFoundation

/// `DidTakePillsViewController` where the user can track his today's/ weekly medicine
class DidTakePillsViewController: UIViewController {
  @IBOutlet weak var dayOfTheWeekLbl: UILabel!
  @IBOutlet weak var fullDateLbl: UILabel!
  @IBOutlet weak var tookPillBtn: UIButton!
  @IBOutlet weak var didNotTookPillBtn: UIButton!

  @IBInspectable var FullDateTextFormat: String = "M/d/yyyy"
  @IBInspectable var MinorDateTextFormat: String = "EEEE"
  @IBInspectable var MissedWeeklyPillTextColor: UIColor = UIColor.redColor()
  @IBInspectable var SeveralDaysRowMissedEntriesTextColor: UIColor = UIColor.blackColor()
  @IBInspectable var NormalColor: UIColor = UIColor(hex: 0x6F5247)

  private var currentDate: NSDate = NSDate()

  //managers
  private var viewContext: NSManagedObjectContext!
  private var medicineManager: MedicineManager!
  private var registriesManager: RegistriesManager!
  private var medicine: Medicine?
  var pagesManager: PagesManagerViewController!

  //Sound effects
  private let TookPillSoundPath = NSBundle.mainBundle().pathForResource("correct", ofType: "aiff", inDirectory: "Sounds")
  private let DidNotTakePillSoundPath = NSBundle.mainBundle().pathForResource("incorrect", ofType: "aiff", inDirectory: "Sounds")
  private var tookPillPlayer: AVAudioPlayer!
  private var didNotTakePillPlayer: AVAudioPlayer!

  override func viewDidLoad() {
    super.viewDidLoad()

    NSNotificationEvents.ObserveAppBecomeActive(self, selector: #selector(refreshScreen))

    if let tookPillSoundPath = TookPillSoundPath,
      let didNotTakePillSoundPath = DidNotTakePillSoundPath {
        do {
          tookPillPlayer = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: tookPillSoundPath))
          didNotTakePillPlayer = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: didNotTakePillSoundPath))
        } catch _ {
          /* do nothing */
        }
    } else {
      Logger.Error("Error getting sounds effects file paths")
    }
  }

  deinit {
    NSNotificationEvents.UnregisterAll(self)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    refreshScreen()
  }

  private func shouldReset(currentDate: NSDate = NSDate(), interval: Int) -> Bool{
    if let m = medicine {
      if m.interval == 1 {
        Logger.Warn("checkIfShouldReset only valid for weekly pills")
        return false
      }

      //get ellaped days
      if let mostRecent = m.registriesManager.mostRecentEntry() {
        if registriesManager.tookMedicine(mostRecent.date) != nil {
          return (currentDate - (mostRecent.date + interval.day)) >= interval
        }

        return (currentDate - mostRecent.date) >= interval
      }
    }

    Logger.Warn("No medicine configured")
    return false
  }

  private func reset(){
    let (title, message) = (ResheduleNotificationAlertText.title, ResheduleNotificationAlertText.message)
    let resheduleAlert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    resheduleAlert.addAction(UIAlertAction(title: AlertOptions.yes, style: .Default, handler: { _ in
      self.pagesManager.presentSetupScreen()
    }))

    resheduleAlert.addAction(UIAlertAction(title: AlertOptions.no, style: .Default, handler: nil))

    delay(0.85) {
      self.presentViewController(resheduleAlert, animated: true, completion: nil)
    }
  }

  func refreshScreen(){
    Logger.Info("Refreshing TOOK PILL")

    currentDate = NSDate()
    dayOfTheWeekLbl.text = currentDate.formatWith(MinorDateTextFormat)
    fullDateLbl.text = currentDate.formatWith(FullDateTextFormat)

    if !(tookPillPlayer.prepareToPlay() && didNotTakePillPlayer.prepareToPlay()) {
      Logger.Error("Error preparing sounds effects")
    }

    viewContext = CoreDataHelper.sharedInstance.createBackgroundContext()
    medicineManager = MedicineManager(context: viewContext)
    medicine = medicineManager.getCurrentMedicine()
    if medicine == nil {
      return
    }

    registriesManager = medicine!.registriesManager
    let tookMedicineEntry = registriesManager.tookMedicine(currentDate)

    //if took
    if tookMedicineEntry != nil {
      Logger.Info("Took medicine today")
      didNotTookPillBtn.enabled = false
      tookPillBtn.enabled = true

      // stop showing widget
    } else {
      //didn't took because there is no information
      if registriesManager.allRegistriesInPeriod(currentDate).entries.count == 0 {
        Logger.Info("No information")
        didNotTookPillBtn.enabled = true
        tookPillBtn.enabled = true
      } else {
        //or there is and he he didn't took the medicine yet
        //check if he already registered today
        if registriesManager.findRegistry(currentDate) != nil {
          Logger.Info("Didn't took today")
          didNotTookPillBtn.enabled = true
          tookPillBtn.enabled = false
        } else {
          Logger.Info("Hasn't took yet")
          //which means that there are no entries for today, so he still has the opportunity to change that
          didNotTookPillBtn.enabled = true
          tookPillBtn.enabled = true
        }
      }
    }

    if medicine!.interval > 1 {
      if shouldReset(currentDate, interval: medicine!.interval){

        dayOfTheWeekLbl.textColor = SeveralDaysRowMissedEntriesTextColor
        fullDateLbl.textColor = SeveralDaysRowMissedEntriesTextColor

        //reset configuration so that the user can reshedule the time
        reset()
      }else if !currentDate.sameDayAs(medicine!.notificationTime!)
        && currentDate > medicine!.notificationTime!
        && tookMedicineEntry == nil {

          dayOfTheWeekLbl.textColor = MissedWeeklyPillTextColor
          fullDateLbl.textColor = MissedWeeklyPillTextColor
      }else {
        dayOfTheWeekLbl.textColor = NormalColor
        fullDateLbl.textColor = NormalColor
      }
    }
  }
}

///IBActions
extension DidTakePillsViewController {
  @IBAction func didNotTookMedicineBtnHandler(sender: AnyObject) {
    if let m = medicine {
      if (tookPillBtn.enabled && didNotTookPillBtn.enabled && registriesManager.addRegistry(currentDate, tookMedicine: false)){
        didNotTakePillPlayer.play()
        reshedule(m.notificationManager)
        refreshScreen()
      }
    }
  }

  @IBAction func tookMedicineBtnHandler(sender: AnyObject) {
    if let m = medicine {
      if (tookPillBtn.enabled && didNotTookPillBtn.enabled && registriesManager.addRegistry(currentDate, tookMedicine: true)){
        tookPillPlayer.play()
        reshedule(m.notificationManager)
        refreshScreen()
      }
    }
  }

  private func reshedule(notificationManager: MedicineNotificationsManager) {
    if UserSettingsManager.UserSetting.MedicineReminderSwitch.getBool(true){
      notificationManager.reshedule()
    }else {
      Logger.Error("Medicine Notifications are not enabled")
    }
  }
}

extension DidTakePillsViewController: PresentsModalityDelegate {
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    pagesManager.currentViewController = self
  }

  func OnDismiss() {
    refreshScreen()
  }
}

//alert messages
extension DidTakePillsViewController {
  typealias AlertText = (title: String, message: String)

  //existing medicine configured
  private var ResheduleNotificationAlertText: AlertText {get {
    return ("You forgot your medicine for quite a while", "Would you like to change your reminder time?")
    }}

  //type of alerts options
  private var AlertOptions: (yes: String, no: String) {get {
    return ("Yes", "No")
    }}
}