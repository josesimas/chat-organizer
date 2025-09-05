//
//  Query.swift
//  Mgo
//
//  Created by Jose Dias on 15/12/2023.
//

import Foundation

struct GlobalDataLoadModel {
    let path: String
    let loaded: Bool
    let error: String
    let folders: [GroupItem]
    let tags: [GroupItem]
    let conversationCount: Int64
    let inboxCount: Int64
}

struct Query {
    
    public static func loadGlobalDataFromDatabase(path: String, completion: @escaping (GlobalDataLoadModel) -> Void) {
        
        let dm = DatabaseManager(databasePath: path)
        if dm.isReady == false {
            Info.add("Cannot open file " + path)
            completion(GlobalDataLoadModel(path: path, loaded: false, error: "Cannot open file.", folders: [], tags: [], conversationCount: 0, inboxCount: 0))
        }
        
        let folders = dm.getFolderRepo().fetchAllFolders().map { return Mapper.Map(source: $0) }
        let tags = dm.getTagRepo().fetchAllTags().map { return Mapper.Map(source: $0) }
        let count = dm.getConversationRepo().getConversationCount()
        let inboxCount = dm.getConversationRepo().getInboxCount()
        
        completion(GlobalDataLoadModel(path: path, loaded: true, error: "", folders: folders, tags: tags, conversationCount: count, inboxCount: inboxCount))
    }
        
    public static func filterConversations(_ dataModel: DataModel) {
        Task {
            filterConversationsInternal(dataModel.path, 
                                        selectedFolder: dataModel.selectedFolder?.id ?? 0,
                                        selectedTag: dataModel.selectedTag?.id ?? 0,
                                        searchTerm: dataModel.searchTerm,
                                        sortAscending: dataModel.sortAsc, 
                                        OnFinished: { cvs in
                UiThreadHelper.invokeSafely {
                    dataModel.filteredConversations.removeAll()
                    dataModel.filteredConversations.append(contentsOf: cvs)
                    dataModel.selectConversation(index: 0)
                }
            })
        }
        
    }
    
    private static func filterConversationsInternal(_ path: String,
                                            selectedFolder: Int64,
                                            selectedTag: Int64,
                                            searchTerm: String,
                                            sortAscending: Bool,
                                            OnFinished: ([SearchResultConversationViewModel]) -> Void) {
        let dm = DatabaseManager(databasePath: path)
        let cvs = dm.getConversationRepo().fetchConversationsFiltered(filter: searchTerm, folderIdValue: selectedFolder, tagIdValue: selectedTag, sortAscending: sortAscending)
        OnFinished(cvs)
    }
    
    public static func getConversationTags(databasePath: String, conversationId: Int64) -> [GroupItem] {
        var ts: [GroupItem] = []
        let dm = DatabaseManager(databasePath: databasePath)
        for ct in dm.getTagRepo().getConversationTags(conversationId) {
            ts.append(Mapper.Map(source: ct))
        }
        return ts
    }
    
    public static func reloadFolders(_ dataModel: DataModel) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        reloadFoldersInternal(dataModel, dm)
    }
    
    public static func reloadFoldersInternal(_ dataModel: DataModel, _ dm: DatabaseManager) {
        let fr = dm.getFolderRepo()
        let folders = fr.fetchAllFolders()
        let inboxCount = fr.getInboxFolderCount()
        let all = fr.getConversationCount()
        
        UiThreadHelper.invokeSafely {
            dataModel.folders.removeAll()
            dataModel.folders.append(GroupItem(id: 0, name: i18n.string(key: "all.conversations"), path: "/", created: Date(), groupItemCount: all))
            dataModel.folders.append(GroupItem(id: 1, name: i18n.string(key: "inbox.conversations"), path: "/", created: Date(), groupItemCount: inboxCount))
            for c in folders{
                dataModel.folders.append(Mapper.Map(source: c))
            }
        }
    }
    
    public static func conversationHasTags(_ dataModel: DataModel, _ id: Int64) -> Bool {
        let dm = DatabaseManager(databasePath: dataModel.path)
        return dm.getTagRepo().conversationHasTags(id)
    }
    
    public static func reloadTags(_ dataModel: DataModel) {
        dataModel.tags.removeAll()
        let dm = DatabaseManager(databasePath: dataModel.path)
        for c in dm.getTagRepo().fetchAllTags(){
            dataModel.tags.append(Mapper.Map(source: c))
        }
    }
    
    public static func reloadTagsInternal(_ dataModel: DataModel, _ dm: DatabaseManager) {
        let tags = dm.getTagRepo().fetchAllTags()
        UiThreadHelper.invokeSafely {
            dataModel.tags.removeAll()
            for c in tags {
                dataModel.tags.append(Mapper.Map(source: c))
            }
        }
    }
    
    public static func removeTagFromConversation(_ dataModel: DataModel,_ tagId: Int64, _ conversationId: Int64) {
        let dm = DatabaseManager(databasePath: dataModel.path)
        dm.getTagRepo().removeTagFromConversation(tagId, conversationId)
        reloadTagsInternal(dataModel, dm)
    }
    
    public static func getMessages(_ dataModel: DataModel, conversationUuId: String) -> [TextDatePair] {
        let dm = DatabaseManager(databasePath: dataModel.path)
        return dm.getConversationRepo().getConversationAsList(conversationUuid: conversationUuId)
    }
    
    public static func getAssistantName(_ dataModel: DataModel) -> String {
        if let c = dataModel.currentConversation {
            let dm = DatabaseManager(databasePath: dataModel.path)
            return dm.getAssistantName(conversationUuid: c.uuid)
        }
        return ""
    }
}

