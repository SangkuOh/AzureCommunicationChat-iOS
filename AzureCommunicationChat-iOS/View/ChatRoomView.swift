//
//  ChatRoomView.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/08.
//

import SwiftUI
import AzureCommunicationCommon
import AzureCommunicationChat
import AzureCore
import struct Kingfisher.KFImage

struct ChatRoomView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State var messages = ""
    @State private var isShowPhotoLibrary = false
    @State private var imageUrl: URL? = nil
    private let dateFormatter = ISO8601DateFormatter()
    private let bottom = "bottom"
    
    func ChatListView() -> some View {
        let reversedList: [ChatMessage] = viewModel.pageItems.reversed()
        
        return ScrollViewReader { proxy in
            ScrollView {
                
                LazyVStack {
                ForEach(reversedList.indices, id: \.self) { index in
                    
                    if reversedList[index].type == .participantAdded {
                        
                        Text("Participant Added")
                            .id(reversedList[index].id)
                        
                    } else {
                        HStack {
                            
                            if reversedList[index].senderDisplayName == viewModel.user.name { Spacer() }
                            
                            VStack(alignment: reversedList[index].senderDisplayName == viewModel.user.name ? .trailing : .leading) {
                                
                                if let userName = reversedList[index].senderDisplayName {
                                    if userName != viewModel.user.name {
                                        Text(userName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.blue)
                                    }
                                }
                                
                                VStack(alignment: reversedList[index].senderDisplayName == viewModel.user.name ? .trailing : .leading) {
                                    
                                    if let message = reversedList[index].content?.message {
                                        
                                        if message.contains("http") {
                                            
                                            KFImage(URL(string: message))
                                                .resizable()
                                                .frame(width: 100, height: 100)
                                                .aspectRatio(contentMode: .fill)
                                                .padding(10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .foregroundColor(Color.gray.opacity(0.1))
                                                )
                                            
                                        } else if message != "" {
                                            
                                            Text(message)
                                                .font(.body)
                                                .padding(10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .foregroundColor(Color.gray.opacity(0.1))
                                                )
                                            
                                        }
                                        
                                        VStack(alignment: .trailing) {
                                            Text(reversedList[index].createdOn.requestString)
                                            
                                            if viewModel.readMessageId == reversedList[index].id
                                                &&
                                                reversedList[index].senderDisplayName == viewModel.user.name {
                                                Text("Seen just now")
                                                    .font(.caption2)
                                            }
                                            
                                        }
                                        .font(.caption)
                                        
                                    }
                                    
                                }
                                .onTapGesture {
                                    viewModel.deleteMessage(messageId: reversedList[index].id) { success in
                                        viewModel.pageItems.remove(at: index)
                                    }
                                }
                            }
                            
                            if reversedList[index].senderDisplayName != viewModel.user.name { Spacer() }
                            
                        }
                        .id(reversedList[index].id)
                        .onAppear {
                            if reversedList[index].id == viewModel.pageItems.last?.id {
                                viewModel.sendMessageReadEvent(messageId: reversedList[index].id)
                            }
                        }
                    }
                }
            }
            .padding()
                
                HStack {
                    if viewModel.isType {
                        Text("Someone is typing...")
                            .font(.caption)
                        
                        Spacer()
                    }
                }
                .padding(.leading, 5)
                .id("bottom")
            }
            .onChange(of: viewModel.isType) { value in
                if value {
                    proxy.scrollTo(bottom, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isEventSend) { value in
                if value {
                    proxy.scrollTo(bottom, anchor: .bottom)
                    viewModel.isEventSend = false
                }
                viewModel.isEventSend = false
            }
            .onAppear {
                viewModel.isEventSend = false
                viewModel.isType = false
            }
        }
        
            
            
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text("If you tap message, message will be deleted")
                    .font(.caption)
                    .padding(.bottom, 5)
                
                HStack {
                    Button {
                        viewModel.addParticipant()
                    } label: {
                        Text("Invite User")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.blue)
                            )
                    }
                    
                    Button {
                        viewModel.loadMore()
                    } label: {
                        Text("Load More")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.blue)
                            )
                    }
                }
            }
            .padding()
            
            ChatListView()
            
            HStack {
                Button {
                    isShowPhotoLibrary = true
                } label : {
                    Image(systemName: "photo")
                }
                
                TextField("Send a Message", text: $messages)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    viewModel.sendMessage(message: messages) { success in
                        if success {
                            messages = ""
                        }
                    }
                } label: {
                    Text("Send")
                        .foregroundColor(Color.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color.blue)
                        )
                }
                .disabled(messages == "")
            }
            .padding()
            
        }
        .navigationTitle("Chat Room")
        .sheet(
            isPresented: $isShowPhotoLibrary,
            onDismiss: {
                guard let selectedImageUrl = self.$imageUrl.wrappedValue else { return }
                
                viewModel.uploadPhoto(fileUrl: selectedImageUrl) { result in
                    viewModel.sendMessage(message: result.url!) { _ in}
                }
                
            }
        ) {
            ImagePicker(sourceType: .photoLibrary, selectedImageUrl: self.$imageUrl)
        }
        .onChange(of: self.messages) { value in
            if value != "" {
                viewModel.sendTypeEvent()
            }
        }
        .onDisappear { viewModel.pageItems = [] }
    }
}
//
//struct ChatRoomView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatRoomView()
//    }
//}
