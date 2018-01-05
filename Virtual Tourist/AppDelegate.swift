//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Niklas Rammerstorfer on 04.01.18.
//  Copyright © 2018 Niklas Rammerstorfer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Constants

    struct UserDefaultsConstants{

        struct MapRegion{
            static let CenterLatitude = "mapRegionCenterLatitude"
            static let CenterLongitude = "mapRegionCenterLongitude"
            static let SpanLatitudeDelta = "mapRegionSpanLatitudeDelta"
            static let SpanLongitudeDelta = "mapRegionSpanLongitudeDelta"
        }
    }

    struct SegueIdentifiers{
        static let PhotoAlbum = "ShowPhotoAlbumScene"
    }

    // MARK: Properties

    let coreDataStack = CoreDataStack(modelName: "Model")!
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

        do {
            try coreDataStack.saveContext()
        } catch {
            print("Error while saving.")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        do {
            try coreDataStack.saveContext()
        } catch {
            print("Error while saving.")
        }
    }
}

