//
//  User.swift
//  MailboxAccess
//
//  Created by Isa Hashim on 2/23/21.
//

import Foundation

struct User: Decodable {
    let firstName: String
    let lastName: String
    let email: String
    let userId: String
    let mailboxId: Int
}
