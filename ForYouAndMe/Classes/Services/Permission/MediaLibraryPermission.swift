//
//  MediaLibraryPermission.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 16/09/2020.
//

import MediaPlayer

struct MediaLibraryPermission: PermissionProtocol {
    
    var isAuthorized: Bool {
        return MPMediaLibrary.authorizationStatus() == .authorized
    }
    
    var isDenied: Bool {
        return MPMediaLibrary.authorizationStatus() == .denied
    }
    
    func request(completion: @escaping ()->()?) {
        MPMediaLibrary.requestAuthorization() { status in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
