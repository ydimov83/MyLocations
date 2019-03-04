//
//  AppDelegate.swift
//  MyLocations
//
//  Created by Yavor Dimov on 2/17/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        
        //loadPersistentStores purpose is to load data from db into memory and creates the Core Data Stack
        container.loadPersistentStores(completionHandler: {
            storeDescription, error in
            if let error = error {
                fatalError("Could not load data store: \(error)")
            }
        })
        return container
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = persistentContainer.viewContext
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let tabController = window!.rootViewController as! UITabBarController
        if let tabViewControllers = tabController.viewControllers {
            //Tag Locations tab, need to pass maangedObjectContext to each tab
            var navController = tabViewControllers[0] as! UINavigationController
            let controler1 = navController.viewControllers.first as! CurrentLocationViewController
            controler1.managedObjectContext = managedObjectContext
            //Locations Tab, need to pass maangedObjectContext to each tab
            navController = tabViewControllers[1] as! UINavigationController
            let controller2 = navController.viewControllers.first as! LocationsViewController
            controller2.managedObjectContext = managedObjectContext
            let _ = controller2.view //Needed to avoid apple bug where tapping on Locations tab immediately after tagging a location fails to show new entry
            
        }
        print(applicationDocumentsDirectory)
        listenForFatalCoreDataNotifications()
        return true
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
    }
    
    //MARK: - Helper Methods
    
    func listenForFatalCoreDataNotifications() {
        //First let NotificationCenter know that we want to be notified whenever a "CoreDataSaveFailedNotification" is encountered
        NotificationCenter.default.addObserver(
            forName: CoreDataSaveFailedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                let message = """
There was a fatal error in the app and it cannot continue.

Press OK to terminate the app.
"""
                let alert = UIAlertController(
                    title: "Internal Error", message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) { _ in
                    let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core Data Error", userInfo: nil)
                    //Creating the NSException object is beneficial for debug since it will write additional data to the crash log when the app terminates
                    exception.raise()
                }
                alert.addAction(action)
                
                let tabController = self.window!.rootViewController as! UITabBarController
                tabController.present(alert, animated: true, completion: nil)
        })
    }
    
}

