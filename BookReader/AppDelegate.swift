//
//  AppDelegate.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let documentDirectoryDidChange = Notification.Name("documentDirectoryDidChange")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let sampleFilename = "Sample.pdf"
        if let sampleFile = Bundle.main.url(forResource: sampleFilename, withExtension: nil) {
            let destination = documentDirectory.appendingPathComponent(sampleFilename)
            if !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: sampleFile, to: destination)
            }
        }
        if let launchOptions = launchOptions, let url = launchOptions[.url] as? URL {
            let destination = documentDirectory.appendingPathComponent(url.lastPathComponent)
            if !fileManager.fileExists(atPath: destination.path) {
                try? fileManager.copyItem(at: url, to: destination)
                NotificationCenter.default.post(name: .documentDirectoryDidChange, object: nil)
            }
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documentDirectory.appendingPathComponent(url.lastPathComponent)
        if !fileManager.fileExists(atPath: destination.path) {
            try? fileManager.copyItem(at: url, to: destination)
            NotificationCenter.default.post(name: .documentDirectoryDidChange, object: nil)
        }
        return true
    }
}
