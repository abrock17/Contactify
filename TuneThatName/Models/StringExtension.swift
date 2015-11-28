//
//  StringExtension.swift
//  TuneThatName
//
//  Created by Tony Brock on 11/28/15.
//  Copyright © 2015 Tony Brock. All rights reserved.
//

import Foundation

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
