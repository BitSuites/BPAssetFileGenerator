//
//  FileWriter.swift
//  BPAssetFileGenerator
//
//  Created by Justin Carstens on 10/10/17.
//  Copyright © 2017 BitSuties. All rights reserved.
//

import Foundation

class FileWriter: NSObject {
    
    var scriptName: String!
    var fileTypes: String!
    var fileName: String!
    var outputBasePath: String!
    var outputFileName: String!
    var outputMethods: [String] = []
    var warningMessage: String?
    var singleFile: Bool = true

    func writeOutputFile() {
        if outputMethods.count == 0 {
            // Nothing to write
            return
        }
        outputFileName = outputFileName.replacingOccurrences(of: " ", with: "")
        
        // Setup the header of the file
        var outputFileContent = ""
        outputFileContent.append("//\n")
        if singleFile {
            outputFileContent.append("// This file is generated from all " + fileTypes + " files by " + scriptName + ".\n")
        } else {
            outputFileContent.append("// This file is generated from " + fileName + " by " + scriptName + ".\n")
        }
        outputFileContent.append("// Please do not edit.\n")
        outputFileContent.append("//\n\n")
        outputFileContent.append("import UIKit\n\n")
        outputFileContent.append("class " + outputFileName + ": NSObject {\n\n")
        
        // If there is a warning message add it
        if warningMessage != nil {
            outputFileContent.append(warningMessage!)
        }
        
        // Sort all methods alphabetically
        outputMethods.sort()
        for nextMethod in outputMethods {
            outputFileContent.append(nextMethod)
        }
        
        outputFileContent.append("}\n")
        
        // Write the output to a file.
        do {
            let outputPath = (outputBasePath as NSString).appendingPathComponent(outputFileName + ".swift")
            try outputFileContent.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
        } catch {}
    }
    
}
