//
//  FileHelpers.swift
//  Mgo
//
//  Created by Jose Dias on 05/12/2023.
//

import Foundation

func getFileExtension()-> String {
    return "cor"
}

func getAppName()-> String {
    return "Chat Organizer"
}

func fileExists(atPath path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func readAllText(atPath path: String) -> String? {
    do {
        let contents = try String(contentsOfFile: path, encoding: .utf8)
        return contents
    } catch {
        Info.add("Error reading file: \(error)")
        return nil
    }
}

func readAllTextData(atPath path: String) -> Data? {
    do {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return data
    } catch {
        Info.add("Error reading file: \(error)")
        return nil
    }
}

func copyDatabaseIfNeeded(forceNew: Bool) -> String? {
    guard let containerURL = getApplicationSupportDirectory() else {
        Info.add("Error finding application support directory")
        return nil
    }

    let fileManager = FileManager.default
    let dbPath = containerURL.appendingPathComponent("pm.db")
    
    if forceNew && fileManager.fileExists(atPath: dbPath.path) {
        do {
            try fileManager.removeItem(atPath: dbPath.path)
        } catch {
            Info.add("Error deleting existing database: \(error)")
            return nil
        }
    }
    
    if !fileManager.fileExists(atPath: dbPath.path) {
        // File does not exist, copy from bundle
        if let bundlePath = Bundle.main.path(forResource: "pm", ofType: "db") {
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: dbPath.path)
            } catch {
                Info.add("Error copying database: \(error)")
                return nil
            }
        } else {
            Info.add("Error: pm.db not found in the bundle")
            return nil
        }
    }

    return dbPath.path
}

func getApplicationSupportDirectory() -> URL? {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)

    guard let appSupportDir = urls.first else { return nil }
    let appDirectory = appSupportDir.appendingPathComponent(i18n.appName, isDirectory: true)

    if !fileManager.fileExists(atPath: appDirectory.path) {
        do {
            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Info.add("Error creating app directory: \(error)")
            return nil
        }
    }

    return appDirectory
}

