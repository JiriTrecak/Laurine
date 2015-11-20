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
            return "\(ShortOptionPrefix)\(shortFlag!)"
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
        
        return (Double(Int(characteristic)!) +
            Double(Int(mantissa)!) / pow(Double(10), Double(mantissa.characters.count - 1))) *
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


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extensions

private extension NSMutableDictionary {
    
    
    func setObject(object : AnyObject!, forKeyPath : String, delimiter : String = ".") {
        
        self.setObject(object, onObject : self, forKeyPath: forKeyPath, createIntermediates: true, replaceIntermediates: true, delimiter: delimiter);
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
                let type = attributes["NSFileType"] as! String
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
    }
}


private enum SpecialCharacter : String {
    case String = "String"
    case Float = "Float"
    case Int = "Int"
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Localization Class implementation

class Localization {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var flatStructure = NSDictionary()
    var objectStructure = NSMutableDictionary()
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    convenience init(runtime : Runtime) {
        
        self.init()
        
        // Load localization file
        self.processInputFromRuntime(runtime)
    }
    
    
    func processInputFromRuntime(runtime : Runtime) {
        
        if let dictionary = NSDictionary(contentsOfFile: runtime.localizationFilePathToRead.path!) {
            self.flatStructure = dictionary
            self.expandFlatStructure(dictionary, delimiter: runtime.localizationDelimiter)
        } else {
            print("Bad format of input file")
            exit(EX_IOERR)
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func writeOutput() {
        
        // Generate header
        LocalizationPrinter.printHeader()
        
        // Imports
        LocalizationPrinter.printMarkWithName("Imports")
        LocalizationPrinter.printImports()
        
        // Extensions
        LocalizationPrinter.printMarkWithName("Extensions")
        LocalizationPrinter.printRequiredExtensions()
        
        // Generate actual localization structures
        LocalizationPrinter.printMarkWithName("Localizations")
        LocalizationPrinter.printCodeStructure(self.structWithContent(self.codifyExpandedStructure(self.objectStructure), name: "Localizations", contentLevel: 0))
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
 
    private func expandFlatStructure(flatStructure : NSDictionary, delimiter: String) {
    
        // Writes values to dictionary and also
        for (key, _) in flatStructure {
            objectStructure.setObject(key as! String, forKeyPath: key as! String, delimiter: delimiter)
        }
    }
    
    
    private func codifyExpandedStructure(expandedStructure : NSDictionary, var contentLevel : Int = 0) -> String {
        
        // Increase content level
        contentLevel++
        
        // Prepare output structure
        var outputStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if value is String {
                let comment = (self.flatStructure.objectForKey(value as! String) as! String).nolineString
                let methodParams = self.methodParamsForString(comment)
                let staticString : String
                
                if methodParams.count > 0 {
                    staticString = self.localizationFuncFromLocalizationKey(value as! String, variableName: key as! String, baseTranslation: comment, methodSpecification: methodParams, contentLevel: contentLevel)
                } else {
                    staticString = self.localizationStaticVarFromLocalizationKey(value as! String, variableName: key as! String, baseTranslation: comment, contentLevel: contentLevel)
                }
                outputStructure.append(staticString)
            }
        }
        
        // Then iterate through nested structures
        for (key, value) in expandedStructure {
            
            if value is NSDictionary {
                outputStructure.append(self.structWithContent(self.codifyExpandedStructure(value as! NSDictionary, contentLevel: contentLevel), name: key as! String, contentLevel: contentLevel))
            }
        }
        
        // At the end, return everything merged together
        return outputStructure.joinWithSeparator("\n")
    }
    
    
    private func methodParamsForString(string : String) -> [SpecialCharacter] {
        
        // Split the string into pieces by %
        let matches = self.matchesForRegexInText("%([0-9]*.[0-9]*(d|f|ld)|@|d)", text: string)
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
        
        if string.containsString("d") {
            return .Int
        } else if string.containsString("f") {
            return .Float
        } else {
            return .String
        }
    }
    
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
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
    
    
    private func structWithContent(content : String, name : String, contentLevel : Int = 0) -> String {
        
        return LocalizationPrinter.templateForStructWithName(name.camelCasedString, content: content, contentLevel: contentLevel)
    }
    
    
    private func localizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, contentLevel : Int = 0) -> String {
        
        return LocalizationPrinter.templateForStaticVarWithName(variableName.camelCasedString, key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
    }
    
    
    private func localizationFuncFromLocalizationKey(key : String, variableName : String, baseTranslation : String, methodSpecification : [SpecialCharacter], contentLevel : Int = 0) -> String {
        
        var counter = 0
        var methodHeaderParams = methodSpecification.reduce("") { (string, character) -> String in
            counter++
            return "\(string), _ value\(counter) : \(character.rawValue)"
        }
        
        var methodParams : [String] = []
        for (index, _) in methodSpecification.enumerate() {
            methodParams.append("value\(index + 1)")
        }
        let methodParamsString = methodParams.joinWithSeparator(", ")
        
        methodHeaderParams = methodHeaderParams.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ", _"))
        return LocalizationPrinter.templateForFuncWithName(variableName.camelCasedString, key: key, baseTranslation : baseTranslation, methodHeader: methodHeaderParams, params: methodParamsString, contentLevel: contentLevel)
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Runtime Class implementation

class Runtime {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var localizationFilePathToRead : NSURL!
    var localizationDelimiter : String! = "."
    var localizationDebug : Bool = false
    var localizationCore : Localization!
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func run() {
        
        // Initialize command line tool
        if self.processInput() {
        
            // Process files
            self.processFiles()
            
            // Generate output
            self.processOutput()
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func processInput() -> Bool {
        
        let cli = CommandLine()
        
        let inputFilePath = StringOption(shortFlag: "i", longFlag: "input", required: true,
            helpMessage: "Required | Path to the localization file")
        let delimiter = StringOption(shortFlag: "d", longFlag: "delimiter", required: false,
            helpMessage: "Optional | String delimiter to separate segments of each string | Defaults to [.]")
        
        cli.addOptions(inputFilePath, delimiter)
        
        do {
            
            // Parse user input
            try cli.parse()
            
            // It passed, now process input
            self.localizationFilePathToRead = NSURL(fileURLWithPath: NSFileManager.defaultManager().currentDirectoryPath).URLByAppendingPathComponent(inputFilePath.value!)
            if let value = delimiter.value { self.localizationDelimiter = value }
            
            return true
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        
        return false
    }
    
    
    private func processFiles() {
        
        // Check if we have input file
        if !NSFileManager.defaultManager().fileExistsAtPath(self.localizationFilePathToRead.path!) {
           exit(EX_IOERR)
        }
        
        // Create translation core
        self.localizationCore = Localization(runtime: self)
    }
    
    
    private func processOutput() {
        
        // Generate output from
        self.localizationCore.writeOutput()
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - LocalizationPrinter Class implementation

class LocalizationPrinter {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    class func printHeader() {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h:mm a"
        
        print("//")
        print("// Autogenerated by Laurine - by Jiri Trecak ( http://jiritrecak.com, @jiritrecak )")
        print("// Do not change this file manually!")
        print("//")
        print("//", formatter.stringFromDate(NSDate()))
        print("//")
    }
    
    
    class func printRequiredExtensions() {
        
        print("extension String {")
        print("")
        print("    var localized: String {")
        print("")
        print("        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: \"\")")
        print("    }")
        print("")
        print("    func localizedWithComment(comment:String) -> String {")
        print("")
        print("        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: comment)")
        print("    }")
        print("}")
    }
    
    
    class func printMarkWithName(name : String, contentLevel : Int = 0) {
        
        print(self.contentIndentForLevel(contentLevel) + "")
        print(self.contentIndentForLevel(contentLevel) + "")
        print(self.contentIndentForLevel(contentLevel) + "// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---")
        print(self.contentIndentForLevel(contentLevel) + "// MARK: - \(name)")
        print(self.contentIndentForLevel(contentLevel) + "")
    }
    
    
    class func printImports() {
        
        print("import Foundation")
    }
    
    
    class func printCodeStructure(structure : String) {
        
        print(structure)
    }
    
    
    class func templateForStructWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "\n"
               + self.contentIndentForLevel(contentLevel) + "struct \(name) {\n"
               + "\n"
               + self.contentIndentForLevel(contentLevel) + "\(content)\n"
               + self.contentIndentForLevel(contentLevel) + "}"
    }
    
    
    class func templateForStaticVarWithName(name : String, key : String, baseTranslation : String, contentLevel : Int) -> String {
        
        return self.contentIndentForLevel(contentLevel) + "/// Base translation: \(baseTranslation)\n"
            + self.contentIndentForLevel(contentLevel) + "static var \(name) : String = \"\(key)\".localized\n"
    }
    
    
    class func templateForFuncWithName(name : String, key : String, baseTranslation : String, methodHeader : String, params : String, contentLevel : Int) -> String {
        
        return self.contentIndentForLevel(contentLevel) + "/// Base translation: \(baseTranslation)\n"
            + self.contentIndentForLevel(contentLevel) + "static func \(name)(\(methodHeader)) -> String {\n"
            + self.contentIndentForLevel(contentLevel + 1) + "return String(format: NSLocalizedString(\"\(key)\", tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: \"\"), \(params))\n"
            + self.contentIndentForLevel(contentLevel) + "}\n"
    }
    
    
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







