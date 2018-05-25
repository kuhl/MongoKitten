import BSON
import NIO

public struct UpdateCommand: MongoDBCommand {
    typealias Reply = UpdateReply
    
    public struct Single: Encodable {
        public enum CodingKeys: String, CodingKey {
            case query = "q"
            case update = "u"
            case upsert
            case multiple = "multi"
        }
        
        public var query: Query
        public var update: Document
//        public var collation: Collation?
        public var upsert: Bool?
        public var multiple: Bool?
        
        public init(matching query: Query, to document: Document) {
            self.query = query
            self.update = document
        }
    }
    
    internal var collectionReference: CollectionReference {
        return update
    }
    
    private let update: CollectionReference
    public var updates: [Single]
    public var ordered: Bool?
//    public var writeConcern: WriteConcern?
    public var bypassDocumentValidation: Bool?
    
    static let writing = true
    static let emitsCursor = false
    
    public init(_ query: Query, to document: Document, in collection: Collection) {
        self.init(
            Single(matching: query, to: document),
            in: collection
        )
    }
    
    public init(_ updates: Single..., in collection: Collection) {
        self.init(updates, in: collection)
    }
    
    public init(_ updates: [Single], in collection: Collection) {
        self.update = collection.reference
        self.updates = Array(updates)
    }
    
    @discardableResult
    public func execute(on connection: MongoDBConnection) -> EventLoopFuture<UpdateReply> {
        return connection.execute(command: self)
    }
}

public struct UpdateReply: ServerReplyDecodable {
    typealias Result = UpdateReply
    
    public enum CodingKeys: String, CodingKey {
        case updated = "n"
        case ok
        case modified = "nModified"
    }
    
    public let updated: Int?
    private let ok: Int
    public let modified: Int
//    public var upserted: [Document]? // TODO: type-safe? We cannot (easily) decode the _id
//    public var writeErrors: [Errors.Write]?
//    public var writeConcernError: [Errors.WriteConcern]?
    
    public var isSuccessful: Bool {
        return ok == 1
    }
    
    var mongoKittenError: MongoKittenError {
        return MongoKittenError(.commandFailure, reason: nil)
    }
    
    func makeResult() throws -> UpdateReply {
        return self
    }
}
