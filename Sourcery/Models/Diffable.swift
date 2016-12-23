//
//  Diffable.swift
//  Sourcery
//
//  Created by Krzysztof Zabłocki on 22/12/2016.
//  Copyright © 2016 Pixle. All rights reserved.
//

import Foundation

protocol Diffable {

    /// Returns `DiffableResult` for the given objects.
    ///
    /// - Parameter object: Object to diff against.
    /// - Returns: Diffable results.
    func diffAgainst(_ object: Any?) -> DiffableResult
}

/// Phantom protocol for code generation
protocol AutoDiffable {}

@objc class DiffableResult: NSObject {
    private var results: [String]
    internal var identifier: String?

    init(results: [String] = [], identifier: String? = nil) {
        self.results = results
        self.identifier = identifier
    }

    func append(_ element: String) {
        results.append(element)
    }

    func append(contentsOf contents: DiffableResult) {
        if !contents.isEmpty {
            results.append(contents.description)
        }
    }

    var isEmpty: Bool { return results.isEmpty }

    override var description: String {
        guard !results.isEmpty else { return "" }
        return "\(identifier.flatMap { "\($0) " } ?? "")" + results.joined(separator: "\n")
    }
}

extension DiffableResult {

    @discardableResult func trackDifference<T: Equatable>(actual: T, expected: T) -> DiffableResult {
        if actual != expected {
            let result = DiffableResult(results: ["<expected: \(actual), received: \(expected)>"])
            append(contentsOf: result)
        }
        return self
    }

    @discardableResult func trackDifference<T: Equatable>(actual: T?, expected: T?) -> DiffableResult {
        if actual != expected {
            let result = DiffableResult(results: ["<expected: \(actual), received: \(expected)>"])
            append(contentsOf: result)
        }
        return self
    }

    @discardableResult func trackDifference<T: Equatable>(actual: T, expected: T) -> DiffableResult where T: Diffable {
        let diffResult = actual.diffAgainst(expected)
        append(contentsOf: diffResult)
        return self
    }

    @discardableResult func trackDifference<T: Equatable>(actual: [T], expected: [T]) -> DiffableResult where T: Diffable {
        let diffResult = DiffableResult()
        defer { append(contentsOf: diffResult) }

        guard actual.count == expected.count else {
            diffResult.append("Different count \(actual.count) vs \(expected.count)")
            return self
        }

        for (idx, item) in actual.enumerated() {
            let diff = DiffableResult()
            diff.trackDifference(actual: item, expected: expected[idx])
            if !diff.isEmpty {
                let string = "idx \(idx): \(diff)"
                diffResult.append(string)
            }
        }

        return self
    }

    @discardableResult func trackDifference<T: Equatable>(actual: [T], expected: [T]) -> DiffableResult {
        let diffResult = DiffableResult()
        defer { append(contentsOf: diffResult) }

        guard actual.count == expected.count else {
            diffResult.append("Different count \(actual.count) vs \(expected.count)")
            return self
        }

        for (idx, item) in actual.enumerated() {
            if item != expected[idx] {
                let string = "idx \(idx): <expected: \(actual), received: \(expected)>"
                diffResult.append(string)
            }
        }

        return self
    }

    @discardableResult func trackDifference<K: Equatable, T: Equatable>(actual: [K: T], expected: [K: T]) -> DiffableResult where T: Diffable {
        let diffResult = DiffableResult()
        defer { append(contentsOf: diffResult) }

        guard actual.count == expected.count else {
            append("Different count \(actual.count) vs \(expected.count)")

            if expected.count > actual.count {
                let missingKeys = Array(expected.keys.filter {
                    actual[$0] == nil
                }.map {
                    String(describing: $0)
                })
                diffResult.append("Missing keys: \(missingKeys.joined(separator: ", "))")
            }
            return self
        }

        for (key, actualElement) in actual {
            guard let expectedElement = expected[key] else {
                diffResult.append("Missing key \"\(key)\"")
                continue
            }

            let diff = DiffableResult()
            diff.trackDifference(actual: actualElement, expected: expectedElement)
            if !diff.isEmpty {
                let string = "key \"\(key)\": \(diff)"
                diffResult.append(string)
            }
        }

        return self
    }

// MARK: - NSObject diffing

    @discardableResult func trackDifference<K: Equatable, T: NSObjectProtocol>(actual: [K: T], expected: [K: T]) -> DiffableResult {
        let diffResult = DiffableResult()
        defer { append(contentsOf: diffResult) }

        guard actual.count == expected.count else {
            append("Different count \(actual.count) vs \(expected.count)")

            if expected.count > actual.count {
                let missingKeys = Array(expected.keys.filter {
                    actual[$0] == nil
                    }.map {
                        String(describing: $0)
                })
                diffResult.append("Missing keys: \(missingKeys.joined(separator: ", "))")
            }
            return self
        }

        for (key, actualElement) in actual {
            guard let expectedElement = expected[key] else {
                diffResult.append("Missing key \"\(key)\"")
                continue
            }

            if !actualElement.isEqual(expectedElement) {
                diffResult.append("key \"\(key)\": <expected: \(actual), received: \(expected)>")
            }
        }

        return self
    }
}