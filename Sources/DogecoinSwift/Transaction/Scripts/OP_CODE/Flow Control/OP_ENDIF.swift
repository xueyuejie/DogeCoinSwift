import Foundation

public struct OpEndIf: OpCodeProtocol {
    public var value: UInt8 { return 0x68 }
    public var name: String { return "OP_ENDIF" }

    public func mainProcess(_ context: ScriptExecutionContext) throws {
        guard !context.conditionStack.isEmpty else {
            throw OpCodeExecutionError.error("Expected an OP_IF or OP_NOTIF branch before OP_ENDIF.")
        }
        context.conditionStack.removeLast()
    }
}
