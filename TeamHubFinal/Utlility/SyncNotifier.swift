//
//  SyncNotifier.swift
//  TeamHubFinal
//
//  Created by Atin Joshi on 06/04/26.
//

import Foundation

final class SyncNotifier{
    static let shared = SyncNotifier()
    private init(){}
    private var observer: [UUID: ()-> Void] = [:]
    
    func addObserver(_ callback: @escaping ()-> Void) -> UUID{
        let id = UUID()
        observer[id] = callback
        return id
    }
    func notify(){
        observer.values.forEach{$0()}
    }
}
