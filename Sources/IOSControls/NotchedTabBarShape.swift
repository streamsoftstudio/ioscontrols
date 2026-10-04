//
//  NotchedTabBarShape.swift
//  IOSControls
//
//  Created by Andrija Milovanovic on 4.10.2026.
//

import CoreGraphics

/// The outline of a tab bar with a round notch cut into the middle of its top
/// edge, where a raised control sits.
///
/// Coordinates grow downwards, as UIKit's do. Platform-independent, so it is
/// tested on macOS too.
public struct NotchedTabBarShape: Equatable {

    /// Where the bar's top edge runs. Above it is the raised part of the
    /// control.
    public var top: CGFloat

    /// The centre of the control the notch makes room for.
    public var controlCenter: CGPoint

    public var controlRadius: CGFloat

    /// Between the control and the notch's edge.
    public var gap: CGFloat

    /// The curve that rounds the notch into the top edge.
    public var filletRadius: CGFloat

    /// The bar's two top corners.
    public var cornerRadius: CGFloat

    public init(
        top: CGFloat,
        controlCenter: CGPoint,
        controlRadius: CGFloat,
        gap: CGFloat,
        filletRadius: CGFloat,
        cornerRadius: CGFloat
    ) {
        self.top = top
        self.controlCenter = controlCenter
        self.controlRadius = controlRadius
        self.gap = gap
        self.filletRadius = filletRadius
        self.cornerRadius = cornerRadius
    }

    public var notchRadius: CGFloat {
        controlRadius + gap
    }

    /// How far either side of the control's centre the notch opens along the
    /// top edge, its rounding included. Zero when the control does not cross
    /// the top edge, and so cuts no notch.
    public var notchHalfWidth: CGFloat {
        notch?.halfWidth ?? 0
    }

    /// The bar's outline within `rect`: from `top` to the bottom of `rect`,
    /// rounded at the top corners, with the notch cut around the control.
    public func path(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let corner = max(0, min(cornerRadius, (rect.maxY - top) / 2, rect.width / 2))

        // Angles grow clockwise on screen, since y grows downwards, and Core
        // Graphics sweeps towards growing angles when `clockwise` is false.
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: top + corner))
        path.addArc(
            center: CGPoint(x: rect.minX + corner, y: top + corner), radius: corner,
            startAngle: .pi, endAngle: 1.5 * .pi, clockwise: false
        )
        if let notch {
            path.addLine(to: CGPoint(x: notch.leadingFillet.x, y: top))
            path.addArc(
                center: notch.leadingFillet, radius: filletRadius,
                startAngle: 1.5 * .pi, endAngle: notch.leadingTouch, clockwise: false
            )
            path.addArc(
                center: controlCenter, radius: notchRadius,
                startAngle: notch.leadingTouch + .pi, endAngle: notch.trailingTouch + .pi, clockwise: true
            )
            path.addArc(
                center: notch.trailingFillet, radius: filletRadius,
                startAngle: notch.trailingTouch, endAngle: 1.5 * .pi, clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX - corner, y: top))
        path.addArc(
            center: CGPoint(x: rect.maxX - corner, y: top + corner), radius: corner,
            startAngle: 1.5 * .pi, endAngle: 2 * .pi, clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    // MARK: Notch

    /// Where the notch meets the top edge: each fillet's centre, and the
    /// angle, from that centre, at which the fillet joins the notch.
    private struct Notch {
        var leadingFillet: CGPoint
        var trailingFillet: CGPoint
        var leadingTouch: CGFloat
        var trailingTouch: CGFloat
        var halfWidth: CGFloat
    }

    private var notch: Notch? {
        let depth = controlCenter.y - top
        let radius = notchRadius
        // Only a control that crosses the top edge cuts into it.
        guard abs(depth) < radius else { return nil }

        // Each fillet touches the top edge from below and the notch from
        // outside, so its centre sits a fillet's radius below the edge and
        // the two radii apart from the control's centre.
        let reach = radius + filletRadius
        let rise = filletRadius - depth
        let offset = (reach * reach - rise * rise).squareRoot()
        let leading = CGPoint(x: controlCenter.x - offset, y: top + filletRadius)
        let trailing = CGPoint(x: controlCenter.x + offset, y: top + filletRadius)
        return Notch(
            leadingFillet: leading,
            trailingFillet: trailing,
            leadingTouch: atan2(controlCenter.y - leading.y, controlCenter.x - leading.x),
            trailingTouch: atan2(controlCenter.y - trailing.y, controlCenter.x - trailing.x),
            halfWidth: offset
        )
    }
}
