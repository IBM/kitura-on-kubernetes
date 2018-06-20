//
//  AppDelegate.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/23/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import CoreData
import HealthKit
import KituraKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // If there is an existing user
        let savedUser = getUserFromLocal()
        if let savedUser = savedUser {
            updateViewController(userId: savedUser.userId!, name: savedUser.name!, image: savedUser.avatar!, fitcoins: 0)
        } else {
            getRandomAvatar(registerUser)
        }
        
        return true
    }
    
    func getRandomAvatar(_ completion: @escaping (_ avatar: AvatarGenerated?) -> Void) {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        client.get("/users/generate") { (avatar: AvatarGenerated?, error: Error?) in
            guard error == nil else {
                print("Error getting random avatar from Kitura: \(error!)")
                return
            }
            guard let avatar = avatar else {
                return
            }
            completion(avatar)
        }
    }
    
    func registerUser(_ avatar: AvatarGenerated?) {
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        client.post("/users", data: avatar) { (user: User?, error: Error?) in
            guard error == nil else {
                print("Error getting registering User to Kitura: \(error!)")
                return
            }
            guard let user = user else {
                return
            }
            self.showAlertWith(title: "Hi, \(user.name)!", message: "You were enrolled and given this random name.", action: UIAlertAction(title: "Cool!", style: UIAlertActionStyle.default, handler: {(_: UIAlertAction) in
                self.updateViewController(userId: user.userId, name: user.name, image: user.image, fitcoins: user.fitcoin)
            }))
            self.persistUserLocal(user)
        }
    }
    
    func showAlertWith(title: String? = nil, message: String? = nil, preferredStyle: UIAlertControllerStyle? = UIAlertControllerStyle.alert, action: UIAlertAction? ...) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle!)
        for action in action {
            alert.addAction(action!)
        }
        DispatchQueue.main.async {
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateViewController(userId: String, name: String, image: Data, fitcoins: Int) {
        for navigationControllers in (self.window?.rootViewController?.childViewControllers)! {
            for viewController in navigationControllers.childViewControllers {
                if viewController is UserViewController {
                    let userVC = viewController as! UserViewController
                    userVC.updateViewWith(userId: userId, name: name, image: image, fitcoins: fitcoins)
                    userVC.currentUser = self.getUserFromLocal()
                    userVC.getCurrentSteps()
                    userVC.startUpdatingSteps()
                }
            }
        }
    }
    
    func getUserFromLocal() -> SavedUser? {
        let managedContext = self.persistentContainer.viewContext
        
        do {
            let result = try managedContext.fetch(SavedUser.fetchRequest())
            print("Number of users: \(result.count)")
            for user in result {
                let user = user as! SavedUser
//                print(user.userId! + " " + user.name!)
//                print(user.startDate)
                return user
            }
        } catch {
            print("Error in core data: Getting User")
            return nil
        }
        return nil
    }
    
    func persistUserLocal(_ user: User) {
        let managedContext = self.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "SavedUser", in: managedContext)!
        let savedUser = NSManagedObject(entity: entity, insertInto: managedContext)
        
        savedUser.setValue(user.name, forKey: "name")
        savedUser.setValue(user.image, forKey: "avatar")
        savedUser.setValue(user.userId, forKey: "userId")
        savedUser.setValue(Date(), forKey: "startDate")
        
        do {
            try managedContext.save()
        } catch {
            print("Error saving user in core data")
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "User")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}

