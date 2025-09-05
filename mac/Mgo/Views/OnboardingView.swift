//
//  OnboardingView.swift
//  Mgo
//
//  Created by Jose Dias on 26/12/2023.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dataModel: DataModel
    
    let frameWidth: Double = 250
    
    @State private var zoomIn: Bool = false
    @State private var zoomInImage: String = ""
        
    var body: some View {
        VStack(alignment: .center) {
            Text("Getting started")
                .font(.system(size: 26))
                .padding(.top, 25)
                .padding(.bottom, 25)
            
            HStack {
                itemView("In OpenAI's chat page select Settings & Beta under your name", "Onboarding01")
                itemView("On the next screen select Data controls and press the Export button", "Onboarding02")
                itemView("Confirm the data export", "Onboarding03")
                itemView("Check your email for a link to your data and download it to your computer. It is a ZIP file.", "Onboarding04")
            }
            .padding(10)
            
            Divider()
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .padding(.bottom, 30)
            
            VStack
            {
                if dataModel.hasDatabaseOpen {
                    
                    Text("Now you are ready to import the OpenAI conversations. Press the button below or select the menu Import-Conversations from OpenAI...")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16))
                    Button(action: {
                        UiThreadHelper.invokeSafely {
                                ImportChatGptCommand.run(dataModel: dataModel, onFinish: {path in
                                    UiThreadHelper.invokeSafely {
                                        LoadDatabaseCommand.run(dataModel: dataModel)
                                    }
                            })
                        }
                        
                    }) {
                        Text("Import from the downloaded zip file...")
                            .font(.system(size: 14))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                                        
                    Text("When you have more conversations you can repeat the process with your mgo file to update the existing conversations and add new ones.")
                        .font(.system(size: 12))
                        .padding()
                    
                } else {
                    Text("After downloading your data from OpenAI click the button below to\nchoose where all your conversations will be saved (or select the File-New menu).")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16))
                    Button(action: {
                        NewDatabaseCommand.run(onFinish: { url in
                            LoadDatabaseCommand.run(dataModel: dataModel, url: url)
                        })
                    }) {
                        Text("New file...")
                            .font(.system(size: 14))
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
            }
        }
        .sheet(isPresented: $zoomIn) {
            ImageSheetView(title: "", showModal: $zoomIn, resourceName: $zoomInImage)
        }
    }
    
    func itemView(_ text: String, _ imageResource: String, _ btnNewFile: Bool = false) -> some View {
        VStack() {
            Text(text)
                .frame(width: frameWidth) // Set the width for wrapping
                .multilineTextAlignment(.leading) // Align the text
                .font(.system(size: 16))
                                    
            if !imageResource.isEmpty {
                Image(imageResource)
                    .resizable()  // Makes the image resizable
                    .aspectRatio(contentMode: .fit) // Maintains the aspect ratio
                    .frame(width: frameWidth)
                    .shadow(radius: 3)
                    .onTapGesture {
                        self.zoomInImage = imageResource
                        self.zoomIn = true
                    }
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .padding(5)
            }
            Spacer()
        }
    }
}


