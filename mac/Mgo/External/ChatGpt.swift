//
//  ChatGptJson.swift
//  Mgo
//
//  Created by Jose Dias on 17/12/2023.
//

import Foundation
import Zip
import SQLite

struct ChatGpt {
    
    static func importConversations(conversations: [Conversation], databasePath: String) {
        
        if DatabaseManager.databaseIsEmpty(databasePath: databasePath) {
            Info.add("Empty database, load all conversations and messages")
            importIntoEmptyDatabase(conversations: conversations, databasePath: databasePath)
        }
        else {
            Info.add("Existing database, create new conversations and update existing")
            updateExistingDatabase(conversations: conversations, databasePath: databasePath)
        }
        shrinkDatabase(databasePath: databasePath)
    }
    
    static func shrinkDatabase(databasePath: String) {
        do {
            let connection = try Connection(databasePath)
            try connection.execute("PRAGMA journal_mode = MEMORY;")
            try connection.vacuum()
        } catch {
            Info.add("shrinkDatabase failed: \(error)")
        }
    }
        
    static func importIntoEmptyDatabase(conversations: [Conversation], databasePath: String) {
        do {
            
            let connection = try Connection(databasePath)
            
            try connection.transaction {
                try connection.execute("PRAGMA journal_mode = MEMORY;")
                
                for conversation in conversations {
                    let conversationId = createConversationInDatabase(connection: connection, conversation: conversation, folder: 1)
                    
                    let data = conversation.mapping
                        .filter { $0.value.message != nil }
                        .map { ($0.key, $0.value.parent, $0.value.message!) }
                        .sorted { $0.2.createTime ?? 0 < $1.2.createTime ?? 0 }
                    
                    for (_, _, message) in data {
                        createMessage(connection: connection, conversationId: conversationId, message: message)
                    }
                }
            }
            Info.add("All conversations were successfully created")
        } catch {
            Info.add("importIntoEmptyDatabase failed: \(error)")
        }
    }
    
    static func updateExistingDatabase(conversations: [Conversation], databasePath: String) {
        do {
            let connection = try Connection(databasePath)
            try connection.transaction {
                try connection.execute("PRAGMA journal_mode = MEMORY;")
                
                for conversation in conversations {
                    
                    let conversationId = ConversationRepository.getConversationIdFromUuid(db: connection, uuid: conversation.id)
                    
                    if conversationId > 0 {
                        updateConversation(connection: connection, conversation: conversation, conversationId: conversationId)
                        Info.add("Updated conversation \(conversation.title ?? "")")
                    }
                    else {
                        let conversationId = createConversationInDatabase(connection: connection, conversation: conversation, folder: 1)
                        let data = conversation.mapping
                            .filter { $0.value.message != nil }
                            .map { ($0.key, $0.value.parent, $0.value.message!) }
                            .sorted { $0.2.createTime ?? 0 < $1.2.createTime ?? 0 }
                        
                        for (_, _, message) in data {
                            createMessage(connection: connection, conversationId: conversationId, message: message)
                        }
                        Info.add("Created new conversation \(conversation.title ?? "")")
                    }
                    
                }
            }
            Info.add("All conversations were successfully created")
        } catch {
            Info.add("updateExistingDatabase failed: \(error)")
        }
    }
    
    static func updateConversation(connection: Connection, conversation: Conversation, conversationId: Int64) {
        let data = conversation.mapping
            .filter { $0.value.message != nil }
            .map { ($0.key, $0.value.parent, $0.value.message!) }
            .sorted { $0.2.createTime ?? 0 < $1.2.createTime ?? 0 }
        
        for (_, _, message) in data {
            if DatabaseManager.messageExists(db: connection, uuid: message.id) {
                updateMessage(con: connection, message: message)
            }
            else {
                createMessage(connection: connection, conversationId: conversationId, message: message)
            }
        }
    }
    
    static func createMessage(connection: Connection, conversationId: Int64, message: Message) {
        let role = message.author?.role ?? ""
        switch role {
        case "system":
            createMessage(con: connection, pConversationId: conversationId, roleId: 1, message: message)
        case "user":
            createMessage(con: connection, pConversationId: conversationId, roleId: 2, message: message)
        case "assistant":
            createMessage(con: connection, pConversationId: conversationId, roleId: 3, message: message)
        case "tool":
            createMessage(con: connection, pConversationId: conversationId, roleId: 4, message: message)
        default:
            Info.add("Unknown role \(message.author?.role ?? "(message is nil) - saving it as system for now")")
            createMessage(con: connection, pConversationId: conversationId, roleId: 1, message: message)
        }
    }
    
