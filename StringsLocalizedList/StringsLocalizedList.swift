//
//  StringsLocalizedList.swift
//  StringsLocalizedList
//
//  Created by Justin Carstens on 10/11/17.
//  Copyright © 2017 BitSuties. All rights reserved.
//

import Foundation

class StringsLocalizedList: ListGeneratorHelper {
    
    var needTranslationKeys: [String] = []
    let needTranslationText = " // Needs Translation"
    
    override class func fileExtensions() -> [String] {
        return ["strings"]
    }
    
    override class func newHelper() -> ListGeneratorHelper {
        return StringsLocalizedList()
    }
    
    override func startGeneratingInfo() {
        // Get the file name with prefix and any additional info.
        let fileName = ((parseFilePath as NSString).lastPathComponent as NSString).deletingPathExtension
        if singleFile {
            fileWriter.outputFileName = classPrefix + "Strings"
        } else {
            fileWriter.outputFileName = classPrefix + "\(fileName)Strings"
        }
        
        // Determine if this is the main file or a translation file
        var hasTranslations = false
        let lprojPath = (parseFilePath as NSString).deletingLastPathComponent
        if lprojPath.hasSuffix(".lproj") {
            if !lprojPath.hasSuffix("Base.lproj") {
                // This is a translation file and not the main one so skip.
                return
            }
            // Update all translation files
            hasTranslations = synchronizeFiles()
        }
        
        // If we are verify and we need to add translations add warning messge
        if verify && needTranslationKeys.count > 0 {
            // Add Warning Message to output file
            var missingImageMessage = ""
            missingImageMessage.append("    /// Warning message so console is notified.\n")
            missingImageMessage.append("    @available(iOS, deprecated: 1.0, message: \"Missing Translation\")\n")
            missingImageMessage.append("    private static func NeedsTranslation(){}\n\n")
            
            if fileWriter.warningMessage == nil {
                fileWriter.warningMessage = missingImageMessage
            } else  if !fileWriter.warningMessage!.contains("NeedsTranslation") {
                fileWriter.warningMessage!.append(missingImageMessage)
            }
        }
        
        if let stringsDictionary = NSDictionary(contentsOfFile: parseFilePath) as? [String : String] {
            for (nextKey, nextValue) in stringsDictionary {
                let localizedString = nextValue.replacingOccurrences(of: "\n", with: "\\n")
                let methodName = ListGeneratorHelper.methodName(nextKey)
                
                // Add String to the file
                var implementation = ""
                implementation.append("    /// \(localizedString)\n")
                implementation.append("    static var \(methodName): String {\n")
                if hasTranslations {
                    if verify && needTranslationKeys.contains(nextKey) {
                        implementation.append("        NeedsTranslation()\n")
                    }
                    implementation.append("        return NSLocalizedString(\"\(nextKey)\", tableName: \"\(fileName)\", comment: \"\(localizedString)\")\n")
                } else {
                    implementation.append("        return \"\(localizedString)\"\n")
                }
                implementation.append("    }\n\n")
                fileWriter.outputMethods.append(implementation)
            }
        }
    }
    
    private func synchronizeFiles() -> Bool {
        var hasTranslations = false
        
        let currentFileFolder = ((parseFilePath as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        var mainString = ""
        var mainComponents: [String]!
        for nextFile in allFilePaths {
            if nextFile == parseFilePath || (parseFilePath as NSString).lastPathComponent != (nextFile as NSString).lastPathComponent {
                // Not the same strings file
                continue
            }
            let nextFileFolder = ((nextFile as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
            if currentFileFolder != nextFileFolder {
                // Not the same strings file
                continue
            }
            // Get the components of the main file if we haven't already
            if mainString.isEmpty {
                do {
                    mainString = try String(contentsOf: URL(fileURLWithPath: parseFilePath), encoding: .utf8)
                    mainComponents = mainString.components(separatedBy: CharacterSet.newlines)
                } catch {
                    continue
                }
            }
            
            // Get the components of the next file
            var nextFileString: String!
            do {
                nextFileString = try String(contentsOf: URL(fileURLWithPath: nextFile), encoding: .utf8)
            } catch {
                continue
            }
            
            let nextFileComponents = nextFileString.components(separatedBy: CharacterSet.newlines)
            
            // Start Adding all the appropriate tranlations to the files
            var translationFile = ""
            for nextMainComponent in mainComponents {
                if !nextMainComponent.hasPrefix("\"") {
                    translationFile.append(nextMainComponent)
                } else {
                    if let translation = stringForKey(keyForComponent(nextMainComponent), components: nextFileComponents) {
                        translationFile.append(translation)
                    } else {
                        translationFile.append(nextMainComponent + needTranslationText)
                    }
                }
                translationFile.append("\n")
            }
            translationFile = "\(translationFile.dropLast())"
            
            // Only create the file if the user wants the helper code enabled.
            // We still go through the creation of the file because of seeing which items need translation.
            if helper {
                do {
                    try translationFile.write(to: URL(fileURLWithPath: nextFile), atomically: true, encoding: .utf8)
                } catch {}
            }
            
            hasTranslations = true
        }
        return hasTranslations
    }
    
    private func stringForKey(_ key: String?, components: [String]) -> String? {
        if key == nil {
            return nil
        }
        for nextComponent in components {
            if nextComponent.hasPrefix("\"") {
                if key == keyForComponent(nextComponent) {
                    if nextComponent.hasSuffix(needTranslationText) {
                        needTranslationKeys.append(key!)
                    }
                    return nextComponent
                }
            }
        }
        needTranslationKeys.append(key!)
        return nil
    }
    
    private func keyForComponent(_ component: String) -> String? {
        let keys = component.components(separatedBy: "\"")
        if keys.count > 1 {
            return keys[1]
        }
        return nil
    }
}
