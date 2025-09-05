//
//  SidebarItem.swift
//  Mgo
//
//  Created by Jose Dias on 04/12/2023.
//

import SwiftUI

struct SidebarSectionListView: View {
    @Binding var groups: [GroupItem]
    @Binding var selectedGroup: GroupItem?
    var onTap: (_ group: GroupItem) -> Void
    var onAddToFolder: (_ conversationIds: [Int64], _ folderId: Int64) -> Void
    var onEdit: (_ group: GroupItem) -> Void
    var onAddSubFolder: (_ group: GroupItem) -> Void
    var onMoveToRootFolder: (_ group: GroupItem) -> Void
    var onDelete: (_ group: GroupItem) -> Void
    var minIdForEditing: Int64
    var hasSubItems: Bool = false
    
    @EnvironmentObject var dataModel: DataModel
    @State private var isTargetHovered = false
    @State private var showContextMenu = true
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(groups) { c in
                    HStack {
                        if hasSubItems {
                            HStack {
                                Image(systemName: c.icon)
                                    .foregroundColor(.accentColor)
                                Text(c.name)
                                    .font(.system(size: 16))
                            }
                            .padding(.leading, c.depth)
                            
                        }
                        else {
                            Text(c.name)
                                .font(.system(size: 16))
                        }
                        Spacer()
                        if c.groupItemCount > 0 {
                            Circle()
                                .fill(Color.white) // Fill the circle with a white background
                                .frame(width: 35, height: 35) // Set the size of the circle
                                .overlay(
                                    Text(String(c.groupItemCount)) // Place the number as text on top of the circle
                                        .font(.system(size: 10)) // Set the font size to 10
                                        .foregroundColor(.black) // Set the text color
                                )
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle()) // Ensure the tap area includes the whole frame
                    .background(c.id == selectedGroup?.id ? Color.gray.opacity(0.15) : Color.clear)
                    .cornerRadius(5)
                    .onTapGesture {
                        self.onTap(c)
                    }
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .onDrag({
                        return NSItemProvider(object: String("FOLDER\n\(c.id)\n\(c.name)") as NSString)
                    })
                    .onDrop(of: [.text], isTargeted: $isTargetHovered) { providers in
                        providers.first?.loadObject(ofClass: NSString.self) { string, error in
                            if let conversations = string as? String {
                                if conversations.contains(",") {
                                    let ids = conversations.components(separatedBy: ",").compactMap { Int64($0) }
                                    onAddToFolder(ids, c.id)
                                }
                                else {
                                    if let number = Int64(conversations) {
                                        let int64Array = [number]
                                        onAddToFolder(int64Array, c.id)
                                    }
                                    else {
                                        if let folder = string as? String {
                                            if folder.hasPrefix("FOLDER\n") {
                                                let arr = folder.components(separatedBy: "\n")
                                                Command.moveFolder(dataModel, from: Int64(arr[1]) ?? 0, to:c.id)
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        return true
                    }
                    .if(c.id > minIdForEditing) { view in
                        view.contextMenu {
                            Button(action: {
                                onEdit(c)
                            }) {
                                Text("Rename...")
                            }
                            if hasSubItems {
                                Divider()
                                Button(action: {
                                    onAddSubFolder(c)
                                }) {
                                    Text("Add sub folder...")
                                }
                                Button(action: {
                                    onMoveToRootFolder(c)
                                }) {
                                    Text("Move to root")
                                }
                            }
                            Divider()
                            Button(action: {
                                onDelete(c)
                            }) {
                                Text("Delete...")
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 250)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
    }
}


