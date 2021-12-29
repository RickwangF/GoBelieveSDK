//
// Created by Nan Yang on 2021/12/23.
//

public protocol ConversationEntity {
    var name: String { get }
    var avatarURL: String { get }
    var content: String { get }
    var uuid: String { get }
    var targetUid: Int64 { get }
    var targetId: String { get }
    var isPinned: Bool { get }
    var isRevoked: Bool { get }
    var isDeleted: Bool { get }
    var isGroup: Bool { get }
    var memberLevel: String { get }
    var memberType: Int { get }
    var memberImage: String { get }
    var draft: String { get }
    var isUnsent: Bool { get }
    var newMessageCount: Int32 { get }
    var timestamp: Int { get }
    var isFromSelf: Bool { get }
    var area: String { get }
    var remarkName: String { get }
    var conversationType: Int { get }
}
