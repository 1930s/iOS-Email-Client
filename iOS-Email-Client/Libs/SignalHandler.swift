//
//  SignalHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class SignalHandler {
    let myAccount : Account
    
    init(account: Account){
        myAccount = account
    }
    
    func decryptMessage(_ encryptedMessageB64: String) -> String{
        let axolotlStore = CriptextAxolotlStore(myAccount.regId, myAccount.identityB64)
        let sessionCipher = SessionCipher(axolotlStore: axolotlStore, recipientId: myAccount.username, deviceId: 1)
        let incomingMessage = PreKeyWhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
        let plainText = sessionCipher?.decrypt(incomingMessage)
        let plainTextString = NSString(data:plainText!, encoding:String.Encoding.ascii.rawValue)
        print("decrypted: \(String(describing: plainTextString))")
        return plainTextString! as String
    }
}
