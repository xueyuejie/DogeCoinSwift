import Foundation

// The entire transaction's outputs, inputs, and script (from the most recently-executed OP_CODESEPARATOR to the end) are hashed. The signature used by OP_CHECKSIG must be a valid signature for this hash and public key. If it is, 1 is returned, 0 otherwise.
public struct OpCheckSig: OpCodeProtocol {
    public var value: UInt8 { return 0xac }
    public var name: String { return "OP_CHECKSIG" }

    // input : sig pubkey
    // output : true / false
    public func mainProcess(_ context: ScriptExecutionContext) throws {
        try context.assertStackHeightGreaterThanOrEqual(2)

        let pubkeyData: Data = context.stack.removeLast()
        let sigData: Data = context.stack.removeLast()

        guard let tx = context.transaction, let input = context.input else {
            throw OpCodeExecutionError.error("The transaction or the utxo to verify is not set.")
        }
        let valid = try BitcoinPublicKey.verifySigData(for: tx, inputIndex: Int(context.inputIndex), input: input ,sigData: sigData, pubKeyData: pubkeyData)
        context.pushToStack(valid)
    }
}
