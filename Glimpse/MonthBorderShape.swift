import SwiftUI

struct MonthBorderShape: Shape {
    let startCol: Int
    let endCol: Int
    let endRow: Int
    let cornerRadius: CGFloat = AppDesign.CornerRadius.md

    func path(in rect: CGRect) -> Path {
        let cw = rect.width / 7
        let ch = rect.height / 6
        let r = cornerRadius

        var vertices: [CGPoint] = []
        let hasTopStep = startCol > 0
        let hasBottomStep = endCol < 6

        if hasTopStep {
            vertices.append(CGPoint(x: CGFloat(startCol) * cw, y: 0))
        } else {
            vertices.append(CGPoint(x: 0, y: 0))
        }

        vertices.append(CGPoint(x: rect.width, y: 0))

        if hasBottomStep {
            vertices.append(CGPoint(x: rect.width, y: CGFloat(endRow) * ch))
            vertices.append(CGPoint(x: CGFloat(endCol + 1) * cw, y: CGFloat(endRow) * ch))
            vertices.append(CGPoint(x: CGFloat(endCol + 1) * cw, y: CGFloat(endRow + 1) * ch))
        } else {
            vertices.append(CGPoint(x: rect.width, y: CGFloat(endRow + 1) * ch))
        }

        if hasTopStep {
            vertices.append(CGPoint(x: 0, y: CGFloat(endRow + 1) * ch))
            vertices.append(CGPoint(x: 0, y: ch))
            vertices.append(CGPoint(x: CGFloat(startCol) * cw, y: ch))
        } else {
            vertices.append(CGPoint(x: 0, y: CGFloat(endRow + 1) * ch))
        }

        var path = Path()
        let count = vertices.count
        let start = midpoint(vertices[count - 1], vertices[0])
        path.move(to: start)

        for i in 0..<count {
            let current = vertices[i]
            let next = vertices[(i + 1) % count]
            path.addArc(tangent1End: current, tangent2End: next, radius: r)
        }

        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}
