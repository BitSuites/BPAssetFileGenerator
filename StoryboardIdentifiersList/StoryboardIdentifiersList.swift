//
//  StoryboardIdentifiersList.swift
//  StoryboardIdentifiersList
//
//  Created by Justin Carstens on 10/11/17.
//  Copyright © 2017 BitSuties. All rights reserved.
//

import Foundation

class StoryboardIdentifiersList: ListGeneratorHelper {
    
    var keys: [String] = []
    
    override class func fileExtensions() -> [String] {
        return ["storyboard", "xib"]
    }
    
    override class func newHelper() -> ListGeneratorHelper {
        return StoryboardIdentifiersList()
    }
    
    override func startGeneratingInfo() {
        // Get the File Name
        let fileExtension = ListGeneratorHelper.capitalizedString((parseFilePath as NSString).pathExtension)
        let fileName = ((parseFilePath as NSString).lastPathComponent as NSString).deletingPathExtension
        let formattedFilename = fileName.replacingOccurrences(of: " ", with: "")
        let containsExtensionText = formattedFilename.lowercased().contains(fileExtension.lowercased())
        var methodName = "Name"
        if singleFile {
            fileWriter.outputFileName = classPrefix + "Identifiers"
            methodName = formattedFilename + fileExtension + "Name"
        } else if containsExtensionText {
            fileWriter.outputFileName = classPrefix + formattedFilename + "Identifiers"
        } else {
            fileWriter.outputFileName = classPrefix + formattedFilename + fileExtension + "Identifiers"
        }
        
        // Write the storyboard name to the file
        writeItemToFile(fileName, methodName: methodName)
        
        // Parse all the Identifiers
        do {
            let document: XMLDocument = try XMLDocument(contentsOf: URL(fileURLWithPath: parseFilePath), options: XMLNode.Options())
            var identifiers: [XMLNode] = []
            identifiers.append(contentsOf: try document.nodes(forXPath: "//@storyboardIdentifier"))
            identifiers.append(contentsOf: try document.nodes(forXPath: "//@reuseIdentifier"))
            identifiers.append(contentsOf: try document.nodes(forXPath: "//segue/@identifier"))
            
            // Write each identifier to the file
            for nextIdentifier in identifiers {
                writeItemToFile(nextIdentifier.stringValue!)
            }
        } catch {}
    }
    
    private func writeItemToFile(_ value: String, methodName: String? = nil) {
        var finalMethodName: String
        if methodName == nil {
            finalMethodName = ListGeneratorHelper.capitalizedString(ListGeneratorHelper.methodName(value))
        } else {
            finalMethodName = methodName!
        }
        if !verify && keys.contains(finalMethodName) {
            // We are not verifying and this key already exists.
            return
        }
        keys.append(finalMethodName)
        
        // Generate Method for file
        var implementation = ""
        implementation.append("    /// \(value) Identifier\n")
        implementation.append("    static var \(finalMethodName): String {\n")
        implementation.append("        return \"\(value)\"\n")
        implementation.append("    }\n\n")
        fileWriter.outputMethods.append(implementation)
    }
    
}