    static func createMessage(con: Connection, pConversationId: Int64, roleId: Int64, message: Message) {
        let insertStatement = "INSERT INTO Message (ConversationId, MessageUuid, Created, RoleId, Text, AssistantDetails) VALUES (?, ?, ?, ?, ?, ?)"
        do {
            let stmt = try con.prepare(insertStatement)
            
            if message.content is Content {
                let ct = message.content as! Content
                guard let parts = ct.parts else { return }
                
                for part in parts {
                    switch part {
                    case let stringPart as StringPart:
                        let str = addCitationsIfPresent(message: message, text: stringPart.value)
                        try stmt.run(pConversationId, message.id, message.createTime ?? 0, roleId, str, message.metadata?.modelSlug ?? "")
                        case let objectPart as ImageAsset:
                            switch objectPart.contentType {
                            case "image_asset_pointer":
                                let text = "\(objectPart.metadata.dalle.serializationTitle): \(objectPart.metadata.dalle.prompt)\nSeed \(objectPart.metadata.dalle.seed)"
                                try stmt.run(pConversationId, message.id, message.createTime ?? 0, roleId, text, message.metadata?.modelSlug ?? "")
                            default:
                                let str = addCitationsIfPresent(message: message, text: objectPart.contentType)
                                try stmt.run(pConversationId, message.id, message.createTime ?? 0, roleId, str, message.metadata?.modelSlug ?? "")
                            }
                    default:
                        Info.add("Unknown part type")
                    }
                }
            }
            else {
                if message.content == nil {
                    Info.add("Nil content message: \(message.id)")
                }
                else {
                    if message.content is CodeContent {
                        let ct = message.content as! CodeContent
                        if ct.text != "\n<<ImageDisplayed>>" {
                            try stmt.run(pConversationId, message.id, message.createTime ?? 0, roleId, "```\n\(ct.text ?? "")\n```", message.metadata?.modelSlug ?? "")
                        }
                    }
                    else if message.content is CustomGptContent {
                        let ct = message.content as! CustomGptContent
                        try stmt.run(pConversationId, message.id, message.createTime ?? 0, roleId, "```\n\(ct.result ?? "")\n```", message.metadata?.modelSlug ?? "")
                    }
                }
            }
        } catch {
            Info.add("createMessage error: \(error)")
        }
    }
    
    static func updateMessage(con: Connection, message: Message) {
        let statement = "UPDATE Message SET Created = ?, Text = ?, AssistantDetails = ? WHERE MessageUuId = ?"
        do {
            let stmt = try con.prepare(statement)
            
            if message.content is Content {
                let ct = message.content as! Content
                guard let parts = ct.parts else { return }
                for part in parts {
                    switch part {
                    case let stringPart as StringPart:
                        let str = addCitationsIfPresent(message: message, text: stringPart.value)
                        try stmt.run(message.createTime ?? 0, str, message.metadata?.modelSlug ?? "", message.id)
                        
                    case let objectPart as ImageAsset:
                        let str = addCitationsIfPresent(message: message, text: objectPart.contentType)
                        try stmt.run(message.createTime ?? 0, str, message.metadata?.modelSlug ?? "", message.id)
                    default:
                        Info.add("Unknown part type")
                    }
                }
            } else {
                if message.content == nil {
                    Info.add("Nil content message: \(message.id)")
                }
                else {
                    if message.content is CodeContent {
                        let ct = message.content as! CodeContent
                        if ct.text != "\n<<ImageDisplayed>>" {
                            try stmt.run(message.createTime ?? 0, "```\n\(ct.text ?? "")\n```", message.metadata?.modelSlug ?? "", message.id)
                        }
                    }
                    else if message.content is CustomGptContent {
                        let ct = message.content as! CustomGptContent
                        try stmt.run(message.createTime ?? 0, "```\n\(ct.result ?? "")\n```", message.metadata?.modelSlug ?? "", message.id)
                    }
                    
                }
            }
            
            
        } catch {
            Info.add("Insertion error: \(error)")
        }
    }
    
    static func addCitationsIfPresent(message: Message, text: String) -> String {
        if message.metadata == nil {
            return text
        }
        if message.metadata?.citations == nil {
            return text
        }
        //citations exist, add them to the end of the text
        guard let cts = message.metadata?.citations else { return text }
        var ctsText = [String]()
        for citation in cts {
            guard let metadata = citation.metadata else { continue }
            guard let extra = metadata.extra else { continue }
            let txt = "\(extra.citedMessageIdx): [\(metadata.title ?? "Source Title")](\(metadata.url ?? "No Url")"
            ctsText.append("\(txt)\n")
        }
        return "\(text)\n\n\(ctsText.joined(separator: "\n"))"
    }
            
