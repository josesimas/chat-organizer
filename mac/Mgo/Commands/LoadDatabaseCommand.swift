//
//  LoadDatabaseCommand.swift
//  Mgo
//
//  Created by Jose Dias on 08/01/2024.
//

import Foundation

struct LoadDatabaseCommand {
    
    public static func run(dataModel: DataModel) {        
        _ = BookmarksHelper.accessDbUsingBookmark(key: dataModel.path, loadDatabase: { url in
            run(dataModel: dataModel, url: url)
        })
    }
        
    public static func run(dataModel: DataModel, url: URL) {

        UiThreadHelper.invokeSafely {
            dataModel.isLoading = true
        }
        
        Task {
            Query.loadGlobalDataFromDatabase(path: url.absoluteString, completion: { model in
                if model.loaded {
                    copyGlobalDataToDataModel(model, dataModel)
                } else {
                    UiThreadHelper.invokeSafely {
                        dataModel.hasDatabaseOpen = false
                    }
                }
            })
        }
    }
    
    private static func copyGlobalDataToDataModel(_ model: GlobalDataLoadModel, _ dataModel: DataModel) {
        
        UiThreadHelper.invokeSafely {
            dataModel.clear()
            dataModel.path = model.path
            dataModel.hasDatabaseOpen = true
            dataModel.isDatabaseEmpty = model.conversationCount == 0
            
            
            dataModel.folders.removeAll()
            dataModel.folders.append(GroupItem(id: 0, name: i18n.string(key: "all.conversations"), path: "/", created: Date(), groupItemCount: model.conversationCount))
            dataModel.folders.append(GroupItem(id: 1, name: i18n.string(key: "inbox.conversations"), path: "/", created: Date(), groupItemCount: model.inboxCount))
            dataModel.folders.append(contentsOf: model.folders)
            
            dataModel.tags.removeAll()
            dataModel.tags.append(contentsOf: model.tags)
             
            dataModel.moveCurrentPathToTopOfRecentFiles()
            dataModel.hasDatabaseOpen = true
        }
    }    

}
