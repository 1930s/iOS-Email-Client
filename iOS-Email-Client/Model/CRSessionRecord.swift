//
//  RawSessionRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class CRSessionRecord: Object{
    @objc dynamic var contactId = ""
    @objc dynamic var deviceId : Int32 = 0
    @objc dynamic var sessionRecord = ""
}
