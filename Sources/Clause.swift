//
//  Clause.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation

public protocol ClauseLocalizable: ExpressibleByStringInterpolation {
	typealias KeyPrefix = (String) -> String?
	/// The resulting string
	func localization(_ table: String, prefix: KeyPrefix?) -> String
}

public struct Clause: ClauseLocalizable {
	public typealias Logger = (String) -> Void
	public static var logMessage: Logger  = { print($0) }

	private let rawKey: String
	private let parameters: [String : PlaceholderValuePairing]

	public init(stringLiteral value: StringLiteralType) {
		rawKey = value
		parameters = [:]
	}
	public init(stringInterpolation: StringInterpolation) {
		rawKey = stringInterpolation.literal
		parameters = stringInterpolation.arguments
	}

	public func localization(_ table: String = "Localizable", prefix: KeyPrefix? = nil) -> String {
		typealias NamedMatch = (name: String, matchedPattern: String)

		var key = rawKey
		if let prefix = prefix?(rawKey), !prefix.isEmpty {
			key = prefix + "." + rawKey
		}
		let rawLocalization =  NSLocalizedString(key, tableName: table, value: key, comment: "")

		if rawLocalization == key {
			let logMsg = "Clause-warning: \(#file) | \(#function) | \(#line) - Key “\(key)” not found in strings file with name “\(table)”."
			Clause.logMessage(logMsg)
		}
		if rawLocalization.isEmpty {
			let logMsg = "Clause-warning: \(#file) | \(#function) | \(#line) - Value for key “\(key)” is empty in strings file with name “\(table)”."
			Clause.logMessage(logMsg)
		}

		// If no interpolations were found in the original string literal, just return the localized string as read from the strings-file
		guard !parameters.isEmpty else { return rawLocalization	}

		// Regex to find patterns like "\("name:", %@)"
		let regex = #"\\\((.+?)\)"#
		guard let regexParser = try? NSRegularExpression(pattern: regex, options: [.caseInsensitive]) else { return rawLocalization }

		let matches = regexParser.matches(in: rawLocalization, range: NSRange(rawLocalization.startIndex..<rawLocalization.endIndex, in: rawLocalization))

		let namedMatches = matches.compactMap { (textResult) -> NamedMatch? in
			// Return nil if no match was found
			guard let range = Range(textResult.range, in: rawLocalization) else { return nil }

			let matchedPattern = String(rawLocalization[range])
			let name = String(matchedPattern.dropLast().dropFirst(2))
			return NamedMatch(name, matchedPattern)
		}

		// Replace the matches with their placeholders. i.e. from "\(name)" to "%@"
		let format = namedMatches.reduce(rawLocalization) { result, namedMatch in
			guard let placeholder = parameters[namedMatch.name]?.placeholder else {
				let validPlaceholdersString = parameters.reduce("") { result, argument -> String in
					return result + "“\(argument.key)”, "
				}
				// dropLast(2) to remove the last ", "
				let logMsg = "Clause-error: \(#file) | \(#function) | \(#line) - Invalid placeholder name “\(namedMatch.name)”. Valid names are: \(validPlaceholdersString.dropLast(2))"
				Clause.logAssertion(logMsg)
				return ""
			}
			return result.replacingOccurrences(of: namedMatch.matchedPattern, with: placeholder)
		}

		// Get the argument values by retrieving them from the parameters dict with the name of the match
		let values: [CVarArg] = namedMatches.compactMap {
			guard let value = parameters[$0.name]?.value else { return nil }
			return value
		}

		guard namedMatches.count == values.count else  {
			let logMsg = "Clause-warning: \(#file) | \(#function) | \(#line) - Unmatched number of placeholders and values. Expected “\(namedMatches.count)” got “\(values.count)”"
			Clause.logAssertion(logMsg)
			return rawLocalization
		}

		return String(format: format, arguments: values)
	}

	private static func logAssertion(_ message: String) {
		assertionFailure(message)
		Clause.logMessage(message)
	}
}

extension Clause {

	// Required by the ExpressibleByStringInterpolation protocol.
	// It collects the literals and the interpolations
	public struct StringInterpolation: StringInterpolationProtocol {
		fileprivate var literal = ""
		fileprivate var arguments:[String: PlaceholderValuePairing] = [:]

		// allocate enough space to hold twice the amount of literal text
		public init(literalCapacity: Int, interpolationCount: Int) {
			literal.reserveCapacity(literalCapacity * 2)
		}

		public mutating func appendLiteral(_ literal: String) {
			// Escape any % characters in the literal.
			self.literal.append(contentsOf: literal.lazy.flatMap { $0 == "%" ? "%%" : String($0) })
		}

		public mutating func appendInterpolation<T: PlaceholderValuePairing>(_ literal: String, _ placeholderValuePair: T) {
			guard let literal = parseLiteral(literal, placeholder: placeholderValuePair.placeholder) else { return }
			self.literal.append(literal.placeholder)
			arguments[literal.name] = placeholderValuePair
		}

		public mutating func appendInterpolation<T: PlaceholderValueFormatting>(_ literal: String, _ placeholderValuePair: T, format: T.Style? = nil) {
			// if a format was given, use the struct instead of the original, because we need to store the style
			let placeholderWithValue: PlaceholderValuePairing = format == nil ? placeholderValuePair : FormatablePlaceholderValuePair(placeholderValuePair, style: format!)
			guard let literal = parseLiteral(literal, placeholder: placeholderWithValue.placeholder) else { return }
			self.literal.append(literal.placeholder)
			arguments[literal.name] = placeholderWithValue
		}

		private func parseLiteral(_ literal: String, placeholder: String) -> (name: String, placeholder: String)? {
			let name = trimSuffix(":", from: literal)
			guard isUniqueKey(name) else { return nil }
			return (name: name, placeholder: "\\"+"(\(name))")
		}
		private func isUniqueKey(_ key: String) -> Bool {
			guard arguments.index(forKey: key) == nil else {
				let logMsg:String = "Clause-error: \(#file) | \(#function) | \(#line) - Placeholder names must be unique. Found “\(key)” more than once."
				Clause.logAssertion(logMsg)
				return false
			}
			return true
		}
		private func trimSuffix(_ suffix: String, from literal: String) -> String {
			var literal = literal
			if literal.hasSuffix(suffix) {
				literal.removeLast(suffix.count)
			}
			return literal
		}
	}
}
