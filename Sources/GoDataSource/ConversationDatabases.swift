//
// Created by Nan Yang on 2021/12/29.
//

import Foundation

public final class ConversationDatabases: NSObject {
    /// 获取旧版数据库实现
    @objc
    public static func legacy() -> GoConversationDatabase {
        SQLConversationDB.shared
    }

    /// 获取新版数据库实现
    @objc
    public static func modern() -> GoConversationDatabase {
        ConversationDatabase.shared
    }
}
