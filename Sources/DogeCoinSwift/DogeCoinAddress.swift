//
//  DogeCoinAddress.swift
//  DogeCoinSwift
//
//  Created by xgblin on 2025/1/7.
//

import Foundation

public struct DogeCoinAddress {
    public let publicKey: Data
    public let network: DogeCoinNetwork
    public var addressData: Data? {
        guard let hash = publicKey.hash160() else {
            return nil
        }
        
        var data = Data()
        data.append(network.pubKeyHashPrefix)
        data.append(hash)
        return data
    }
    
    public var address: String? {
        return self.addressData?.bytes.base58CheckEncodedString
    }
    
    init(publicKey: Data, network: DogeCoinNetwork) {
        self.publicKey = publicKey
        self.network = network
    }
    
    public static func decodeAddress(_ address: String) -> Data? {
        return address.base58CheckDecodedData
    }
    
    public static func encodeAddress(_ addressData: Data,network: DogeCoinNetwork = .mainnet) -> String? {
        guard addressData.count == 1 + 20, addressData.prefix(1) == network.pubKeyHashPrefix else { return nil }
        return addressData.bytes.base58CheckEncodedString
    }
    
    public static func isValidAddress(_ address: String, network: DogeCoinNetwork = .mainnet) -> Bool {
        guard let data = DogeCoinAddress.decodeAddress(address) else { return false }
        guard data.count == 1 + 20, data.prefix(1) == network.pubKeyHashPrefix else { return false }
        return true
    }
}


