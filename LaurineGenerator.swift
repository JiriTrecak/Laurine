#!/usr/bin/env xcrun -sdk macosx swift

//
// Laurine - Storyboard Generator Script
//
// Generate swift localization file based on localizables.string
//
// Usage:
// laurine.swift Main.storyboard > Output.swift
//
// Licence: MIT
// Author: Jiří Třečák http://www.jiritrecak.com @jiritrecak
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - CommandLine Tool

/* NOTE *
* I am using command line tool for parsing of the input / output arguments. Since static frameworks are not yet
* supported, I just hardcoded entire project to keep it.
* For whoever is interested in the project, please check their repository. It rocks!
* I'm not an author of the code that follows. Licence kept intact.
*
* https://github.com/jatoben/CommandLine
*
*/


/*
* CommandLine.swift, Option.swift, StringExtensions.swift
* Copyright (c) 2014 Ben Gollmer.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/* Required for setlocale(3) */
@exported import Darwin

let ShortOptionPrefix = "-"
let LongOptionPrefix = "--"

/* Stop parsing arguments when an ArgumentStopper (--) is detected. This is a GNU getopt
* convention; cf. https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html
*/
let ArgumentStopper = "--"

/* Allow arguments to be attached to flags when separated by this character.
* --flag=argument is equivalent to --flag argument
*/
let ArgumentAttacher: Character = "="

/* An output stream to stderr; used by CommandLine.printUsage(). */
private struct StderrOutputStream: OutputStreamType {
    static let stream = StderrOutputStream()
    func write(s: String) {
        fputs(s, stderr)
    }
}

/**
 * The CommandLine class implements a command-line interface for your app.
 *
 * To use it, define one or more Options (see Option.swift) and add them to your
 * CommandLine object, then invoke `parse()`. Each Option object will be populated with
 * the value given by the user.
 *
 * If any required options are missing or if an invalid value is found, `parse()` will throw
 * a `ParseError`. You can then call `printUsage()` to output an automatically-generated usage
 * message.
 */
public class CommandLine {
    private var _arguments: [String]
    private var _options: [Option] = [Option]()
    
    /** A ParseError is thrown if the `parse()` method fails. */
    public enum ParseError: ErrorType, CustomStringConvertible {
        /** Thrown if an unrecognized argument is passed to `parse()` in strict mode */
        case InvalidArgument(String)
        
        /** Thrown if the value for an Option is invalid (e.g. a string is passed to an IntOption) */
        case InvalidValueForOption(Option, [String])
        
        /** Thrown if an Option with required: true is missing */
        case MissingRequiredOptions([Option])
        
        public var description: String {
            switch self {
            case let .InvalidArgument(arg):
                return "Invalid argument: \(arg)"
            case let .InvalidValueForOption(opt, vals):
                let vs = vals.joinWithSeparator(", ")
                return "Invalid value(s) for option \(opt.flagDescription): \(vs)"
            case let .MissingRequiredOptions(opts):
                return "Missing required options: \(opts.map { return $0.flagDescription })"
            }
        }
    }
    
    /**
     * Initializes a CommandLine object.
     *
     * - parameter arguments: Arguments to parse. If omitted, the arguments passed to the app
     *   on the command line will automatically be used.
     *
     * - returns: An initalized CommandLine object.
     */
    public init(arguments: [String] = Process.arguments) {
        self._arguments = arguments
        
        /* Initialize locale settings from the environment */
        setlocale(LC_ALL, "")
    }
    
    /* Returns all argument values from flagIndex to the next flag or the end of the argument array. */
    private func _getFlagValues(flagIndex: Int) -> [String] {
        var args: [String] = [String]()
        var skipFlagChecks = false
        
        /* Grab attached arg, if any */
        var attachedArg = _arguments[flagIndex].splitByCharacter(ArgumentAttacher, maxSplits: 1)
        if attachedArg.count > 1 {
            args.append(attachedArg[1])
        }
        
        for var i = flagIndex + 1; i < _arguments.count; i++ {
            if !skipFlagChecks {
                if _arguments[i] == ArgumentStopper {
                    skipFlagChecks = true
                    continue
                }
                
                if _arguments[i].hasPrefix(ShortOptionPrefix) && Int(_arguments[i]) == nil &&
                    _arguments[i].toDouble() == nil {
                        break
                }
            }
            
            args.append(_arguments[i])
        }
        
        return args
    }
    
    /**
     * Adds an Option to the command line.
     *
     * - parameter option: The option to add.
     */
    public func addOption(option: Option) {
        _options.append(option)
    }
    
    /**
     * Adds one or more Options to the command line.
     *
     * - parameter options: An array containing the options to add.
     */
    public func addOptions(options: [Option]) {
        _options += options
    }
    
