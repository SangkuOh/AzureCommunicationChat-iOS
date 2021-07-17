//
//  CommunicationIdentifier.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/09.
//

import Foundation
import AzureCommunicationCommon

extension CommunicationIdentifier {
    var stringValue: String? {
        switch self {
        case is CommunicationUserIdentifier:
            return (self as! CommunicationUserIdentifier).identifier
        case is UnknownIdentifier:
            return (self as! UnknownIdentifier).identifier
        case is PhoneNumberIdentifier:
            return (self as! PhoneNumberIdentifier).phoneNumber
        case is MicrosoftTeamsUserIdentifier:
            return (self as! MicrosoftTeamsUserIdentifier).userId
        default:
            return nil
        }
    }

}
