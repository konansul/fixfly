//
//  SessionManager.swift
//  FixFly
//
//  Created by Kanan Sultanov on 18.04.26.
//

import Combine
import Foundation

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()
 
    @Published var hasSeenPhotoGuidelinesThisSession: Bool = false
    
    private init() {}
}