    /**
     * Adds one or more Options to the command line.
     *
     * - parameter options: The options to add.
     */
    public func addOptions(options: Option...) {
        _options += options
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: An array containing the options to set.
     */
    public func setOptions(options: [Option]) {
        _options = options
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: The options to set.
     */
    public func setOptions(options: Option...) {
        _options = options
    }
    
    /**
     * Parses command-line arguments into their matching Option values. Throws `ParseError` if
     * argument parsing fails.
     *
     * - parameter strict: Fail if any unrecognized arguments are present (default: false).
     */
    public func parse(strict: Bool = false) throws {
        for (idx, arg) in _arguments.enumerate() {
            if arg == ArgumentStopper {
                break
            }
            
            if !arg.hasPrefix(ShortOptionPrefix) {
                continue
            }
            
            let skipChars = arg.hasPrefix(LongOptionPrefix) ?
                LongOptionPrefix.characters.count : ShortOptionPrefix.characters.count
            let flagWithArg = arg[Range(start: arg.startIndex.advancedBy(skipChars), end: arg.endIndex)]
            
            /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
            if flagWithArg.isEmpty {
                continue
            }
            
            /* Remove attached argument from flag */
            let flag = flagWithArg.splitByCharacter(ArgumentAttacher, maxSplits: 1)[0]
            
            var flagMatched = false
            for option in _options where option.flagMatch(flag) {
                let vals = self._getFlagValues(idx)
                guard option.setValue(vals) else {
                    throw ParseError.InvalidValueForOption(option, vals)
                }
                
                flagMatched = true
                break
            }
            
            /* Flags that do not take any arguments can be concatenated */
            let flagLength = flag.characters.count
            if !flagMatched && !arg.hasPrefix(LongOptionPrefix) {
                for (i, c) in flag.characters.enumerate() {
                    for option in _options where option.flagMatch(String(c)) {
                        /* Values are allowed at the end of the concatenated flags, e.g.
                        * -xvf <file1> <file2>
                        */
                        let vals = (i == flagLength - 1) ? self._getFlagValues(idx) : [String]()
                        guard option.setValue(vals) else {
                            throw ParseError.InvalidValueForOption(option, vals)
                        }
                        
                        flagMatched = true
                        break
                    }
                }
            }
            
            /* Invalid flag */
            guard !strict || flagMatched else {
                throw ParseError.InvalidArgument(arg)
            }
        }
        
        /* Check to see if any required options were not matched */
        let missingOptions = _options.filter { $0.required && !$0.wasSet }
        guard missingOptions.count == 0 else {
            throw ParseError.MissingRequiredOptions(missingOptions)
        }
    }
    
    /* printUsage() is generic for OutputStreamType because the Swift compiler crashes
    * on inout protocol function parameters in Xcode 7 beta 1 (rdar://21372694).
    */
    
    /**
    * Prints a usage message.
    *
    * - parameter to: An OutputStreamType to write the error message to.
    */
    public func printUsage<TargetStream: OutputStreamType>(inout to: TargetStream) {
        let name = _arguments[0]
        
        var flagWidth = 0
        for opt in _options {
            flagWidth = max(flagWidth, "  \(opt.flagDescription):".characters.count)
        }
        
        print("Usage: \(name) [options]", toStream: &to)
        for opt in _options {
            let flags = "  \(opt.flagDescription):".paddedToWidth(flagWidth)
            print("\(flags)\n      \(opt.helpMessage)", toStream: &to)
        }
    }
    
    /**
     * Prints a usage message.
     *
     * - parameter error: An error thrown from `parse()`. A description of the error
     *   (e.g. "Missing required option --extract") will be printed before the usage message.
     * - parameter to: An OutputStreamType to write the error message to.
     */
    public func printUsage<TargetStream: OutputStreamType>(error: ErrorType, inout to: TargetStream) {
        print("\(error)\n", toStream: &to)
        printUsage(&to)
    }
    
    /**
     * Prints a usage message.
     *
     * - parameter error: An error thrown from `parse()`. A description of the error
     *   (e.g. "Missing required option --extract") will be printed before the usage message.
     */
    public func printUsage(error: ErrorType) {
        var out = StderrOutputStream.stream
        printUsage(error, to: &out)
    }
    
    /**
     * Prints a usage message.
     */
    public func printUsage() {
        var out = StderrOutputStream.stream
        printUsage(&out)
    }
}


/**
 * The base class for a command-line option.
 */
public class Option {
    public let shortFlag: String?
    public let longFlag: String?
    public let required: Bool
    public let helpMessage: String
    
    /** True if the option was set when parsing command-line arguments */
    public var wasSet: Bool {
        return false
    }
    
    public var flagDescription: String {
        switch (shortFlag, longFlag) {
        case (let sf, let lf) where sf != nil && lf != nil:
            return "\(ShortOptionPrefix)\(sf!), \(LongOptionPrefix)\(lf!)"
        case (_, let lf) where lf != nil:
            return "\(LongOptionPrefix)\(lf!)"
        default:
            return "\(ShortOptionPrefix)\(shortFlag ?? "")"
        }
    }
    
    private init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        if let sf = shortFlag {
            assert(sf.characters.count == 1, "Short flag must be a single character")
            assert(Int(sf) == nil && sf.toDouble() == nil, "Short flag cannot be a numeric value")
        }
        
        if let lf = longFlag {
            assert(Int(lf) == nil && lf.toDouble() == nil, "Long flag cannot be a numeric value")
        }
        
        self.shortFlag = shortFlag
        self.longFlag = longFlag
        self.helpMessage = helpMessage
        self.required = required
    }
    
    /* The optional casts in these initalizers force them to call the private initializer. Without
    * the casts, they recursively call themselves.
    */
    
    /** Initializes a new Option that has both long and short flags. */
    public convenience init(shortFlag: String, longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, longFlag, required, helpMessage)
    }
    
    /** Initializes a new Option that has only a short flag. */
    public convenience init(shortFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, nil, required, helpMessage)
    }
    
    /** Initializes a new Option that has only a long flag. */
    public convenience init(longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(nil, longFlag as String?, required, helpMessage)
    }
    
    func flagMatch(flag: String) -> Bool {
        return flag == shortFlag || flag == longFlag
    }
    
    func setValue(values: [String]) -> Bool {
        return false
    }
}

/**
 * A boolean option. The presence of either the short or long flag will set the value to true;
 * absence of the flag(s) is equivalent to false.
 */
public class BoolOption: Option {
    private var _value: Bool = false
    
    public var value: Bool {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value
    }
    
    override func setValue(values: [String]) -> Bool {
        _value = true
        return true
    }
}

/**  An option that accepts a positive or negative integer value. */
public class IntOption: Option {
    private var _value: Int?
    
    public var value: Int? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    override func setValue(values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let val = Int(values[0]) {
            _value = val
            return true
        }
        
        return false
    }
}

/**
 * An option that represents an integer counter. Each time the short or long flag is found
 * on the command-line, the counter will be incremented.
 */
