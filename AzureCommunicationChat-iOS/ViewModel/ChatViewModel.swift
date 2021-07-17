//
//  ChatViewModel.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/08.
//

import SwiftUI
import AzureCommunicationCommon
import AzureCommunicationChat
import AzureCore
import Alamofire


class ChatViewModel: ObservableObject {
    @Published var pageItems = [ChatMessage]()
    @Published var chatList = [ChatThreadItem]()
    @Published var user: User = User(name: "", communicationUserId: "", token: "")
    @Published var chatRoom = CreateChatThreadResult()
    @Published var isType = false
    @Published var isEventSend = false
    @Published var readMessageId = ""
    var chatThreadClient: ChatThreadClient?
    var chatClient: ChatClient?
    var chatMessages: PagedCollection<ChatMessage>?
    let chatLogger = ChatLogger.shared
    
    // Create ChatClient
    func getChatClient(endpoint: String, token: String) {
        guard let credential = try? CommunicationTokenCredential(token: token) else { return }
        
        let options = AzureCommunicationChatClientOptions(logger: ClientLoggers.none)
        guard let chatClient = try? ChatClient(endpoint: endpoint, credential: credential, withOptions: options) else { return }
        
        self.chatClient = chatClient
        self.resistEvent()
    }
    
    // Create ThreadClient
    func getThreadClient(threadId: String, completionHandler: @escaping (Bool) -> Void) {
        guard let chatThreadClient = try? self.chatClient?.createClient(forThread: threadId) else { return }
        self.chatThreadClient = chatThreadClient
        
        completionHandler(true)
    }
    
    // Resist Event To ChatClient
    func resistEvent() {
        
        if let chatClient = self.chatClient {
            
            chatClient.startRealTimeNotifications() { result in
                switch result {
                    case .success:
                        chatClient.register(event: ChatEventId.chatMessageReceived, handler: self.handler)
                        chatClient.register(event: ChatEventId.readReceiptReceived, handler: self.handler)
                        chatClient.register(event: ChatEventId.chatMessageDeleted, handler: self.handler)
                        chatClient.register(event: ChatEventId.chatMessageEdited, handler: self.handler)
                        chatClient.register(event: ChatEventId.chatThreadCreated, handler: self.handler)
                        chatClient.register(event: ChatEventId.chatThreadDeleted, handler: self.handler)
                        chatClient.register(event: ChatEventId.participantsAdded, handler: self.handler)
                        chatClient.register(event: ChatEventId.typingIndicatorReceived, handler: self.handler)
                    case .failure:
                        print("에러발생")
                }
            }
            
        }
        
    }
    
