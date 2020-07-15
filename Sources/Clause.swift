//
//  Clause.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation
import PetiteLogger

public protocol ClauseLocalizable: ExpressibleByStringInterpolation {
	typealias KeyPrefix = (String) -> String?

	/// The resulting string
	func localization(_ table: String, prefix: KeyPrefix?) -> String
}

private typealias Log = PetiteLogger.Logger

public struct Clause: ClauseLocalizable {
	public static var parameterEscape = "@"

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
		if let prefix = prefix?(rawKey),
			!prefix.isEmpty {
			key = prefix + "." + rawKey
		}
		let rawLocalization =  NSLocalizedString(key, tableName: table, value: key, comment: "")

		if rawLocalization == key {
			Log.warning("Key “\(key)” not found in strings file with name “\(table)”.")
		}
		if rawLocalization.isEmpty {
			Log.warning("Value for key “\(key)” is empty in strings file with name “\(table)”.")
		}

		// If no interpolations were found in the original string literal, just return the localized string as read from the strings-file
		guard !parameters.isEmpty else { return rawLocalization	}

		// Find patterns like "\("name:", %@)" with a Regular-Expression-Parser
		guard let regexParser = Self.regexParser else { return rawLocalization }
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
				Log.error("Invalid placeholder name “\(namedMatch.name)”. Valid names are: \(validPlaceholdersString.dropLast(2))")
				return rawLocalization
			}
			return result.replacingOccurrences(of: namedMatch.matchedPattern, with: placeholder)
		}

		// Get the argument values by retrieving them from the parameters dict with the name of the match
		let values: [CVarArg] = namedMatches.compactMap {
			guard let value = parameters[$0.name]?.value else { return nil }
			return value
		}

		guard namedMatches.count == values.count else  {
			Log.warning("Unmatched number of placeholders and values. Expected “\(namedMatches.count)” got “\(values.count)”")
			return rawLocalization
		}

		return String(format: format, arguments: values)
	}

	private static let regexParser: NSRegularExpression? = {
		return try? NSRegularExpression(pattern: #"\\\((.+?)\)"#, options: [.caseInsensitive])
	}()
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

		public mutating func appendInterpolation<T: PlaceholderValuePairing>(_ parameterName: String, _ placeholderValuePair: T) {
			guard let processedParameterName = processParameterName(parameterName) else { return }
			self.literal.append(processedParameterName.escapedName)
			arguments[processedParameterName.trimmedName] = placeholderValuePair
		}

		public mutating func appendInterpolation<T: PlaceholderValueFormatting>(_ parameterName: String, _ placeholderValuePair: T, format: T.Style? = nil) {
			// if a format was given, use the struct instead of the original, because we need to store the style
			let placeholderWithValue: PlaceholderValuePairing = format == nil ? placeholderValuePair : FormatablePlaceholderValuePair(placeholderValuePair, style: format!)
			guard let processedParameterName = processParameterName(parameterName) else { return }
			self.literal.append(processedParameterName.escapedName)
			arguments[processedParameterName.trimmedName] = placeholderWithValue
		}

		private func processParameterName(_ parameterName: String) -> (trimmedName: String, escapedName: String)? {
			let name = trimSuffix(":", from: parameterName)
			guard isUniqueKey(name) else { return nil }
			return (trimmedName: name, escapedName: "\(Clause.parameterEscape)(\(name))")
		}
		private func isUniqueKey(_ key: String) -> Bool {
			guard arguments.index(forKey: key) == nil else {
				Log.error("Placeholder names must be unique. Found “\(key)” more than once.")
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
