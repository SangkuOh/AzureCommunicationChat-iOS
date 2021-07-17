//
//  ContentView.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/07.
//

import SwiftUI
import AzureCommunicationCommon
import AzureCommunicationChat
import AzureCore


struct ContentView: View {
    @EnvironmentObject var tokenService: TokenService
    @EnvironmentObject var appSetting: AppSettings
    @StateObject var chatViewModel = ChatViewModel()
    @State var displayNmae = ""
    @State var name = ""
    @State var topic = ""
    @State var isList = false
    @State var isChat = false
    
    let chatLogger = ChatLogger.shared
    
    
    var body: some View {
        NavigationView {
            
            VStack(alignment: .leading) {
                
                NavigationLink(destination: ChatRoomView()
                                .environmentObject(chatViewModel),
                               isActive: $isChat) { EmptyView() }
                
                Text("This App use Clipboard to use the other's userId.\nIf you want invite another device,\nyou have to click Ivite Button at first create User.")
                    .font(.caption)
                
                Spacer()
                
                ChatListView(isActive: $isChat)
                    .environmentObject(chatViewModel)
                
                VStack(alignment: .leading) {
                    Text("User: \(chatViewModel.user.name)")
                        .font(.body)
                    
                    
                    TextField("name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        
                        Button {
                            UIPasteboard.general.string = tokenService.userId
                            
                            if let userId = UIPasteboard.general.string {
                                chatLogger.notice(userId)
                            }
                            
                            chatViewModel.user = User(name: name, communicationUserId: tokenService.userId, token: tokenService.token)
                            
                            chatLogger.notice("user: \(chatViewModel.user)")
                            
                            if let clip = UIPasteboard.general.string {
                                chatLogger.notice("clipedText: \(clip)")
                            }
                            name = ""
                            
                        } label: {
                            Text("Create User")
                                .font(.body)
                                .foregroundColor(Color.white)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(Color.green)
                                )
                        }    
                    }
                    
                    TextField("Chat Room topic", text: $topic)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button {
                        chatViewModel.createRoom(topic: topic) { success in
                            if success {
                                isChat = true
                            }
                        }
                    } label: {
                        Text("Create Room")
                            .font(.body)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(chatViewModel.user.name == "" ? Color.gray.opacity(0.1) : Color.blue)
                            )
                    }
                    .disabled(chatViewModel.user.name == "")
                    
                }
                
                Spacer()
                
            }
            .padding()
            .navigationTitle("Simple Chat App")
        }
        .onAppear {
            chatViewModel.getChatList { success in
                if success {
                    topic = ""
                    isList = true
                }
            }
            
            if tokenService.token == "" {
                tokenService.getCommunicationToken { result, _ in
                    tokenService.token = result.token
                    tokenService.userId = result.userId
                    chatViewModel.getChatClient(endpoint: appSetting.tokenEndpoint, token: result.token)
                }
            }
        }
    }
}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
