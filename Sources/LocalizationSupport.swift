//
//  LocalizationSupport.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation

public protocol StringsFileNameProviding {
	static var baseStringsFileName: String { get }
}

extension StringsFileNameProviding {
	public static var baseStringsFileName: String {
		return "Localizable"
	}
}
