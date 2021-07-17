//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCommon
import AzureCommunicationChat
import AzureCore

class TokenService: ObservableObject {
    private var communicationTokenFetchUrl: String
    @Published var token = ""
    @Published var userId = ""

    let logger = ChatLogger.shared
    
    init(communicationTokenFetchUrl: String) {
        self.communicationTokenFetchUrl = communicationTokenFetchUrl
    }

    func getCommunicationToken(completionHandler: @escaping (TokenResponse, Error?) -> Void) {
        guard let url = URL(string: communicationTokenFetchUrl) else { return }
        var urlRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        urlRequest.httpMethod = "GET"

        URLSession.shared.dataTask(with: urlRequest) { (data, _, error) in
            if let error = error {
                print(error)
            } else if let data = data {
                do {
                    
                    let res = try JSONDecoder().decode(TokenResponse.self, from: data)
                    completionHandler(res, nil)
                } catch let error {
                    print(error)
                }
            }
        }.resume()
    }
}

struct TokenResponse: Codable {
    var token: String
    var userId: String
//    private enum CodingKeys: String, CodingKey {
//        case token
//    }
}
