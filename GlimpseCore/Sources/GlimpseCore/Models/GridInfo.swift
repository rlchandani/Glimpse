import Foundation

public struct GridInfo: Equatable, Sendable {
    public let startCol: Int
    public let endCol: Int
    public let endRow: Int

    public init(startCol: Int, endCol: Int, endRow: Int) {
        self.startCol = startCol
        self.endCol = endCol
        self.endRow = endRow
    }
}
