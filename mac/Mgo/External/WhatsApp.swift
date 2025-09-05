//
//  WhatsApp.swift
//  Mgo
//
//  Created by Jose Dias on 31/05/2024.
//

import Foundation
import Zip
import SQLite

struct WhatsApp {
    
    //Extract all the chat files to a temp folder
    static func extractChatFilesFromZip(sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        do {
            // Create a temporary directory
            let tempDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: sourceURL, create: true)
            
            // Unzip the file to the temporary directory
            try Zip.unzipFile(sourceURL, destination: tempDirectory, overwrite: true, password: nil)
            
            return tempDirectory
        } catch {
            Info.add("extractChatFileFromZip: \(error)")
            return nil
        }
    }
    
    static func importChat(zipPath: URL, tempFolder: URL, databasePath: String) {
        do {
            //create a conversation with the name of the zip file
            let chatName = zipPath.deletingPathExtension().lastPathComponent
            //get the date of the conversation from the first line in the _chat.txt file
            guard let chat = readAllText(atPath: fullPath(for: "/_chat.txt", in: tempFolder.path).path)
            else {
                Info.add("could not read the _chat.txt file")
                return
            }
            let lines = chat.components(separatedBy: .newlines)
            let date = parseDate(from: lines.first ?? Date.now.formatted())?.timeIntervalSince1970 ?? 0
              
            let connection = try Connection(databasePath)
            
            try connection.transaction {
                try connection.execute("PRAGMA journal_mode = MEMORY;")
                //create the conversation in the inbox
                let newId = createWhatsAppConversationInDatabase(connection: connection, name: chatName, uuid: UUID().uuidString, created: date, folder: 0)
                
                //read the chat file and create each message
                for line in lines {
                    createMessageInDatabase(connection: connection, message: createMessageFromLine(conversationId: newId, line: line))
                }
                //store all chat files in the new ChatFiles table as blobs
                
            }
            
            
            
            Info.add("All conversations were successfully created")
        } catch {
            Info.add("importIntoEmptyDatabase failed: \(error)")
        }
    }
    
    static func createMessageFromLine(conversationId: Int64, line: String) -> Message {
        let split = splitMessage(line)
        let date = parseDate(from: split?.date ?? Date.now.formatted())?.timeIntervalSince1970 ?? 0
        
        return Message(id: 0, conversationId: conversationId, messageUuid: UUID().uuidString, created: date, roleId: 1, text: split?.message, assistantDetails: split?.name)
    }
    
    static // Function to split the input string into date and time, name, and message
    func splitMessage(_ inputString: String) -> (date: String, name: String, message: String)? {
        // Define the regex pattern to capture the date and time, name, and message
        let pattern = "\\[(.*?)\\] (.*?): (.*)"

        do {
            // Create a regular expression object with the pattern
            let regex = try NSRegularExpression(pattern: pattern, options: [])

            // Perform a search on the input string
            let matches = regex.matches(in: inputString, range: NSRange(inputString.startIndex..., in: inputString))

            // Check if we found a match
            if let match = matches.first {
                // Extract the date and time part
                if let dateRange = Range(match.range(at: 1), in: inputString),
                   let nameRange = Range(match.range(at: 2), in: inputString),
                   let messageRange = Range(match.range(at: 3), in: inputString) {
                    let datePart = String(inputString[dateRange])
                    let namePart = String(inputString[nameRange])
                    let messagePart = String(inputString[messageRange])
                    return (date: datePart, name: namePart, message: messagePart)
                }
            }
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
        }
        return nil // Return nil if no match is found or if there's an error
    }
    
    static func createMessageInDatabase(connection: Connection, message: Message) {
        let messageTable = Table("Message")
        let conversationId = Expression<Int64>("ConversationId")
        let messageUuid = Expression<String>("MessageUuid")
        let created = Expression<Double>("Created")
        let roleId = Expression<Int64>("RoleId")
        let text = Expression<String?>("Text")
        let assistantDetails = Expression<String?>("AssistantDetails")
        
        do {
            let insert = messageTable.insert(
                conversationId <- conversationId,
                messageUuid <- message.messageUuid,
                created <- message.created,
                roleId <- message.roleId,
                text <- message.text,
                assistantDetails <- message.assistantDetails
            )

            try connection.run(insert)
        } catch {
            Info.add("createMessageInDatabase failed: \(error)")
        }
    }
        
    static func extractDateAsString(inputString: String) -> String? {
        // Define the regex pattern to find the date and time in square brackets
        let pattern = "\\[(.*?)\\]"

        do {
            // Create a regular expression object with the pattern
            let regex = try NSRegularExpression(pattern: pattern, options: [])

            // Perform a search on the input string
            let matches = regex.matches(in: inputString, range: NSRange(inputString.startIndex..., in: inputString))

            // Check if we found a match
            if let match = matches.first {
                // Extract the date and time part
                if let range = Range(match.range(at: 1), in: inputString) {
                    return inputString[range].lowercased()
                }
            }
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
        }
        return nil
    }
    
    static func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()

        // Set the locale to the current system locale
        formatter.locale = Locale.current

        // Prepare the input string by removing square brackets if present
        let cleanedDateString = dateString.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))

        // Determine and set the appropriate date and time format based on system settings
        // Since the format is not predefined, you can experiment with typical date and time styles
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        // Optionally, you can explicitly try to deduce the date format from an example using dateFormat
        // Uncomment and modify the following line if necessary:
        // formatter.dateFormat = "dd/MM/yyyy, HH:mm:ss"

        // Parse the string into a Date object
        return formatter.date(from: cleanedDateString)
    }
    
    static func fullPath(for fileName: String, in folderPath: String) -> URL {
        let folderURL = URL(fileURLWithPath: folderPath)
        return folderURL.appendingPathComponent(fileName)
    }
    
    static func createWhatsAppConversationInDatabase(connection: Connection, name: String, uuid: String, created: Double, folder: Int64) -> Int64 {
        let conversationTable = Table("Conversation")
        let uuid = Expression<String>("Uuid")
        let created = Expression<Double>("Created")
        let updated = Expression<Double?>("Updated")
        let title = Expression<String?>("Title")
        let sourceId = Expression<Int64>("SourceId")
        let folderId = Expression<Int64>("FolderId")

        do {
            let insert = conversationTable.insert(
                uuid <- uuid,
                created <- created,
                updated <- 0,
                title <- name,
                sourceId <- 2, //WhatsApp
                folderId <- folder
            )

            let rowId = try connection.run(insert)
            return Int64(rowId)
        } catch {
            Info.add("createWhatsAppConversationInDatabase failed: \(error)")
            return 0
        }
    }
}

