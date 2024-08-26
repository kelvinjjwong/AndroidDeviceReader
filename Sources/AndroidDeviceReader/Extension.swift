//
//  File.swift
//  
//
//  Created by Kelvin Wong on 2024/8/26.
//

import Foundation

extension String {
    
    
    func isFileExists() -> Bool {
        if FileManager.default.fileExists(atPath: self) {
            return true
        }
        return false
    }
}
