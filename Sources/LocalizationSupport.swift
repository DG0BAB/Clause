//
//  LocalizationSupport.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation

public protocol LocalizationMetadataProviding {
	/// The strings file the localizations are stored in
	/// Defaults to `Localizable`.string
	static var stringsFileName: String { get }

	/// The `Bundle` the strings file is stored in
	/// Defaults to the main Bundle of the module
	static var bundle: Bundle { get }
}

extension LocalizationMetadataProviding {
	public static var stringsFileName: String {
		return "Localizable"
	}
	public static var bundle: Bundle {
		return Bundle.main
	}
}
