//
//  AppDelegate.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import TabView
import ios_system
import ObjectUserDefaults
import StoreKit

/// A Tab View theme that adapts to the system appearance.
@available(iOS 13.0, *) class DefaultTheme: TabViewTheme {
    
    var backgroundColor: UIColor {
        return .systemFill
    }
    
    var barTitleColor: UIColor {
        return .label
    }
    
    var barTintColor: UIColor {
        return .systemFill
    }
    
    var barBlurStyle: UIBlurEffect.Style {
        return .systemChromeMaterial
    }
    
    var separatorColor: UIColor {
        return .separator
    }
    
    var tabCloseButtonColor: UIColor {
        return TabViewThemeLight().tabCloseButtonColor
    }
    
    var tabCloseButtonBackgroundColor: UIColor {
        return TabViewThemeLight().tabCloseButtonBackgroundColor
    }
    
    var tabBackgroundDeselectedColor: UIColor {
        return TabViewThemeLight().tabBackgroundDeselectedColor
    }
    
    var tabTextColor: UIColor {
        return .label
    }
    
    var tabSelectedTextColor: UIColor {
        return .label
    }
    
    var statusBarStyle: UIStatusBarStyle {
        return .default
    }
}

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if #available(iOS 13.0, *) {
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            let tabVC = TerminalTabViewController(theme: TabViewThemeLight())
            tabVC.viewControllers = [LTTerminalViewController.makeTerminal()]
            window?.rootViewController = tabVC
            window?.makeKeyAndVisible()
        }
        
        sideLoading = true
        
        // Clang
        if !FileManager.default.fileExists(atPath: FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("usr").path) {
            try? FileManager.default.removeItem(at: FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("usr"))
        }
        ios_switchSession(stdout)
        ios_system("tar -zxvf \(Bundle.main.path(forResource: "usr", ofType: "tar.gz") ?? "") -C ~/Library/")
        
        let usrURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("usr")
        
        putenv("SDKPATH=\(Bundle.main.path(forResource: "iPhoneOS", ofType: "sdk") ?? "")".cValue)
        putenv("C_INCLUDE_PATH=\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
        //putenv("OBJC_INCLUDE_PATH=\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
        putenv("CPLUS_INCLUDE_PATH=\(usrURL.appendingPathComponent("include/c++/v1")):\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
        //putenv("OBJCPLUS_INCLUDE_PATH=\(usrURL.appendingPathComponent("include/c++/v1")):\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
        ios_closeSession(stdout)
        
        initializeEnvironment()
                
        replaceCommand("pbcopy", "pbcopy_main", true)
        replaceCommand("pbpaste", "pbpaste_main", true)
        replaceCommand("id", "id_main", true)
        
        // Python
        putenv("PYTHONOPTIMIZE=".cValue)
        putenv("PYTHONDONTWRITEBYTECODE=1".cValue)
        
        // cacert.pem
        let cacertNewURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("cacert.pem")
        if let cacertURL = Bundle.main.url(forResource: "cacert", withExtension: "pem"), !FileManager.default.fileExists(atPath: cacertNewURL.path) {
            try? FileManager.default.copyItem(at: cacertURL, to: cacertNewURL)
        }
        
        if let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("bin"), let oldScriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("scripts"), FileManager.default.fileExists(atPath: oldScriptsDirectory.path), !FileManager.default.fileExists(atPath: scriptsDirectory.path) {
            try? FileManager.default.moveItem(at: oldScriptsDirectory, to: scriptsDirectory)
        }
        
        // The directory where scripts goes
        if let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("bin"), !FileManager.default.fileExists(atPath: scriptsDirectory.path) {
            try? FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        // Colors
        putenv("TERM=ansi".cValue)
        
        window?.accessibilityIgnoresInvertColors = true
        
        if SettingsTableViewController.fontSize.integerValue == 0 {
            SettingsTableViewController.fontSize.integerValue = 14
        }
        
        // Request app review
        ReviewHelper.shared.launches += 1
        ReviewHelper.shared.requestReview()
        
        return true
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}

