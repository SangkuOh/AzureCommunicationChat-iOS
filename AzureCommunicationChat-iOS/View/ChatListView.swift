//
//  ChatListView.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/08.
//

import SwiftUI
import AzureCommunicationChat

struct ChatListView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @Binding var isActive: Bool
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Chat List")
                .font(.subheadline)
            
            HStack {
                ScrollView(.horizontal) {
                    ForEach(chatViewModel.chatList.indices, id: \.self) { item in
                        
                        Text(chatViewModel.chatList[item].topic)
                            .font(.title2)
                            .foregroundColor(Color.white)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.blue)
                            )
                            .onTapGesture {
                                chatViewModel.getThreadClient(threadId: chatViewModel.chatList[item].id) { _ in
                                    
                                    chatViewModel.getMessageList { success in
                                        if success {
                                            isActive = true
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

//
//struct ChatListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatListView()
//    }
//}
