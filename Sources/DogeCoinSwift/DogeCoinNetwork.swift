//
//  DogeCoinNetwork.swift
//  DogeCoinSwift
//
//  Created by xgblin on 2025/1/7.
//

import Foundation

public enum DogeCoinNetwork: String {
    case mainnet
    case testnet
    
    public var pubKeyHashPrefix: Data {
        switch self {
        case .mainnet:
            return Data(hex: "1e")
        case .testnet:
            return Data(hex: "71")
        }
    }
    
    public func extendedPath() -> String {
        switch self {
        case .mainnet:
            return "m/44'/3'/0'"
        case .testnet:
            return "m/44'/1'/0'"
        }
    }
    
    public func pubKeyPrefix() -> Data {
        switch self {
        case .mainnet:
            return Data(hex: "02facafd")
        case .testnet:
            return Data(hex: "043587cf")
        }
    }
    
    public func priKeyPrefix() -> Data {
        switch self {
        case .mainnet:
            return Data(hex: "02fac398")
        case .testnet:
            return Data(hex: "04358394")
        }
    }
}
