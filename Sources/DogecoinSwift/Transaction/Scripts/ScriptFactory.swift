import Foundation

public struct ScriptFactory {
    // Basic
    public struct Standard {}
    public struct LockTime {}
    public struct MultiSig {}
    public struct OpReturn {}
    public struct Condition {}

    // Contract
    public struct HashedTimeLockedContract {}
}

// MARK: - Standard
public extension ScriptFactory.Standard {
    static func buildP2PK(publickey: BitcoinPublicKey) -> Script? {
        return try? Script()
            .appendData(publickey.data)
            .append(.OP_CHECKSIG)
    }

    static func buildP2PKH(address: BitcoinAddress) -> Script? {
        return Script(address:address.address!)
    }

    static func buildP2SH(script: Script) -> Script {
        return script.toP2SH()
    }

    static func buildMultiSig(publicKeys: [BitcoinPublicKey]) -> Script? {
        return Script(publicKeys: publicKeys, signaturesRequired: UInt(publicKeys.count))
    }
    static func buildMultiSig(publicKeys: [BitcoinPublicKey], signaturesRequired: UInt) -> Script? {
        return Script(publicKeys: publicKeys, signaturesRequired: signaturesRequired)
    }
}

// MARK: - LockTime
public extension ScriptFactory.LockTime {
    // Base
    static func build(script: Script, lockDate: Date) -> Script? {
        return try? Script()
            .appendData(lockDate.bigNumData)
            .append(.OP_CHECKLOCKTIMEVERIFY)
            .append(.OP_DROP)
            .appendScript(script)
    }

    static func build(script: Script, lockIntervalSinceNow: TimeInterval) -> Script? {
        let lockDate = Date(timeIntervalSinceNow: lockIntervalSinceNow)
        return build(script: script, lockDate: lockDate)
    }

    // P2PKH + LockTime
    static func build(address: BitcoinAddress, lockIntervalSinceNow: TimeInterval) -> Script? {
        guard let p2pkh = Script(address: address.address!) else {
            return nil
        }
        let lockDate = Date(timeIntervalSinceNow: lockIntervalSinceNow)
        return build(script: p2pkh, lockDate: lockDate)
    }

    static func build(address: BitcoinAddress, lockDate: Date) -> Script? {
        guard let p2pkh = Script(address: address.address!) else {
            return nil
        }
        return build(script: p2pkh, lockDate: lockDate)
    }
}

// MARK: - OpReturn
public extension ScriptFactory.OpReturn {
    static func build(text: String) -> Script? {
        let MAX_OP_RETURN_DATA_SIZE: Int = 220
        guard let data = text.data(using: .utf8), data.count <= MAX_OP_RETURN_DATA_SIZE else {
            return nil
        }
        return try? Script()
            .append(.OP_RETURN)
            .appendData(data)
    }
}

// MARK: - Condition
public extension ScriptFactory.Condition {
    static func build(scripts: [Script]) -> Script? {

        guard !scripts.isEmpty else {
            return nil
        }
        guard scripts.count > 1 else {
            return scripts[0]
        }

        var scripts: [Script] = scripts

        while scripts.count > 1 {
            var newScripts: [Script] = []
            while !scripts.isEmpty {
                let script = Script()
                do {
                    if scripts.count == 1 {
                        try script
                            .append(.OP_DROP)
                            .appendScript(scripts.removeFirst())
                    } else {
                        try script
                            .append(.OP_IF)
                            .appendScript(scripts.removeFirst())
                            .append(.OP_ELSE)
                            .appendScript(scripts.removeFirst())
                            .append(.OP_ENDIF)
                    }
                } catch {
                    return nil
                }
                newScripts.append(script)
            }
            scripts = newScripts
        }

        return scripts[0]
    }
}

// MARK: - HTLC
/*
 OP_IF
    [HASHOP] <digest> OP_EQUALVERIFY OP_DUP OP_HASH160 <recipient pubkey hash>
 OP_ELSE
    <num> [TIMEOUTOP] OP_DROP OP_DUP OP_HASH160 <sender pubkey hash>
 OP_ENDIF
 OP_EQUALVERIFYs
 OP_CHECKSIG
*/
public extension ScriptFactory.HashedTimeLockedContract {
    // Base
    static func build(recipient: BitcoinAddress, sender: BitcoinAddress, lockDate: Date, hash: Data, hashOp: HashOperator) -> Script? {
        guard hash.count == hashOp.hashSize else {
            return nil
        }

        return try? Script()
            .append(.OP_IF)
                .append(hashOp.opcode)
                .appendData(hash)
                .append(.OP_EQUALVERIFY)
                .append(.OP_DUP)
                .append(.OP_HASH160)
                .appendData(recipient.addressData!)
            .append(.OP_ELSE)
                .appendData(lockDate.bigNumData)
                .append(.OP_CHECKLOCKTIMEVERIFY)
                .append(.OP_DROP)
                .append(.OP_DUP)
                .append(.OP_HASH160)
                .appendData(sender.addressData!)
            .append(.OP_ENDIF)
            .append(.OP_EQUALVERIFY)
            .append(.OP_CHECKSIG)
    }

    // convenience
    static func build(recipient: BitcoinAddress, sender: BitcoinAddress, lockIntervalSinceNow: TimeInterval, hash: Data, hashOp: HashOperator) -> Script? {
        let lockDate = Date(timeIntervalSinceNow: lockIntervalSinceNow)
        return build(recipient: recipient, sender: sender, lockDate: lockDate, hash: hash, hashOp: hashOp)
    }

    static func build(recipient: BitcoinAddress, sender: BitcoinAddress, lockIntervalSinceNow: TimeInterval, secret: Data, hashOp: HashOperator) -> Script? {
        let hash = hashOp.hash(secret)
        let lockDate = Date(timeIntervalSinceNow: lockIntervalSinceNow)
        return build(recipient: recipient, sender: sender, lockDate: lockDate, hash: hash, hashOp: hashOp)
    }

    static func build(recipient: BitcoinAddress, sender: BitcoinAddress, lockDate: Date, secret: Data, hashOp: HashOperator) -> Script? {
        let hash = hashOp.hash(secret)
        return build(recipient: recipient, sender: sender, lockDate: lockDate, hash: hash, hashOp: hashOp)
    }

}

public class HashOperator {
    public static let SHA256: HashOperator = HashOperatorSha256()
    public static let HASH160: HashOperator = HashOperatorHash160()

    public var opcode: OpCode { return .OP_INVALIDOPCODE }
    public var hashSize: Int { return 0 }
    public func hash(_ data: Data) -> Data { return Data() }
    fileprivate init() {}
}

final public class HashOperatorSha256: HashOperator {
    override public var opcode: OpCode { return .OP_SHA256 }
    override public var hashSize: Int { return 32 }

    override public func hash(_ data: Data) -> Data {
        return data.sha256()
    }
}

final public class HashOperatorHash160: HashOperator {
    override public var opcode: OpCode { return .OP_HASH160 }
    override public var hashSize: Int { return 20 }

    override public func hash(_ data: Data) -> Data {
        return data.hash160()!
    }
}

// MARK: - Utility Extension
private extension Date {
    var bigNumData: Data {
        let dateUnix: TimeInterval = timeIntervalSince1970
        let bn = BigNumber(Int32(dateUnix).littleEndian)
        return bn.data
    }
}