public class CounterOption: Option {
    private var _value: Int = 0
    
    public var value: Int {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value > 0
    }
    
    override func setValue(values: [String]) -> Bool {
        _value += 1
        return true
    }
}

/**  An option that accepts a positive or negative floating-point value. */
public class DoubleOption: Option {
    private var _value: Double?
    
    public var value: Double? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    override func setValue(values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let val = values[0].toDouble() {
            _value = val
            return true
        }
        
        return false
    }
}

/**  An option that accepts a string value. */
public class StringOption: Option {
    private var _value: String? = nil
    
    public var value: String? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    override func setValue(values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values[0]
        return true
    }
}

/**  An option that accepts one or more string values. */
public class MultiStringOption: Option {
    private var _value: [String]?
    
    public var value: [String]? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    override func setValue(values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values
        return true
    }
}

/** An option that represents an enum value. */
public class EnumOption<T:RawRepresentable where T.RawValue == String>: Option {
    private var _value: T?
    public var value: T? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    /* Re-defining the intializers is necessary to make the Swift 2 compiler happy, as
    * of Xcode 7 beta 2.
    */
    
    private override init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        super.init(shortFlag, longFlag, required, helpMessage)
    }
    
    /** Initializes a new Option that has both long and short flags. */
    public convenience init(shortFlag: String, longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, longFlag, required, helpMessage)
    }
    
    /** Initializes a new Option that has only a short flag. */
    public convenience init(shortFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, nil, required, helpMessage)
    }
    
    /** Initializes a new Option that has only a long flag. */
    public convenience init(longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(nil, longFlag as String?, required, helpMessage)
    }
    
    override func setValue(values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        if let v = T(rawValue: values[0]) {
            _value = v
            return true
        }
        
        return false
    }
}


/* Required for localeconv(3) */
import Darwin

internal extension String {
    /* Retrieves locale-specified decimal separator from the environment
    * using localeconv(3).
    */
    private func _localDecimalPoint() -> Character {
        let locale = localeconv()
        if locale != nil {
            let decimalPoint = locale.memory.decimal_point
            if decimalPoint != nil {
                return Character(UnicodeScalar(UInt32(decimalPoint.memory)))
            }
        }
        
        return "."
    }
    
    /**
     * Attempts to parse the string value into a Double.
     *
     * - returns: A Double if the string can be parsed, nil otherwise.
     */
    func toDouble() -> Double? {
        var characteristic: String = "0"
        var mantissa: String = "0"
        var inMantissa: Bool = false
        var isNegative: Bool = false
        let decimalPoint = self._localDecimalPoint()
        
        for (i, c) in self.characters.enumerate() {
            if i == 0 && c == "-" {
                isNegative = true
                continue
            }
            
            if c == decimalPoint {
                inMantissa = true
                continue
            }
            
            if Int(String(c)) != nil {
                if !inMantissa {
                    characteristic.append(c)
                } else {
                    mantissa.append(c)
                }
            } else {
                /* Non-numeric character found, bail */
                return nil
            }
        }
        
        return (Double(Int(characteristic) ?? 0) +
            Double(Int(mantissa) ?? 0) / pow(Double(10), Double(mantissa.characters.count - 1))) *
            (isNegative ? -1 : 1)
    }
    
    /**
     * Splits a string into an array of string components.
     *
     * - parameter splitBy:  The character to split on.
     * - parameter maxSplit: The maximum number of splits to perform. If 0, all possible splits are made.
     *
     * - returns: An array of string components.
     */
    func splitByCharacter(splitBy: Character, maxSplits: Int = 0) -> [String] {
        var s = [String]()
        var numSplits = 0
        
        var curIdx = self.startIndex
        for(var i = self.startIndex; i != self.endIndex; i = i.successor()) {
            let c = self[i]
            if c == splitBy && (maxSplits == 0 || numSplits < maxSplits) {
                s.append(self[Range(start: curIdx, end: i)])
                curIdx = i.successor()
                numSplits++
            }
        }
        
        if curIdx != self.endIndex {
            s.append(self[Range(start: curIdx, end: self.endIndex)])
        }
        
        return s
    }
    
    /**
     * Pads a string to the specified width.
     *
     * - parameter width: The width to pad the string to.
     * - parameter padBy: The character to use for padding.
     *
     * - returns: A new string, padded to the given width.
     */
    func paddedToWidth(width: Int, padBy: Character = " ") -> String {
        var s = self
        var currentLength = self.characters.count
        
        while currentLength++ < width {
            s.append(padBy)
        }
        
        return s
    }
    
