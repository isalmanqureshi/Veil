//
//  ScreenshotDetector.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//
import SwiftUI

final class ScreenshotDetector {

    static func start(trustCenter: TrustCenter) {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            trustCenter.log(event: TrustEvent(
                    id: UUID(),
                    type: .screenshotTaken,
                    title: "Screenshot detected",
                    message: "Content may now exist outside protected chat.",
                    timestamp: Date(),
                    severity: .warning
                )
            )
        }
    }
}

