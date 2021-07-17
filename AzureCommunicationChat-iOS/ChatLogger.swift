//
//  CHLogger.swift
//  CloudHospital (iOS)
//
//  Created by Hyounwoo Sung on 2021/05/08.
//

import Foundation
import SwiftUI
import os

/// Usages
/// - debugging
///   logger.debug("debug")
///   logger.info("info")

/// - persisted to disk
///   logger.notice("notice")
///   logger.error("error")
///   logger.fault("fault")
class ChatLogger: NSObject {
    static let shared: ChatLogger = ChatLogger()

    let logger = Logger(subsystem: "ChatLogger", category: "AzureTest")
    let signpostLog = OSLog(__subsystem: "ChatLogger", category: "AzureTest")
}

extension ChatLogger {

    func debug(_ message: String) {
        logger.debug("➡️ debug: \(message)")
//        logger.notice("📘 notice: \(message)")
    }

    func info(_ message: String) {
        logger.info("📗 info: \(message)")
    }

    func notice(_ message: String) {
        logger.notice("📘 notice: \(message)")
    }

    func error(_ message: String) {
        logger.error("📕 error: \(message)")
    }

    func fault(_ message: String) {
        logger.fault("📔 fault: \(message, privacy: .public)")
    }
}
