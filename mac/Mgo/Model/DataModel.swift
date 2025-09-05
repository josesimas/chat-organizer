//
//  DataModel.swift
//  Mgo
//
//  Created by Jose Dias on 06/12/2023.
//

import Foundation
import Combine

class DataModel: ObservableObject {
    //this variable is not cleared and is used to detect that nothing has been loaded so far
    @Published var hasDatabaseOpen: Bool = false
    @Published var isDatabaseEmpty: Bool = false
    //Menu
    @Published var isLoading: Bool = false
    @Published var recentFiles: [String] = []
    
    //files
    @Published var path: String = ""
    
    //General
    @Published var searchTerm: String = ""
    private var cancellable: AnyCancellable?
        
    @Published var folders: [GroupItem] = []
    @Published var tags: [GroupItem] = []
    @Published var selectedFolder: GroupItem? = nil
    @Published var selectedTag: GroupItem? = nil
    
    //main screen
    @Published var filteredConversations: [SearchResultConversationViewModel] = []
        
    //startup guard to avoid too many filterings
    private var lastChangedSearchTerm: String = ""
    private var loadingModelAtStartup: Bool = true
    
    //show/hide a conversation
    @Published var currentConversation: Conversation? = nil {
        didSet {
            if let c = currentConversation {
                self.messages = Query.getMessages(self, conversationUuId: c.uuid).filter { $0.text != "" }.map({ MessageViewModel.fromTextDatePair(tdp: $0) })
                for index in messages.indices {
                    messages[index].changed = false
                }
            }
            else {
                self.messages = []
            }
        }
    }
    @Published var lastSelectedConversationId: Int64 = 0
    
    @Published var messages: [MessageViewModel] = []
    
    //sort
    var sortAsc: Bool = true
    
    @Published var showToolsAndSystem: Bool = false
    
    init() {
        if UserDefaults.standard.object(forKey: "list.sort.asc") != nil {
                // Key exists in UserDefaults, fetch its value
                sortAsc = UserDefaults.standard.bool(forKey: "list.sort.asc")
            } else {
                // Key does not exist, use the default value (true)
                sortAsc = true
            }
        
        cancellable = $searchTerm
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main) // optional debounce
            .sink { [weak self] searchTerm in
                guard let dm = self else {
                    return
                }
                if dm.loadingModelAtStartup {
                    dm.loadingModelAtStartup = false
                    Query.filterConversations(dm)
                    return
                }
                if dm.lastChangedSearchTerm != searchTerm {
                    Query.filterConversations(dm)
                     dm.lastChangedSearchTerm = searchTerm
                }
            }
    }
    
    var DatabaseName: String {
        get {
            if path == "" {
                return ""
            }
            let fileURL = URL(fileURLWithPath: path)
            return fileURL.lastPathComponent
        }
    }
    
    var AppTitle: String {
        get {
            if path == "" {
                return ""
            }
            let fileURL = URL(fileURLWithPath: path)
            let fileNameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
            return fileNameWithoutExtension.removingPercentEncoding ?? fileNameWithoutExtension
        }
    }
    
    var canEditSelectedFolder: Bool {
        get {
            if selectedFolder == nil {
                return false
            }
            return selectedFolder?.id ?? 0 > 1
        }
    }
    
    func selectConversation(index: Int) {
        if index < filteredConversations.count {
            currentConversation = filteredConversations[index].conversation
        }
    }
    
    func toggleConversationSort() {
        
        sortAsc = !sortAsc
        
        if sortAsc {
            filteredConversations.sort { $0.created < $1.created }
        }
        else {
            filteredConversations.sort { $0.created > $1.created }
        }
        UserDefaults.standard.setValue(sortAsc, forKey: "list.sort.asc")
    }
    
    func currentConversationHasTags() -> Bool {
        if currentConversation == nil {
            return false
        }
        let tags = Query.getConversationTags(databasePath: path, conversationId: currentConversation!.id)
        return tags.count > 0
    }
    
    func clear() {
        isLoading = false
        path = ""
        searchTerm = ""
        folders.removeAll()
        tags.removeAll()
        selectedFolder = nil
        selectedTag = nil
        filteredConversations = []
        lastChangedSearchTerm = ""
        loadingModelAtStartup = true
        currentConversation = nil
        lastSelectedConversationId = 0
    }
    
    public func moveCurrentPathToTopOfRecentFiles() {
        if recentFiles.contains(path) {
            recentFiles.removeAll { $0 == path }
        }
        recentFiles.insert(path, at: 0)
        saveRecentFiles()
    }
    
    private func saveRecentFiles() {
        do {
            if recentFiles.count > 4 {
                UserDefaults.standard.removeObject(forKey: BookmarksHelper.createKey(recentFiles[0]))
                recentFiles.remove(at: recentFiles.count - 1)
            }
            
            let jsonData = try JSONEncoder().encode(recentFiles)
            let jsonString = String(data: jsonData, encoding: .utf8)
            UserDefaults.standard.set(jsonString, forKey: "RecentFiles")
        } catch {
            Info.add("Failed to encode recent files: \(error)")
        }
    }
    
}
