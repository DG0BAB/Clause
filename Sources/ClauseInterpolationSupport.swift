//
//  ClauseInterpolationSupport.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation

/** Combines a placeholder i.e. %@, %d, %f, etc.
with a value.

`placeholder` can be used in the format String in one of the
`String(format:, CVarArg...)` initialisers. While `value` represents the argument
*/
public protocol PlaceholderValuePairing {
	/// Placeholder i.e. %@, %d, %f
	var placeholder: String { get }

	/// Value for the placeholder
	var value: CVarArg { get }
}

// MARK: - Type conformances to PlaceholderValuePairing

// Extend `String` to conform to `PlaceholderValuePairing`
extension String: PlaceholderValuePairing {
	/// Returns `%@`
	public var placeholder: String { return "%@" }

	/// Return this `String` as a `CVarArg`
	public var value: CVarArg { return String(self) }
}

// Extend `Date` to conform to `PlaceholderValuePairing`
extension Date: PlaceholderValuePairing {
	/// Returns `%@`
	public var placeholder: String { return "%@" }

	/// Return a `String` describing this `Date` as a `CVarArg`
	public var value: CVarArg { return String(describing: self) }
}

// Extend `Int` to conform to `PlaceholderValuePairing`
extension Int: PlaceholderValuePairing {
	/// Returns `%d`
	public var placeholder: String { return "%d" }

	/// Return this `Int` as a `CVarArg`
	public var value: CVarArg { return Int(self) }
}

// Extend `Float` to conform to `PlaceholderValuePairing`
extension Float: PlaceholderValuePairing {
	/// Returns `%f`
	public var placeholder: String { return "%f" }

	/// Return this `Float` as a `CVarArg`
	public var value: CVarArg { return Float(self) }
}

// Extend `Double` to conform to `PlaceholderValuePairing`
extension Double: PlaceholderValuePairing {
	/// Returns `%lf`
	public var placeholder: String { return "%lf" }

	/// Return this `Double` as a `CVarArg`
	public var value: CVarArg { return Double(self) }
}

// If the Optional has some value and the value's type
// conforms to the PlaceholderValuePairing protocol,
// placeholder string and value are taken from that type
// Otherwise "%@" is returned for the placeholder and
// "nil" for the value.
extension Optional: PlaceholderValuePairing where Wrapped: PlaceholderValuePairing {
	public var placeholder: String { return asPVP?.placeholder ?? "%@" }
	public var value: CVarArg {	return asPVP?.value ?? "nil" }

	var asPVP: PlaceholderValuePairing? {
		guard
			case .some(let wrapped) = self else { return nil }
		return wrapped
	}
}

// MARK: - Placeholder Formatting

/** A different kind of `PlaceholderValuePairing` with support
of formatting the value.

Especially useful if value is a `Date` or number.
*/
public protocol PlaceholderValueFormatting: PlaceholderValuePairing {
	/// The Style that is used by the associated formatter
	associatedtype Style
	var formatedPlaceholder: String { get }
	func formatedValue(style: Style) -> CVarArg
}

extension PlaceholderValueFormatting {
	// Return the default formated placeholder for none specifc types
	public var formatedPlaceholder: String {
		return self.placeholder
	}
}

/** Combines a `PlaceholderValuePairing` with a `Style` which is
used for formatting the value.

Conforms to `PlaceholderValuePairing` so this struct can be used as such.
*/
struct FormatablePlaceholderValuePair<T: PlaceholderValueFormatting>: PlaceholderValuePairing {
	fileprivate let wrapped: T
	fileprivate let style: T.Style

	init(_ other: T, style: T.Style) {
		self.wrapped = other
		self.style = style
	}
	var placeholder: String { return wrapped.formatedPlaceholder }
	var value: CVarArg { return wrapped.formatedValue(style: style) }
}

// MARK: - Type conformances to PlaceholderValueFormatting

// Make `Date` values formatable
extension Date: PlaceholderValueFormatting {
	/// `Date` uses the `DateFormatter.Style`
	public typealias Style = DateFormatter.Style

	/// The formatted `Date` according to the given style
	public func formatedValue(style: Style) -> CVarArg {
		let formatter = DateFormatter()
		formatter.timeStyle = style
		formatter.dateStyle = style
		return formatter.string(from: self)
	}
}

// Make `Int` values formatable
extension Int: PlaceholderValueFormatting {
	/// `Int` uses the `NumberFormatter.Style`
	public typealias Style = NumberFormatter.Style

	/// Placeholder for formated `Int` is %@ instead of %d.
	public var formatedPlaceholder: String { return "%@" }

	/// The formated `Int` according to the given style
	public func formatedValue(style: Style) -> CVarArg {
		return NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
	}
}

// Make `Float` values formatable
extension Float: PlaceholderValueFormatting {
	/// `Int` uses the `NumberFormatter.Style`
	public typealias Style = NumberFormatter.Style

	/// Placeholder for formated `Float` is %@ instead of %f.
	public var formatedPlaceholder: String { return "%@" }

	/// The formated `Float` according to the given style
	public func formatedValue(style: Style) -> CVarArg {
		return NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
	}
}

// Make `Double` values formatable
extension Double: PlaceholderValueFormatting {
	/// `Double` uses the `NumberFormatter.Style`
	public typealias Style = NumberFormatter.Style

	/// Placeholder for formated `Double` is %@ instead of %lf.
	public var formatedPlaceholder: String { return "%@" }

	/// The formated `Double` according to the given style
	public func formatedValue(style: Style) -> CVarArg {
		return NumberFormatter.localizedString(from: NSNumber(value: self), number: style)
	}
}