    // Sending Event Thread Paticipant typing..
    func sendTypeEvent() {
        if let chatThreadClient = self.chatThreadClient {
            chatThreadClient.sendTypingNotification { result, _ in
                switch result {
                    case .success:
                        print("throw event successfully")
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }
    }
    
    // Sending Event Message read receipt
    func sendMessageReadEvent(messageId: String) {
        if let chatThreadClient = self.chatThreadClient {
            chatThreadClient.sendReadReceipt(forMessage: messageId) { result, _ in
                switch result {
                    case .success:
                        print("throw event successfully")
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }
    }
    
    // Event Handler
    func handler (event: TrouterEvent) {
        
        switch event {
            case .chatMessageReceivedEvent(let message):
                self.pageItems.insert(
                    ChatMessage(
                        id: message.id,
                        type: message.type,
                        sequenceId: message.threadId,
                        version: message.version,
                        content: ChatMessageContent(message: message.message, initiator: message.recipient),
                        senderDisplayName: message.senderDisplayName,
                        createdOn: message.createdOn!,
                        sender: message.sender), at: 0)
                self.isType = false
                self.isEventSend = true
                self.getChatList { _ in }
            case .typingIndicatorReceived(let type):
                if type.sender.unsafelyUnwrapped.stringValue != self.user.communicationUserId {
                    if !self.isType {
                        self.isType = true
                    }
                }
            case .readReceiptReceived(let read):
                if self.pageItems.last?.senderDisplayName == self.user.name {
                    self.readMessageId = read.chatMessageId
                }
            case .chatMessageEdited(_):
                print("Edit")
            case .chatMessageDeleted(_):
                print("Delete")
            case .chatThreadCreated(_):
                print("Thread created")
            case .chatThreadPropertiesUpdated(_):
                print("Updated")
            case .chatThreadDeleted(_):
                print("Thread Deleted")
            case .participantsAdded(let paticipants):
                paticipants.participantsAdded?.forEach({ joinedUser in
                    print("\(String(describing: joinedUser.displayName)) Join Room")
                })
            case .participantsRemoved(_):
                print("Participant Removed")
        }
    }
    
    // Create Chat Thread
    func createRoom(topic: String, completionHandler: @escaping (Bool) -> Void) {
        
        let topic = CreateChatThreadRequest(topic: topic)
        
        if let chatClient = self.chatClient {
            
            chatClient.create(thread: topic) { result, _ in
                switch result {
                    case .success(let createChatThreadResult):
                        
                        self.getThreadClient(threadId: createChatThreadResult.chatThread!.id) {_ in}
                        self.chatRoom = createChatThreadResult
                        completionHandler(true)
                    case .failure:
                        completionHandler(false)
                        print("통신실패")
                }
            }
            
        }
        
    }
    
    // Add participant in Thread
    func addParticipant() {
        
        guard let addedUserId = UIPasteboard.general.string else { return }
        chatLogger.notice("userId: \(addedUserId)")
        
        let threadParticipants = [
            ChatParticipant(id: CommunicationUserIdentifier(addedUserId), displayName: "Test1")
        ]
        
        if let clichatThreadClientent = self.chatThreadClient {
            
            clichatThreadClientent.add(participants: threadParticipants) { result, _ in
                switch result {
                    case .success:
                        print("Paticipant Added.")
                    case .failure(let err):
                        print(err)
                }
            }
            
        }
    }
    
    // Get Threads Propertis
    func getThreadProperties() {
        if let chatThreadClient = self.chatThreadClient {
            chatThreadClient.getProperties { result, _ in
                switch result {
                    case let .success(chatThreadProperties):
                        print(chatThreadProperties)
                    case let .failure(error):
                        print(error.localizedDescription)
                }
            }
        }
    }
    
    // Get specific Thread's paticipants list
    func getThreadParticipants(chatThreadClient: ChatThreadClient, completionHandler: @escaping ([String]) -> Void) {
        
        chatThreadClient.listParticipants { result, _ in
            switch result {
                case .success(let result):
                    var participantsList = [String]()
                    
                    result.items?.forEach({ chatParticipant in
                        
                        if let displayName = chatParticipant.displayName {
                            participantsList.append(displayName)
                        }
                        
                    })
                    
                    completionHandler(participantsList)
                    self.chatLogger.notice("Paticipants: \(participantsList)")
                case .failure(let err):
                    print(err)
            }
        }
        
    }
    
    // Send a Message
    func sendMessage(message: String, completionHandler: @escaping (Bool) -> Void) {
        
        let sendChatMessageRequest = SendChatMessageRequest(
            content: message,
            senderDisplayName: self.user.name,
            type: .text
        )
        
        if let chatThreadClient = self.chatThreadClient {
            
            chatThreadClient.send(message: sendChatMessageRequest) { result, _ in
                switch result {
                    case .success(let sendChatMessageResult):
                        self.updateMessage(message: message, messageId: sendChatMessageResult.id)
                        completionHandler(true)
                    case .failure(let err):
                        print(err.localizedDescription)
                        completionHandler(false)
                }
            }
            
        }
        
    }
    
    // Message Update
    func updateMessage(message: String, messageId: String) {
        
        if let chatThreadClient = self.chatThreadClient {
            
            chatThreadClient.update(content: message, messageId: messageId) { result, _ in
                switch result {
                    case .success:
                        self.chatLogger.notice("Message updated successfully")
                    case .failure(let err):
                        print(err.localizedDescription)
                }
            }
            
        }
    }
    
    // Delete Message From Thread
    func deleteMessage(messageId: String, completionHandler: @escaping (Bool) -> Void) {
        if let chatThreadClient = self.chatThreadClient {
            
            chatThreadClient.delete(message: messageId) { result, _ in
                switch result {
                    case .success:
                        print("Message deleted successfully")
                        completionHandler(true)
                    case .failure(let error):
                        print(error.localizedDescription)
                        completionHandler(false)
                }
            }
        }
        
    }
    
    // Get specific Maessage
    func getMessage(messageId: String, completionHandler: @escaping (ChatMessage) -> Void) {
        
        if let chatThreadClient = self.chatThreadClient {
            
            chatThreadClient.get(message: messageId) { result, _ in
                switch result {
                    case .success(let chatMessage):
                        completionHandler(chatMessage)
                    case .failure(let err):
                        print(err)
                }
            }
            
        }
        
    }
    
    // Load More Message in Thread
    func loadMore() {
        if let chatMessages = self.chatMessages {
            if !chatMessages.isExhausted {
                chatMessages.nextPage { newChatMessages in
                    
                    guard let messages = try? newChatMessages.get() else { return }
                    self.pageItems.append(contentsOf: messages)
                }
            }
            
        }
    }
    
    // Get All messages in Thread
    func getMessageList(completionHandler: @escaping (Bool) -> Void) {
        
        let options = ListChatMessagesOptions(maxPageSize: 20)
        
        chatThreadClient?.listMessages(withOptions: options, completionHandler: { result, error in
            if let error = error {
                print("listMessages error: \(String(describing: error.statusMessage))")
                completionHandler(false)
            }
            
            switch result {
                case let .success(chatMessages):
                    
                    self.chatMessages = chatMessages
                    
                    if let pageItems = chatMessages.pageItems {
                        self.pageItems = pageItems
                        completionHandler(true)
                    }
                    
                case .failure(_):
                    completionHandler(false)
                    break
                    
            }
        })
        
    }
    
    // GetThreadList
    func getChatList(completionHandler: @escaping (Bool) -> Void) {
        
        if let chatClient = self.chatClient {
            
            chatClient.listThreads { result, _ in
                switch result {
                    case .success(let listThreadsResponse):
                        if let pageItems = listThreadsResponse.pageItems {
                            self.chatList = pageItems
                            completionHandler(true)
                        }
                    case .failure:
                        print("통신실패")
                        completionHandler(false)
                }
            }
            
        }
    }
    
    // Send Iamge file to DB
    func uploadPhoto(fileUrl: URL, completionHandler: @escaping (MediaViewModel) -> Void) {
        let imageApi = "https://api-int.icloudhospital.com/api/v1/images"
        let parameters: [String: Any] = ["file": fileUrl]
        
        AF.upload(multipartFormData: { mpForm in
            for (k, v) in parameters {
                switch v {
                    case let fileURL as URL:
                        mpForm.append(fileURL, withName: k)
                    default:
                        fatalError()
                }
            }
            
        }, to: imageApi, headers: [
            "Content-Type": "multipart/form-data",
            "Authorization" : "Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IldWZk9BUS1kMGZ3bkhXdUtBMUpMU2ciLCJ0eXAiOiJhdCtqd3QifQ.eyJuYmYiOjE2MjY0OTQ0ODYsImV4cCI6MTYyNjQ5ODA4NiwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS1pbnQuaWNsb3VkaG9zcGl0YWwuY29tIiwiYXVkIjpbIkNsb3VkSG9zcGl0YWxfYXBpIiwiQ2xvdWRIb3NwaXRhbF9jaGF0X2FwaSIsIkNsb3VkSG9zcGl0YWxfcGF5bWVudF9hcGkiLCJJZGVudGl0eVNlcnZlckFwaSJdLCJjbGllbnRfaWQiOiJDbG91ZEhvc3BpdGFsX1NQQSIsInN1YiI6Ijc4MjBjMjA4LTRhZmMtNDEzNC04NzdjLWRhNDg2NzkxNjQzZCIsImF1dGhfdGltZSI6MTYyNjE3MjMzNywiaWRwIjoiR29vZ2xlIiwicm9sZSI6IlVzZXIiLCJuYW1lIjoic2FuZ2t1ODI0QGdtYWlsLmNvbSIsImVtYWlsIjoic2FuZ2t1ODI0QGdtYWlsLmNvbSIsInNjb3BlIjpbImVtYWlsIiwib3BlbmlkIiwicHJvZmlsZSIsInJvbGVzIiwiQ2xvdWRIb3NwaXRhbF9hcGkiLCJDbG91ZEhvc3BpdGFsX2NoYXRfYXBpIiwiQ2xvdWRIb3NwaXRhbF9wYXltZW50X2FwaSIsIklkZW50aXR5U2VydmVyQXBpIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbIkdvb2dsZSJdfQ.Z309jx5eeJOjoHtT_SCKpDKsL_XysnjOnSzqLIUCCE2WjzcdHza_Ez7fvTurC6eV9c7eHl-lGjnuCpPnFao09TNsDAtfOj2RBhbLcxVwDDbYOJSBXC1zpBC7M6U5qyZ_dD0Rb96dxYWMwr1phPPAo9N5vIXRC9OEmT40E0v2O60z298r9NDUhDtaLTXChb3k2zIMMAEpSQAFM-LHTUIoMEwGES9yyNzPSjNUkRi_FUYnS4PkDovAQFehBqBFeCC6Sh7gFj_ZEh6YH53OE_5WEh_rFSarXPiMkHHr5YDFUScmSlQ_fcaeD4-023yJ6GMbDui48hWQ-_lRKsYbE968Zg" ])
        .response(completionHandler: { response in
            
            switch response.result {
                case .success(let data):
                    if let data = data {
                        let decoder = JSONDecoder()
                        guard let decodedData = try? decoder.decode([MediaViewModel].self, from: data) else { return }
                        completionHandler(decodedData[0])
                    }
                case .failure(let error):
                    print(error)
            }
        }
        )
    }
}
