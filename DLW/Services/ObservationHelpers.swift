//
//  ObservationHelpers.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import Foundation
import Vision

/// Gets the absolute distance between 2 `VNPoint`
///
/// Uses the distance formula to get the distance between 2 points.
public func getPointsAbsoluteDistance(a: VNPoint, b: VNPoint) -> Double {
    let xval: Double = pow(a.x - b.x, 2)
    let yval: Double = pow(a.y - b.y, 2)
    let distance: Double = sqrt(xval + yval)
    return distance
}

/// Gets the vertical distance between 2 `VNPoint`
public func getPointsVerticalDistance(a: VNPoint, b: VNPoint) -> Double {
    return abs(a.y - b.y)
}

/// Gets the horizontal distance between 2 `VNPoint`
public func getPointsHorizontalDistance(a: VNPoint, b: VNPoint) -> Double {
    return abs(a.x - b.x)
}

/// Gets the angle from 3 `VNPoint`.
///
/// Uses the Cosine Rule to derive the angle, with `b` being the vertex of the 3 points.
public func getAngleFromThreeVNPoints(a: VNPoint, b: VNPoint, c: VNPoint) -> Double {
    let ab: Double = sqrtl(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    let bc: Double = sqrtl(pow(b.x - c.x, 2) + pow(b.y - c.y, 2))
    let ac: Double = sqrtl(pow(a.x - c.x, 2) + pow(a.y - c.y, 2))
    let angle: Double = (pow(ab, 2) + pow(bc, 2) - pow(ac, 2)) / (2 * ab * bc)
    return acos(angle) * 180 / Double.pi
}

/// Checks if the list of `VNPoint` are sorted in a vertically ascending manner.
public func vnPointsAreVerticallySortedAscendingly(points: [VNPoint]) -> Bool {
    if points.isEmpty {
        return false
    }
    var currentY = points[0].y
    for i in stride(from: 1, to: points.count, by: 1) {
        let point = points[i]
        if currentY > point.y {
            return false
        }
        currentY = point.y
    }
    return true
}

/// Checks if the list of `VNPoint` are sorted in a horizontally ascending manner.
public func vnPointsAreHorizontallySortedAscendingly(points: [VNPoint]) -> Bool {
    if points.isEmpty {
        return false
    }
    var currentX = points[0].x
    for i in stride(from: 1, to: points.count, by: 1) {
        let point = points[i]
        if currentX > point.x {
            return false
        }
        currentX = point.x
    }
    return true
}

/// Gets the angle from 3 `CGPoint`.
///
/// Uses the Cosine Rule to derive the angle, with `b` being the vertex of the 3 points.
public func getAngleFromThreeCGPoints(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
    let ab: Double = sqrtl(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    let bc: Double = sqrtl(pow(b.x - c.x, 2) + pow(b.y - c.y, 2))
    let ac: Double = sqrtl(pow(a.x - c.x, 2) + pow(a.y - c.y, 2))
    let angle: Double = (pow(ab, 2) + pow(bc, 2) - pow(ac, 2)) / (2 * ab * bc)
    return acos(angle) * 180 / Double.pi
}

//TODO: function for getting angle from CGPoints

/// Checks if the list of `CGPoint` are sorted in a vertically ascending manner.
public func cgPointsAreVerticallySortedAscendingly(points: [CGPoint]) -> Bool {
    if points.isEmpty {
        return false
    }
    var currentY = points[0].y
    for i in stride(from: 1, to: points.count, by: 1) {
        let point = points[i]
        if currentY > point.y {
            return false
        }
        currentY = point.y
    }
    return true
}

/// Checks if the list of `CGPoint` are sorted in a horizontally ascending manner.
public func cgPointsAreHorizontallySortedAscendingly(points: [CGPoint]) -> Bool {
    if points.isEmpty {
        return false
    }
    var currentX = points[0].x
    for i in stride(from: 1, to: points.count, by: 1) {
        let point = points[i]
        if currentX > point.x {
            return false
        }
        currentX = point.x
    }
    return true
}