    static func createConversationInDatabase(connection: Connection, conversation: Conversation, folder: Int64) -> Int64 {
        let conversationTable = Table("Conversation")
        let uuid = Expression<String>("Uuid")
        let created = Expression<Double>("Created")
        let updated = Expression<Double?>("Updated")
        let title = Expression<String?>("Title")
        let sourceId = Expression<Int64>("SourceId")
        let folderId = Expression<Int64>("FolderId")

        do {
            let insert = conversationTable.insert(
                uuid <- conversation.id,
                created <- conversation.createTime,
                updated <- (conversation.updateTime ?? 0),
                title <- (conversation.title ?? ""),
                sourceId <- 1,
                folderId <- folder
            )

            let rowId = try connection.run(insert)
            return Int64(rowId)
        } catch {
            Info.add("createConversationInDatabase failed: \(error)")
            return 0
        }
    }

    static func extractJsonFileFromZip(sourceURL: URL) -> String? {
        let fileManager = FileManager.default
        do {
            // Create a temporary directory
            let tempDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: sourceURL, create: true)
            
            // Unzip the file to the temporary directory
            try Zip.unzipFile(sourceURL, destination: tempDirectory, overwrite: true, password: nil)
            
            // Locate the conversations.json file in the temporary directory
            let jsonFileURL = tempDirectory.appendingPathComponent("conversations.json")
            
            // Check if the file exists
            guard fileManager.fileExists(atPath: jsonFileURL.path) else {
                throw NSError(domain: "com.gepsoft.app", code: 100, userInfo: [NSLocalizedDescriptionKey: "conversations.json not found in the zip archive"])
            }
            
            // Read the contents of the file
            let contents = try String(contentsOf: jsonFileURL, encoding: .utf8)
            
            // Cleanup: Delete the temporary directory
            try fileManager.removeItem(at: tempDirectory)

            // Return the contents
            return contents
        } catch {
            Info.add("extractJsonFileFromZip: \(error)")
            return nil
        }
    }
    
    static func readJsonFile(sourceURL: URL) -> String? {
            let fileManager = FileManager.default
            do {
                // Check if the file exists
                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    throw NSError(domain: "com.gepsoft.app", code: 100, userInfo: [NSLocalizedDescriptionKey: "json not found"])
                }
                
                // Read the contents of the file
                let contents = try String(contentsOf: sourceURL, encoding: .utf8)
                
                // Return the contents
                return contents
            } catch {
                Info.add("Error: \(error)")
                return nil
            }
        }

    static func loadJson(from jsonString: String) -> [Conversation] {
        let decoder = JSONDecoder()
        guard let data = jsonString.data(using: .utf8) else {
            Info.add("Error: Cannot convert string to Data")
            return []
        }

        do {
            let conversations = try decoder.decode([Conversation].self, from: data)
            return conversations.sorted { $0.createTime > $1.createTime }
        } catch {
            Info.add("Failed to decode data from string: \(error)")
            return []
        }
    }
    
  struct Conversation: Decodable {
        var conversationId: String
        var conversationTemplateId: String?
        var createTime: Double
        var currentNode: String?
        var gizmoId: String?
        var id: String
        var mapping: [String: Node]
        var moderationResults: [String]
        var pluginIds: String?
        var title: String?
        var updateTime: Double?

        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case conversationTemplateId = "conversation_template_id"
            case createTime = "create_time"
            case currentNode = "current_node"
            case gizmoId = "gizmo_id"
            case id
            case mapping
            case moderationResults = "moderation_results"
            case pluginIds = "plugin_ids"
            case title
            case updateTime = "update_time"
        }
    }
    
    struct Node: Decodable {
        var children: [String]
        var id: String
        var message: Message?
        var parent: String?

        enum CodingKeys: String, CodingKey {
            case children
            case id
            case message
            case parent
        }
    }

    struct Message: Decodable {
        var author: Author?
        var content: ContentProtocol?
        var createTime: Double?
        var endTurn: Bool?
        var id: String
        var metadata: Metadata?
        var recipient: String?
        var status: String?
        var updateTime: Double?
        var weight: Double?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            author = try container.decodeIfPresent(Author.self, forKey: .author)
            createTime = try container.decodeIfPresent(Double.self, forKey: .createTime)
            endTurn = try container.decodeIfPresent(Bool.self, forKey: .endTurn)
            id = try container.decode(String.self, forKey: .id)
            metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata)
            recipient = try container.decodeIfPresent(String.self, forKey: .recipient)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            updateTime = try container.decodeIfPresent(Double.self, forKey: .updateTime)
            weight = try container.decodeIfPresent(Double.self, forKey: .weight)
            
            content = try container.decodeIfPresent(Content.self, forKey: .content)
            let ct = content as! Content
            if ct.parts == nil {
                content = try container.decodeIfPresent(CodeContent.self, forKey: .content)
                
                let cct = content as! CodeContent
                if cct.text ==  nil {
                    content = try container.decodeIfPresent(CustomGptContent.self, forKey: .content)
                }
            }
        }

        enum CodingKeys: String, CodingKey {
            case author
            case content
            case createTime = "create_time"
            case endTurn = "end_turn"
            case id
            case metadata
            case recipient
            case status
            case updateTime = "update_time"
            case weight
        }
    }


    struct Author: Codable {
        var metadata: Metadata?
        var name: String?
        var role: String?

        enum CodingKeys: String, CodingKey {
            case metadata
            case name
            case role
        }
    }
    
    struct Metadata: Codable {
        var finishDetails: FinishDetails?
        var messageType: String?
        var modelSlug: String?
        var timestamp: String?
        var citations: [Citation]?

        enum CodingKeys: String, CodingKey {
            case finishDetails = "finish_details"
            case messageType = "message_type"
            case modelSlug = "model_slug"
            case timestamp, citations
        }
    }
    
    struct Citation: Codable {
        let startIx: Int?
        let endIx: Int?
        let citationFormatType: String?
        let metadata: CitationMetadata?

        enum CodingKeys: String, CodingKey {
            case startIx = "start_ix"
            case endIx = "end_ix"
            case citationFormatType = "citation_format_type"
            case metadata
        }
    }
    
    struct CitationMetadata: Codable {
        let type: String?
        let title: String?
        let url: String?
        let text: String?
        let pubDate: String?
        let extra: Extra?

        enum CodingKeys: String, CodingKey {
            case type, title, url, text
            case pubDate = "pub_date"
            case extra
        }
    }

    struct Extra: Codable {
        let citedMessageIdx: Int
        let evidenceText: String?

        enum CodingKeys: String, CodingKey {
            case citedMessageIdx = "cited_message_idx"
            case evidenceText = "evidence_text"
        }
    }

    struct FinishDetails: Codable {
        var stop: String?
        var type: String?

        enum CodingKeys: String, CodingKey {
            case stop
            case type
        }
    }
    
    // Struct for string parts
    struct StringPart: PartProtocol {
        let value: String
    }
    
    struct CodeContent : Decodable, ContentProtocol {
        let contentType: String
        let language: String?
        let text: String?

        enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case language, text
        }
    }
    
    struct CustomGptContent : Decodable, ContentProtocol {
        let contentType: String
        let result: String?
        let summary: String?
        let assets: [String]?
        
        enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case result, summary, assets
        }
    }

    struct Content: Decodable, ContentProtocol {
        var contentType: String?
        var parts: [PartProtocol]?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            contentType = try container.decodeIfPresent(String.self, forKey: .contentType)

            var partsContainer = try? container.nestedUnkeyedContainer(forKey: .parts)
            var partsArray = [PartProtocol]()

            while let _ = partsContainer, !partsContainer!.isAtEnd {
                if let partString = try? partsContainer!.decode(String.self) {
                    let stringPart = StringPart(value: partString)
                    partsArray.append(stringPart)
                } else if let imagePart = try? partsContainer!.decode(ImageAsset.self) {
                    partsArray.append(imagePart)
                } else {
                    // Advance to the next element to avoid an infinite loop
                    _ = try? partsContainer!.decode(DummyCodable.self)
                }
            }

            parts = partsArray.isEmpty ? nil : partsArray
        }

        enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case parts
        }
    }

    // Dummy codable to consume an element in case of a decoding failure
    struct DummyCodable: Decodable {}

    struct ImageAsset: Codable, PartProtocol {
        let contentType: String
        let assetPointer: String
        let sizeBytes: Int
        let width: Int
        let height: Int
        let fovea: Int
        let metadata: Metadata1

        enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case assetPointer = "asset_pointer"
            case sizeBytes = "size_bytes"
            case width, height, fovea, metadata
        }
    }
    
    struct Metadata1: Codable {
        let dalle: Dalle
    }

    struct Dalle: Codable {
        let genID: String
        let prompt: String
        let seed: Int
        let serializationTitle: String

        enum CodingKeys: String, CodingKey {
            case genID = "gen_id"
            case prompt, seed
            case serializationTitle = "serialization_title"
        }
    }

}

// Protocol for parts
protocol PartProtocol: Decodable {}
protocol ContentProtocol: Decodable { }
