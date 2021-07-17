# AzureCommunicationChat-iOS
I made a simple app use AzureCommunicationChat SDK
## 🚨 Notice
```
If you want test this app,
You have to input your own source at AppSettings.plist
"communcationTokenFetchUrl", "tokenEndpoint"
```
# Getting started
## pod install
```
platform :ios, '12.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

target 'MyTarget' do
  pod 'AzureCommunicationChat', '1.0.0-beta.12'
  ...
end. 
```

# ChatClient
- ChatClient is the class that control the Thread(ChatRoom) function of the user.
- It must be initialised first.
- It is recommended to store it out of the closure because it is likely to be used several times.
- In my case, I registered the event immediately after the instance was created.

## Required
- CommunicationServices resource endpoint
- User Access Token
```
func getChatClient(endpoint: String, token: String) {
        guard let credential = try? CommunicationTokenCredential(token: token) else { return }
        
        let options = AzureCommunicationChatClientOptions(logger: ClientLoggers.none)
        guard let chatClient = try? ChatClient(endpoint: endpoint, credential: credential, withOptions: options) else { return }
        
        self.chatClient = chatClient
        self.resistEvent()
    }
```

# ChatClient Operations
## Create a Thread
- Client.create make new Thread(ChatRoom)
- In my case, I saved ThreadClient to control the thread at the same time as it was created.
## Required
- Topic for Thread
```
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
                }
            }
            
        }
        
    }
```
# List Threads
## Get List of Thread
- chartClient.listThreads return list of Thread
## Required
- ListChatThreadsOptions is the object representing the options to pass.
- maxPageSize, optional, is the maximum number of messages to be returned per page.
- startTime, optional, is the thread start time to consider in the query.
```
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
                        completionHandler(false)
                }
            }
            
        }
    }
```
# ChatThreadClient
- ChartThreadClient are needed to control the inside of the thread.
- It also recommended to store it out of the closure because it is likely to be used several times.
## Required
- ThreadId
```
func getThreadClient(threadId: String, completionHandler: @escaping (Bool) -> Void) {
        guard let chatThreadClient = try? self.chatClient?.createClient(forThread: threadId) else { return }
        self.chatThreadClient = chatThreadClient
        
        completionHandler(true)
    }
```
# ChatThreadClient Operations

#Add Thread Participants
## Required
- Participants's userId
- Participants's displayName
```
func addParticipant(addedUserId: String) {
        
        let threadParticipants = [
            ChatParticipant(id: CommunicationUserIdentifier(addedUserId), displayName: "Mike")
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
```
# Send a message
- send a message to server

## Required
- Content(message)
- supported type of Content is text and html
- DisplayName
- In order to transfer data, must be Changed to text or html.
```
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
            "Authorization" : "Bearer \(accessToken)" ])
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
```

#Update a message
- Use the update method of ChatThreadClient to update the content of a message.
- In my case, I configured the message update function to work as soon as get response.
## Required
- message is the unique ID of the message.
- parameters contains the message content to be updated.
```
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
```
#Delete a message
##Required
- messageId
```
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
```
#Get a message
- To retrieve a message in a Thread.
- It Returns the retrieved message
##Required
- messageId
```
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
```
# List messages
- To get the Messages in the thread
- It Returns <PagedCollection<ChatMessage>
- To Use more action, you have to capture <PagedCollection<ChatMessage>
- listMessagesResponse.isExhausted Returns true if there are no more results to fetch.
so use this, if false fetch more Data by use listMessagesResponse.nextPage Method.
##Required
- ListChatMessagesOptions is the optional object representing the options to pass.
- maxPageSize, optional, is the maximum number of messages to be returned per page.
- startTime, optional, is the thread start time to consider in the query.
```
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
```
#Event Operations
# chatClient.startRealTimeNotifications
- With realtime notifications enabled you can receive events when messages are sent to the thread.
- To enable realtime notifications use the startRealtimeNotifications method of ChatClient. Starting notifications is an asynhronous operation.
```
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
```
#Send a typing notification
- Use the sendTypingNotification method of ChatThreadClient to post a typing notification event to a thread, on behalf of a user.
```
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
```

#Send read receipt
- Use the sendReadReceipt method of ChatThreadClient to post a read receipt event to a thread, on behalf of a user.
- forMessage refers to the unique ID of the message that the read receipt is for.
```
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
```
## references
- https://github.com/Azure/azure-sdk-for-ios/tree/main/sdk/communication/AzureCommunicationChat#receive-messages-from-a-thread
- https://azure.github.io/azure-sdk-for-ios/AzureCommunicationChat/index.html
- https://docs.microsoft.com/ko-kr/azure/communication-services/concepts/chat/concepts
