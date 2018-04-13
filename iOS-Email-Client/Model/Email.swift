//
//  Email.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/8/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class Email: Object {
    
    @objc dynamic var id = 0
    @objc dynamic var key = ""
    @objc dynamic var threadId = ""
    @objc dynamic var s3Key = ""
    @objc dynamic var unread = true
    @objc dynamic var secure = true
    @objc dynamic var content = ""
    @objc dynamic var preview = ""
    @objc dynamic var subject = ""
    @objc dynamic var delivered = DeliveryStatus.SENT
    @objc dynamic var date : Date?
    var isExpanded = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["isExpanded"]
    }
    
    var isUnsent: Bool{
        return delivered == DeliveryStatus.UNSENT
    }
    
    func incrementID() -> Int {
        let realm = try! Realm()
        return (realm.objects(Email.self).max(ofProperty: "id") as Int? ?? 0) + 1
    }
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}

struct DeliveryStatus {
    static let PENDING = 0
    static let SENT = 1
    static let DELIVERED = 2
    static let UNSENT = -1
}