    /**
     * Wraps a string to the specified width.
     *
     * This just does simple greedy word-packing, it doesn't go full Knuth-Plass.
     * If a single word is longer than the line width, it will be placed (unsplit)
     * on a line by itself.
     *
     * - parameter width:   The maximum length of a line.
     * - parameter wrapBy:  The line break character to use.
     * - parameter splitBy: The character to use when splitting the string into words.
     *
     * - returns: A new string, wrapped at the given width.
     */
    func wrappedAtWidth(width: Int, wrapBy: Character = "\n", splitBy: Character = " ") -> String {
        var s = ""
        var currentLineWidth = 0
        
        for word in self.splitByCharacter(splitBy) {
            let wordLength = word.characters.count
            
            if currentLineWidth + wordLength + 1 > width {
                /* Word length is greater than line length, can't wrap */
                if wordLength >= width {
                    s += word
                }
                
                s.append(wrapBy)
                currentLineWidth = 0
            }
            
            currentLineWidth += wordLength + 1
            s += word
            s.append(splitBy)
        }
        
        return s
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Import

import Foundation


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions

private let BASE_CLASS_NAME : String = "Localizations"
private let OBJC_CLASS_PREFIX : String = "_"


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extensions
private extension String {
    
    func alphanumericString(exceptionCharactersFromString: String = "") -> String {
        
        // removes diacritic marks
        var copy = self.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
        
        // removes all non alphanumeric characters
        let characterSet = NSCharacterSet.alphanumericCharacterSet().invertedSet.mutableCopy() as! NSMutableCharacterSet
        
        // don't remove the characters that are given
        characterSet.removeCharactersInString(exceptionCharactersFromString)
        copy = copy.componentsSeparatedByCharactersInSet(characterSet).reduce("") { $0 + $1 }
        
        return copy
    }
}

private extension NSMutableDictionary {
    
    
    func setObject(object : AnyObject!, var forKeyPath : String, delimiter : String = ".") {
        
        // forKeyPath = forKeyPath.stringByReplacingOccurrencesOfString(" ", withString: "_")
        // forKeyPath = forKeyPath.alphanumericString("_")
        
        self.setObject(object, onObject : self, forKeyPath: forKeyPath, createIntermediates: true, replaceIntermediates: true, delimiter: delimiter)
    }
    
    
    func setObject(object : AnyObject, onObject : AnyObject, var forKeyPath : String, createIntermediates: Bool, replaceIntermediates: Bool, delimiter: String) {
        
        // Replace delimiter with dot delimiter - otherwise key value observing does not work properly
        let baseDelimiter = "."
        forKeyPath = forKeyPath.stringByReplacingOccurrencesOfString(delimiter, withString: baseDelimiter, options: .LiteralSearch, range: nil)
        
        // There is no keypath, just assign object
        if forKeyPath.rangeOfString(baseDelimiter) == nil {
            onObject.setObject(object, forKey: forKeyPath);
        }
        
        // Create path components separated by delimiter (. by default) and get key for root object
        let pathComponents : Array<String> = forKeyPath.componentsSeparatedByString(baseDelimiter);
        let rootKey : String = pathComponents[0];
        let replacementDictionary : NSMutableDictionary = NSMutableDictionary();
        
        // Store current state for further replacement
        var previousObject : AnyObject? = onObject;
        var previousReplacement : NSMutableDictionary = replacementDictionary;
        var reachedDictionaryLeaf : Bool = false;
        
        // Traverse through path from root to deepest level
        for path : String in pathComponents {
            
            let currentObject : AnyObject? = reachedDictionaryLeaf ? nil : previousObject?.objectForKey(path);
            
            // Check if object already exists. If not, create new level, if allowed, or end
            if currentObject == nil {
                
                reachedDictionaryLeaf = true;
                if createIntermediates {
                    let newNode : NSMutableDictionary = NSMutableDictionary();
                    previousReplacement.setObject(newNode, forKey: path);
                    previousReplacement = newNode;
                } else {
                    return;
                }
                
            // If it does and it is dictionary, create mutable copy and assign new node there
            } else if currentObject is NSDictionary {
                
                let newNode : NSMutableDictionary = NSMutableDictionary(dictionary: currentObject as! [NSObject : AnyObject]);
                previousReplacement.setObject(newNode, forKey: path);
                previousReplacement = newNode;
                
            // It exists but it is not NSDictionary, so we replace it, if allowed, or end
            } else {
                
                reachedDictionaryLeaf = true;
                if replaceIntermediates {
                    
                    let newNode : NSMutableDictionary = NSMutableDictionary();
                    previousReplacement.setObject(newNode, forKey: path);
                    previousReplacement = newNode;
                } else {
                    return;
                }
            }
            
            // Replace previous object with the new one
            previousObject = currentObject;
        }
        
        // Replace root object with newly created n-level dictionary
        replacementDictionary.setValue(object, forKeyPath: forKeyPath);
        onObject.setObject(replacementDictionary.objectForKey(rootKey), forKey: rootKey);
    }
}


private extension NSFileManager {
    
    func isDirectoryAtPath(path : String) -> Bool {
        
        let manager = NSFileManager.defaultManager()
        
        do {
            let attribs: NSDictionary? = try manager.attributesOfItemAtPath(path)
            if let attributes = attribs {
                let type = attributes["NSFileType"] as? String
                return type == NSFileTypeDirectory
            }
        } catch _ {
            return false
        }
    }
}


private extension String {
    
    var camelCasedString: String {
        
        let inputArray = self.componentsSeparatedByCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
        return inputArray.reduce("", combine:{$0 + $1.capitalizedString})
    }
    
    
    var nolineString: String {
        
        return self.stringByReplacingOccurrencesOfString("\n", withString: "")
                   .stringByReplacingOccurrencesOfString("\r", withString: "")
        
    }
    
    
    func isFirstLetterDigit() -> Bool {
        
        guard let c : Character = self.characters.first else {
            return false
        }
        
        let s = String(c).unicodeScalars
        let uni = s[s.startIndex]
        
        let digits = NSCharacterSet.decimalDigitCharacterSet()
        return digits.longCharacterIsMember(uni.value)
    }
    
    
    func isReservedKeyword(lang : Runtime.ExportLanguage) -> Bool {
        
        // Define keywords for each language
        var keywords : [String] = []
        if lang == .ObjC {
            keywords = ["auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long",
                        "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "swift", "typedef", "union", "unsigned", "void", "volatile", "while",
                        "BOOL", "Class", "bycopy", "byref", "id", "IMP", "in", "inout", "nil", "NO", "NULL", "oneway", "out", "Protocol", "SEL", "self", "super", "YES"]
        } else if lang == .Swift {
            keywords = ["class", "deinit", "enum", "extension", "func", "import", "init", "inout", "internal", "let", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "catch", "dynamicType", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try", "__COLUMN__", "__FILE__", "__FUNCTION__", "__LINE__"]
        }
        
        // Check if it contains that keyword
        return keywords.indexOf(self) != nil
    }
}


private enum SpecialCharacter {
    case String
    case Double
    case Int
    case Int64
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Localization Class implementation

class Localization {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var flatStructure = NSDictionary()
    var objectStructure = NSMutableDictionary()
    var autocapitalize : Bool = true
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    convenience init(inputFile : NSURL, delimiter : String, autocapitalize : Bool) {
        
        self.init()
        
        // Load localization file
        self.processInputFromFile(inputFile, delimiter: delimiter, autocapitalize: autocapitalize)
    }
    
    
    func processInputFromFile(file : NSURL, delimiter : String, autocapitalize : Bool) {
        
        guard let path = file.path, let dictionary = NSDictionary(contentsOfFile: path) else {
            // TODO: Better error handling
            print("Bad format of input file")
            exit(EX_IOERR)
        }
        
        self.flatStructure = dictionary
        self.autocapitalize = autocapitalize
        self.expandFlatStructure(dictionary, delimiter: delimiter)
    }

    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func writerWithSwiftImplementation() -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName("Imports")
        writer.writeSwiftImports()
        
        // Extensions
        writer.writeMarkWithName("Extensions")
        writer.writeRequiredExtensions()
        
        // Generate actual localization structures
        writer.writeMarkWithName("Localizations")
        writer.writeCodeStructure(self.swiftStructWithContent(self.codifySwift(self.objectStructure), structName: BASE_CLASS_NAME, contentLevel: 0))
        
        return writer
    }
    
    
    func writerWithObjCImplementationWithFilename(filename : String) -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName("Imports")
        writer.writeObjCImportsWithFileName(filename)
        
        // Generate actual localization structures
        writer.writeMarkWithName("Header")
        writer.writeCodeStructure(self.codifyObjC(self.objectStructure, baseClass: BASE_CLASS_NAME, header: false))
        
        return writer
    }
    
    
    func writerWithObjCHeader() -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName("Imports")
        writer.writeObjCHeaderImports()
        
        // Generate actual localization structures
        writer.writeMarkWithName("Header")
        writer.writeCodeStructure(self.codifyObjC(self.objectStructure, baseClass: BASE_CLASS_NAME, header: true))
        
        // Generate macros
        writer.writeMarkWithName("Macros")
        writer.writeObjCHeaderMacros()
        
        return writer
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func expandFlatStructure(flatStructure : NSDictionary, delimiter: String) {
    
        // Writes values to dictionary and also
        for (key, _) in flatStructure {
            guard let key = key as? String else { continue }
            objectStructure.setObject(key, forKeyPath: key, delimiter: delimiter)
        }
    }
    
    
    private func codifySwift(expandedStructure : NSDictionary, var contentLevel : Int = 0) -> String {
        
        // Increase content level
        contentLevel++
        
        // Prepare output structure
        var outputStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if let value = value as? String {
                let comment = (self.flatStructure.objectForKey(value) as! String).nolineString
                let methodParams = self.methodParamsForString(comment)
                let staticString: String
                
                if methodParams.count > 0 {
                    staticString = self.swiftLocalizationFuncFromLocalizationKey(value, methodName: key as! String, baseTranslation: comment, methodSpecification: methodParams, contentLevel: contentLevel)
                } else {
                    staticString = self.swiftLocalizationStaticVarFromLocalizationKey(value, variableName: key as! String, baseTranslation: comment, contentLevel: contentLevel)
                }
                outputStructure.append(staticString)
            }
        }
        
        // Then iterate through nested structures
        for (key, value) in expandedStructure {
            
            if let value = value as? NSDictionary {
                outputStructure.append(self.swiftStructWithContent(self.codifySwift(value, contentLevel: contentLevel), structName: key as! String, contentLevel: contentLevel))
            }
        }
        
        // At the end, return everything merged together
        return outputStructure.joinWithSeparator("\n")
    }
    
    
    private func codifyObjC(expandedStructure : NSDictionary, baseClass : String, header : Bool) -> String {
        
        // Prepare output structure
        var outputStructure : [String] = []
        var contentStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if let value = value as? String {
                
                let comment = (self.flatStructure.objectForKey(value) as! String).nolineString
                let methodParams = self.methodParamsForString(comment)
                let staticString : String
                
                if methodParams.count > 0 {
                    staticString = self.objcLocalizationFuncFromLocalizationKey(value, methodName: self.variableName(key as! String, lang: .ObjC), baseTranslation: comment, methodSpecification: methodParams, header: header)
                } else {
                    staticString = self.objcLocalizationStaticVarFromLocalizationKey(value, variableName: self.variableName(key as! String, lang: .ObjC), baseTranslation: comment, header: header)
                }
                
                contentStructure.append(staticString)
            }
        }
        
        // Then iterate through nested structures
        for (key, value) in expandedStructure {
            
            if let value = value as? NSDictionary {
                outputStructure.append(self.codifyObjC(value, baseClass : baseClass + self.variableName(key as! String, lang: .ObjC), header: header))
                contentStructure.insert(self.objcClassVarWithName(self.variableName(key as! String, lang: .ObjC), className: baseClass + self.variableName(key as! String, lang: .ObjC), header: header), atIndex: 0)
            }
        }
        
        if baseClass == BASE_CLASS_NAME {
            if header {
                contentStructure.append(TemplateFactory.templateForObjCBaseClassHeader(OBJC_CLASS_PREFIX + BASE_CLASS_NAME))
            } else {
                contentStructure.append(TemplateFactory.templateForObjCBaseClassImplementation(OBJC_CLASS_PREFIX + BASE_CLASS_NAME))
            }
        }
        
        // Generate class code for current class
        outputStructure.append(self.objcClassWithContent(contentStructure.joinWithSeparator("\n"), className: OBJC_CLASS_PREFIX + baseClass, header: header))
        
        // At the end, return everything merged together
        return outputStructure.joinWithSeparator("\n")
    }
    
    
    private func methodParamsForString(string : String) -> [SpecialCharacter] {
        
        // Split the string into pieces by %
        let matches = self.matchesForRegexInText("%([0-9]*.[0-9]*(d|i|u|f|ld)|@|d|i|u|f|ld)", text: string)
        var characters : [SpecialCharacter] = []
        
        // If there is just one component, no special characters are found
        if matches.count == 0 {
            return []
        } else {
            for match in matches {
                characters.append(self.propertyTypeForMatch(match))
            }
            return characters
        }
    }
    
    
    private func propertyTypeForMatch(string : String) -> SpecialCharacter {
        if string.containsString("ld") {
            return .Int64
        } else if string.containsString("d") || string.containsString("i") {
            return .Int
        } else if string.containsString("u") {
            return .UInt
        } else if string.containsString("f") {
            return .Double
        } else {
            return .String
        }
    }
    
    
    private func variableName(string : String, lang : Runtime.ExportLanguage) -> String {
        
        if self.autocapitalize {
            return (string.isFirstLetterDigit() || string.isReservedKeyword(lang) ? "_" + string.camelCasedString : string.camelCasedString)
        } else {
            return (string.isFirstLetterDigit() || string.isReservedKeyword(lang) ? "_" + string : string)
        }
    }
    
    
    private func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
    private func dataTypeFromSpecialCharacter(char : SpecialCharacter, language : Runtime.ExportLanguage) -> String {
        
        switch char {
            case .String: return language == .Swift ? "String" : "NSString *"
            case .Double: return language == .Swift ? "Double" : "double"
            case .Int: return language == .Swift ? "Int" : "int"
            case .Int64: return language == .Swift ? "Int64" : "long"
        }
    }
    
    
    private func swiftStructWithContent(content : String, structName : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStructWithName(self.variableName(structName, lang: .Swift), content: content, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStaticVarWithName(self.variableName(variableName, lang: .Swift), key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, methodSpecification : [SpecialCharacter], contentLevel : Int = 0) -> String {
        
        var counter = 0
        var methodHeaderParams = methodSpecification.reduce("") { (string, character) -> String in
            counter++
            return "\(string), _ value\(counter) : \(self.dataTypeFromSpecialCharacter(character, language: .Swift))"
        }
        
        var methodParams : [String] = []
        for (index, _) in methodSpecification.enumerate() {
            methodParams.append("value\(index + 1)")
        }
        let methodParamsString = methodParams.joinWithSeparator(", ")
        
        methodHeaderParams = methodHeaderParams.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ", _"))
        return TemplateFactory.templateForSwiftFuncWithName(self.variableName(methodName, lang: .Swift), key: key, baseTranslation : baseTranslation, methodHeader: methodHeaderParams, params: methodParamsString, contentLevel: contentLevel)
    }
    
    
    private func objcClassWithContent(content : String, className : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCClassHeaderWithName(className, content: content, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCClassImplementationWithName(className, content: content, contentLevel: contentLevel)
        }
    }
    
    
    private func objcClassVarWithName(name : String, className : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCClassVarHeaderWithName(name, className: className, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCClassVarImplementationWithName(name, className: className, contentLevel: contentLevel)
        }
    }
    
    
    private func objcLocalizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCStaticVarHeaderWithName(variableName, key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCStaticVarImplementationWithName(variableName, key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
        }
    }
    
    
    private func objcLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, methodSpecification : [SpecialCharacter], header : Bool, contentLevel : Int = 0) -> String {
        
        var counter = 0
        var methodHeader = methodSpecification.reduce("") { (string, character) -> String in
            counter++
            return "\(string), \(self.dataTypeFromSpecialCharacter(character, language: .ObjC))"
        }
        counter = 0
        var blockHeader = methodSpecification.reduce("") { (string, character) -> String in
            counter++
            return "\(string), \(self.dataTypeFromSpecialCharacter(character, language: .ObjC)) value\(counter) "
        }
        
        var blockParamComponent : [String] = []
        for (index, _) in methodSpecification.enumerate() {
            blockParamComponent.append("value\(index + 1)")
        }
        let blockParams = blockParamComponent.joinWithSeparator(", ")
        methodHeader = methodHeader.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ", "))
        blockHeader = blockHeader.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ", "))
        
        if header {
            return TemplateFactory.templateForObjCMethodHeaderWithName(methodName, key: key, baseTranslation: baseTranslation, methodHeader: methodHeader, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCMethodImplementationWithName(methodName, key: key, baseTranslation: baseTranslation, methodHeader: methodHeader, blockHeader: blockHeader, blockParams: blockParams, contentLevel: contentLevel)
        }
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Runtime Class implementation

class Runtime {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    enum ExportLanguage : String {
        case Swift = "swift"
        case ObjC = "objc"
    }
    
    
    enum ExportStream : String {
        case Standard = "stdout"
        case File = "file"
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var localizationFilePathToRead : NSURL!
    var localizationFilePathToWriteTo : NSURL!
    var localizationFileHeaderPathToWriteTo : NSURL?
    var localizationDelimiter = "."
    var localizationDebug = false
    var localizationCore : Localization!
    var localizationExportLanguage : ExportLanguage = .Swift
    var localizationExportStream : ExportStream = .File
    var localizationAutocapitalize = false
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func run() {
        
        // Initialize command line tool
        if self.checkCLI() {
        
            // Process files
            if self.checkIO() {
            
                // Generate input -> output based on user configuration
                self.processOutput()
            }
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func checkCLI() -> Bool {
        
        // Define CLI options
        let inputFilePath = StringOption(shortFlag: "i", longFlag: "input", required: true,
            helpMessage: "Required | String | Path to the localization file")
        let outputFilePath = StringOption(shortFlag: "o", longFlag: "output", required: false,
            helpMessage: "Optional | String | Path to output file (.swift or .m, depending on your configuration. If you are using ObjC, header will be created on that location. If ommited, output will be sent to stdout instead.")
        let outputLanguage = StringOption(shortFlag: "l", longFlag: "language", required: false,
            helpMessage: "Optional | String | [swift | objc] | Specifies language of generated output files | Defaults to [swift]")
        let delimiter = StringOption(shortFlag: "d", longFlag: "delimiter", required: false,
            helpMessage: "Optional | String | String delimiter to separate segments of each string | Defaults to [.]")
        let autocapitalize = BoolOption(shortFlag: "c", longFlag: "capitalize", required: false,
            helpMessage: "Optional | Bool | When enabled, name of all structures / methods / properties are automatically CamelCased | Defaults to false")

        
        let cli = CommandLine()
        cli.addOptions(inputFilePath, outputFilePath, outputLanguage, delimiter, autocapitalize)    
        
        // TODO: make output file path NOT optional when print output stream is selected
        do {
            
            // Parse user input
            try cli.parse()
            
            // It passed, now process input
            self.localizationFilePathToRead = NSURL(fileURLWithPath: inputFilePath.value!)
            
            if let value = delimiter.value { self.localizationDelimiter = value }
            self.localizationAutocapitalize = autocapitalize.wasSet ? true : false
            if let value = outputLanguage.value, type = ExportLanguage(rawValue: value) { self.localizationExportLanguage = type }
            if let value = outputFilePath.value {
                self.localizationFilePathToWriteTo = NSURL(fileURLWithPath: value)
                self.localizationExportStream = .File
            } else {
                self.localizationExportStream = .Standard
            }
            
            return true
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        
        return false
    }
    
    
    private func checkIO() -> Bool {
        
        // Check if we have input file
        if !NSFileManager.defaultManager().fileExistsAtPath(self.localizationFilePathToRead.path!) {
            
            // TODO: Better error handling
            exit(EX_IOERR)
        }
        
        // Handle output file checks only if we are writing to file
        if self.localizationExportStream == .File {
            
            // Remove output file first
            _ = try? NSFileManager.defaultManager().removeItemAtPath(self.localizationFilePathToWriteTo.path!)
            if !NSFileManager.defaultManager().createFileAtPath(self.localizationFilePathToWriteTo.path!, contents: NSData(), attributes: nil) {
                
                // TODO: Better error handling
                exit(EX_IOERR)
            }
            
            // ObjC - we also need header file for ObjC code
            if self.localizationExportLanguage == .ObjC {
                
                // Create header file name
                self.localizationFileHeaderPathToWriteTo = self.localizationFilePathToWriteTo.URLByDeletingPathExtension!.URLByAppendingPathExtension("h")
                
                // Remove file at path and replace it with new one
                _ = try? NSFileManager.defaultManager().removeItemAtPath(self.localizationFileHeaderPathToWriteTo!.path!)
                if !NSFileManager.defaultManager().createFileAtPath(self.localizationFileHeaderPathToWriteTo!.path!, contents: NSData(), attributes: nil) {
                    
                    // TODO: Better error handling
                    exit(EX_IOERR)
                }
            }
        }
        return true
    }
    
    
    private func processOutput() {
        
        // Create translation core which will process all required data
        self.localizationCore = Localization(inputFile: self.localizationFilePathToRead, delimiter: self.localizationDelimiter, autocapitalize: self.localizationAutocapitalize)
        
        // Write output for swift
        if self.localizationExportLanguage == .Swift {
            let implementation = self.localizationCore.writerWithSwiftImplementation()
            
            // Write swift file
            if self.localizationExportStream == .Standard {
                implementation.writeToSTD(true)
            } else if self.localizationExportStream == .File {
                implementation.writeToOutputFileAtPath(self.localizationFilePathToWriteTo)
            }
            
        // or write output for objc, based on user configuration
        } else if self.localizationExportLanguage == .ObjC {
            let implementation = self.localizationCore.writerWithObjCImplementationWithFilename(self.localizationFilePathToWriteTo.URLByDeletingPathExtension!.lastPathComponent!)
            let header = self.localizationCore.writerWithObjCHeader()
            
            // Write .h and .m file
            if self.localizationExportStream == .Standard {
                header.writeToSTD(true)
                implementation.writeToSTD(true)
            } else if self.localizationExportStream == .File {
                implementation.writeToOutputFileAtPath(self.localizationFilePathToWriteTo)
                header.writeToOutputFileAtPath(self.localizationFileHeaderPathToWriteTo!)
            }
        }
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - LocalizationPrinter Class implementation

class StreamWriter {
    
    var outputBuffer : String = ""
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func writeHeader() {
        
        // let formatter = NSDateFormatter()
        // formatter.dateFormat = "yyyy-MM-dd 'at' h:mm a"
        
        self.store("//\n")
        self.store("// Autogenerated by Laurine - by Jiri Trecak ( http://jiritrecak.com, @jiritrecak )\n")
        self.store("// Do not change this file manually!\n")
        self.store("//\n")
        // self.store("// \(formatter.stringFromDate(NSDate()))\n")
        // self.store("//\n")
    }
    
    
    func writeRequiredExtensions() {
        
        self.store("private extension String {\n")
        self.store("\n")
        self.store("    var localized: String {\n")
        self.store("\n")
        self.store("        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: \"\")\n")
        self.store("    }\n")
        self.store("\n")
        self.store("    func localizedWithComment(comment:String) -> String {\n")
        self.store("\n")
        self.store("        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: comment)\n")
        self.store("    }\n")
        self.store("}\n")
    }
    
    
    func writeMarkWithName(name : String, contentLevel : Int = 0) {
        
        self.store(TemplateFactory.contentIndentForLevel(contentLevel) + "\n")
        self.store(TemplateFactory.contentIndentForLevel(contentLevel) + "\n")
        self.store(TemplateFactory.contentIndentForLevel(contentLevel) + "// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n")
        self.store(TemplateFactory.contentIndentForLevel(contentLevel) + "// MARK: - \(name)\n")
        self.store(TemplateFactory.contentIndentForLevel(contentLevel) + "\n")
    }
    
    
    func writeSwiftImports() {
        
        self.store("import Foundation\n")
    }
    
    
    func writeObjCImportsWithFileName(name : String) {
        
        self.store("#import \"\(name).h\"\n")
    }
    
    
    func writeObjCHeaderImports() {
        
        self.store("@import Foundation;\n")
        self.store("@import UIKit;\n")
    }
    
    
    func writeObjCHeaderMacros() {
        
        self.store("// Make localization to be easily accessible\n")
        self.store("#define Localizations [\(OBJC_CLASS_PREFIX)\(BASE_CLASS_NAME) sharedInstance]\n")
    }
    
    
    func writeCodeStructure(structure : String) {
        
        self.store(structure)
        
    }
    
    
    func writeToOutputFileAtPath(path : NSURL, clearBuffer : Bool = true) {
        
        _ = try? self.outputBuffer.writeToFile(path.path!, atomically: true, encoding: NSUTF8StringEncoding)
        
        if clearBuffer {
            self.outputBuffer = ""
        }
    }
    
    
    func writeToSTD(clearBuffer : Bool = true) {
        
        print(self.outputBuffer)
        
        if clearBuffer {
            self.outputBuffer = ""
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func store(string : String) {
        
        self.outputBuffer += string
    }
}





// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - TemplateFactory Class implementation

class TemplateFactory {
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public - Swift Templates
    
    class func templateForSwiftStructWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "public struct \(name) {\n"
             + "\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "\(content)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "}"
    }
    
    
    class func templateForSwiftStaticVarWithName(name : String, key : String, baseTranslation : String, contentLevel : Int) -> String {
        
        return TemplateFactory.contentIndentForLevel(contentLevel) + "/// Base translation: \(baseTranslation)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "public static var \(name) : String = \"\(key)\".localized\n"
    }
    
    
    class func templateForSwiftFuncWithName(name : String, key : String, baseTranslation : String, methodHeader : String, params : String, contentLevel : Int) -> String {
        
        return TemplateFactory.contentIndentForLevel(contentLevel) + "/// Base translation: \(baseTranslation)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "public static func \(name)(\(methodHeader)) -> String {\n"
             + TemplateFactory.contentIndentForLevel(contentLevel + 1) + "return String(format: NSLocalizedString(\"\(key)\", tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: \"\"), \(params))\n"
             + TemplateFactory.contentIndentForLevel(contentLevel) + "}\n"
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public - ObjC templates
    
    class func templateForObjCClassImplementationWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "@implementation \(name)\n\n"
            + "\(content)\n"
            + "@end\n\n"
    }
    
    
    class func templateForObjCStaticVarImplementationWithName(name : String, key : String, baseTranslation : String, contentLevel : Int) -> String {
        
        return "- (NSString *)\(name) {\n"
              + TemplateFactory.contentIndentForLevel(1) + "return NSLocalizedString(@\"\(key)\", nil);\n"
            + "}\n"
    }
    
    
    class func templateForObjCClassVarImplementationWithName(name : String, className : String, contentLevel : Int) -> String {
        
        return "- (_\(className) *)\(name) {\n"
             + TemplateFactory.contentIndentForLevel(1) + "return [\(OBJC_CLASS_PREFIX)\(className) new];\n"
             + "}\n"
    }
    
    
    class func templateForObjCMethodImplementationWithName(name : String, key : String, baseTranslation : String, methodHeader : String, blockHeader : String, blockParams : String, contentLevel : Int) -> String {
        
        return "- (NSString *(^)(\(methodHeader)))\(name) {\n"
             + TemplateFactory.contentIndentForLevel(1) + "return ^(\(blockHeader)) {\n"
             + TemplateFactory.contentIndentForLevel(2) + "return [NSString stringWithFormat: NSLocalizedString(@\"\(key)\", nil), \(blockParams)];\n"
             + TemplateFactory.contentIndentForLevel(1) + "};\n"
             + "}\n"
    }
    
    
    class func templateForObjCClassHeaderWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "@interface \(name) : NSObject\n\n"
             + "\(content)\n"
             + "@end\n"
    }
    
    
    class func templateForObjCStaticVarHeaderWithName(name : String, key : String, baseTranslation : String, contentLevel : Int) -> String {
        
        return "/// Base translation: \(baseTranslation)\n"
             + "- (NSString *)\(name);\n"
    }
    
    
    class func templateForObjCClassVarHeaderWithName(name : String, className : String, contentLevel : Int) -> String {
        
        return "- (_\(className) *)\(name);\n"
    }
    
    
    class func templateForObjCMethodHeaderWithName(name : String, key : String, baseTranslation : String, methodHeader : String, contentLevel : Int) -> String {
        
        return "/// Base translation: \(baseTranslation)\n"
             + "- (NSString *(^)(\(methodHeader)))\(name);"
    }
    
    
    class func templateForObjCBaseClassHeader(name: String) -> String {
        return "+ (\(name) *)sharedInstance;\n"
    }
    
    
    class func templateForObjCBaseClassImplementation(name : String) -> String {
        
        return "+ (\(name) *)sharedInstance {\n"
        + "\n"
        + TemplateFactory.contentIndentForLevel(1) + "static dispatch_once_t once;\n"
        + TemplateFactory.contentIndentForLevel(1) + "static \(name) *instance;\n"
        + TemplateFactory.contentIndentForLevel(1) + "dispatch_once(&once, ^{\n"
        + TemplateFactory.contentIndentForLevel(2) + "instance = [[\(name) alloc] init];\n"
        + TemplateFactory.contentIndentForLevel(1) + "});\n"
        + TemplateFactory.contentIndentForLevel(1) + "return instance;\n"
        + "}"
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public - Helpers


    class func contentIndentForLevel(contentLevel : Int) -> String {
        
        var outputString = ""
        for _ in 0 ..< contentLevel {
            outputString += "    "
        }
        return outputString
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Actual processing

let runtime = Runtime()
runtime.run()




