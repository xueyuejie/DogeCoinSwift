import Foundation
import BIP39swift
import BIP32Swift
import Secp256k1Swift

public struct DogecoinKey {
    private var node: HDNode
    
    public var publicKey: Data {
        return node.publicKey
    }
    
    public var pubKeyHash: Data {
        return publicKey.hash160()!
    }
    
    public var privateKey: Data? {
        return node.privateKey
    }
    
    public static func fromMnemonics(_ mnemonics: String) -> Self? {
        guard let seed = BIP39.seedFromMmemonics(mnemonics) else {
            return nil
        }
        guard let rootNode = HDNode(seed: seed) else {
            return nil
        }
       return DogecoinKey(node: rootNode)
    }
    
    public func serializePublicKeyString(version: HDNode.HDversion) -> String? {
        return node.serializeToString(serializePublic: true, version: version)
    }
    
    public func serializePrivateKeyString(version: HDNode.HDversion) -> String? {
        return node.serializeToString(serializePublic: false, version: version)
    }
    
    public func serializePublicKey(version: HDNode.HDversion) -> Data? {
        return node.serialize(serializePublic: true, version: version)
    }
    
    public func serializePrivateKey(version: HDNode.HDversion) -> Data? {
        return node.serialize(serializePublic: false, version: version)
    }
    
    public func derive(path: String) throws -> DogecoinKey {
        guard let childNode = node.derive(path: path) else {
            throw DogecoinError.invalidDerivePath
        }
        return DogecoinKey(node: childNode)
    }
    
    public func derive(index: UInt32, hardened: Bool = false) throws -> DogecoinKey {
        guard let childNode = node.derive(index: index, derivePrivateKey: true, hardened: hardened) else {
            throw DogecoinError.invalidDerivePath
        }
        return DogecoinKey(node: childNode)
    }
}
