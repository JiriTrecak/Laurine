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
 * CommandLine.swift
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

import Foundation
/* Required for setlocale(3) */
#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

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
private struct StderrOutputStream: TextOutputStream {
    static let stream = StderrOutputStream()
    func write(_ s: String) {
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
open class CommandLine {
    fileprivate var _arguments: [String]
    fileprivate var _options: [Option] = [Option]()
    fileprivate var _maxFlagDescriptionWidth: Int = 0
    fileprivate var _usedFlags: Set<String> {
        var usedFlags = Set<String>(minimumCapacity: _options.count * 2)
        
        for option in _options {
            for case let flag? in [option.shortFlag, option.longFlag] {
                usedFlags.insert(flag)
            }
        }
        
        return usedFlags
    }
    
    /**
     * After calling `parse()`, this property will contain any values that weren't captured
     * by an Option. For example:
     *
     * ```
     * let cli = CommandLine()
     * let fileType = StringOption(shortFlag: "t", longFlag: "type", required: true, helpMessage: "Type of file")
     *
     * do {
     *   try cli.parse()
     *   print("File type is \(type), files are \(cli.unparsedArguments)")
     * catch {
     *   cli.printUsage(error)
     *   exit(EX_USAGE)
     * }
     *
     * ---
     *
     * $ ./readfiles --type=pdf ~/file1.pdf ~/file2.pdf
     * File type is pdf, files are ["~/file1.pdf", "~/file2.pdf"]
     * ```
     */
    open fileprivate(set) var unparsedArguments: [String] = [String]()
    
    /**
     * If supplied, this function will be called when printing usage messages.
     *
     * You can use the `defaultFormat` function to get the normally-formatted
     * output, either before or after modifying the provided string. For example:
     *
     * ```
     * let cli = CommandLine()
     * cli.formatOutput = { str, type in
     *   switch(type) {
     *   case .Error:
     *     // Make errors shouty
     *     return defaultFormat(str.uppercaseString, type: type)
     *   case .OptionHelp:
     *     // Don't use the default indenting
     *     return ">> \(s)\n"
     *   default:
     *     return defaultFormat(str, type: type)
     *   }
     * }
     * ```
     *
     * - note: Newlines are not appended to the result of this function. If you don't use
     * `defaultFormat()`, be sure to add them before returning.
     */
    open var formatOutput: ((String, OutputType) -> String)?
    
    /**
     * The maximum width of all options' `flagDescription` properties; provided for use by
     * output formatters.
     *
     * - seealso: `defaultFormat`, `formatOutput`
     */
    open var maxFlagDescriptionWidth: Int {
        if _maxFlagDescriptionWidth == 0 {
            _maxFlagDescriptionWidth = _options.map { $0.flagDescription.count }.sorted().first ?? 0
        }
        
        return _maxFlagDescriptionWidth
    }
    
    /**
     * The type of output being supplied to an output formatter.
     *
     * - seealso: `formatOutput`
     */
    public enum OutputType {
        /** About text: `Usage: command-example [options]` and the like */
        case about
        
        /** An error message: `Missing required option --extract`  */
        case error
        
        /** An Option's `flagDescription`: `-h, --help:` */
        case optionFlag
        
        /** An Option's help message */
        case optionHelp
    }
    
    
    /** A ParseError is thrown if the `parse()` method fails. */
    public enum ParseError: Error, CustomStringConvertible {
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
                let vs = vals.joined(separator: ", ")
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
    public init(arguments: [String] = Swift.CommandLine.arguments) {
        self._arguments = arguments
        
        /* Initialize locale settings from the environment */
        setlocale(LC_ALL, "")
    }
    
    /* Returns all argument values from flagIndex to the next flag or the end of the argument array. */
    private func _getFlagValues(_ flagIndex: Int, _ attachedArg: String? = nil) -> [String] {
        var args: [String] = [String]()
        var skipFlagChecks = false
        
        if let a = attachedArg {
            args.append(a)
        }
        
        for i in flagIndex + 1 ..< _arguments.count {
            if !skipFlagChecks {
                if _arguments[i] == ArgumentStopper {
                    skipFlagChecks = true
                    continue
                }
                
                if _arguments[i].hasPrefix(ShortOptionPrefix) && Int(_arguments[i]) == nil &&
                    Double(_arguments[i]) == nil {
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
    public func addOption(_ option: Option) {
        let uf = _usedFlags
        for case let flag? in [option.shortFlag, option.longFlag] {
            assert(!uf.contains(flag), "Flag '\(flag)' already in use")
        }
        
        _options.append(option)
        _maxFlagDescriptionWidth = 0
    }
    
    /**
     * Adds one or more Options to the command line.
     *
     * - parameter options: An array containing the options to add.
     */
    public func addOptions(_ options: [Option]) {
        for o in options {
            addOption(o)
        }
    }
    
    /**
     * Adds one or more Options to the command line.
     *
     * - parameter options: The options to add.
     */
    public func addOptions(_ options: Option...) {
        for o in options {
            addOption(o)
        }
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: An array containing the options to set.
     */
    public func setOptions(_ options: [Option]) {
        _options = [Option]()
        addOptions(options)
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: The options to set.
     */
    public func setOptions(_ options: Option...) {
        _options = [Option]()
        addOptions(options)
    }
    
    /**
     * Parses command-line arguments into their matching Option values.
     *
     * - parameter strict: Fail if any unrecognized flags are present (default: false).
     *
     * - throws: A `ParseError` if argument parsing fails:
     *   - `.InvalidArgument` if an unrecognized flag is present and `strict` is true
     *   - `.InvalidValueForOption` if the value supplied to an option is not valid (for
     *     example, a string is supplied for an IntOption)
     *   - `.MissingRequiredOptions` if a required option isn't present
     */
    open func parse(strict: Bool = false) throws {
        var strays = _arguments
        
        /* Nuke executable name */
        strays[0] = ""
        
        let argumentsEnumerator = _arguments.enumerated()
        
        for (idx, arg) in argumentsEnumerator {
            if arg == ArgumentStopper {
                break
            }
            
            if !arg.hasPrefix(ShortOptionPrefix) {
                continue
            }
            
            let skipChars = arg.hasPrefix(LongOptionPrefix) ?
                LongOptionPrefix.count : ShortOptionPrefix.count
           
            let flagWithArg = arg[arg.index(arg.startIndex, offsetBy: skipChars)..<arg.endIndex]
            
            /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
            if flagWithArg.isEmpty {
                continue
            }
            
            /* Remove attached argument from flag */
            let splitFlag = flagWithArg.split(separator: ArgumentAttacher, maxSplits: 1)
            let flag = String(splitFlag[0])
            let attachedArg: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
            
            var flagMatched = false
            for option in _options where option.flagMatch(flag) {
                let vals = self._getFlagValues(idx, attachedArg)
                guard option.setValue(vals) else {
                    throw ParseError.InvalidValueForOption(option, vals)
                }
                
                var claimedIdx = idx + option.claimedValues
                if attachedArg != nil { claimedIdx -= 1 }
                for i in idx...claimedIdx {
                    strays[i] = ""
                }
                
                flagMatched = true
                break
            }
            
            /* Flags that do not take any arguments can be concatenated */
            let flagLength = flag.count
            if !flagMatched && !arg.hasPrefix(LongOptionPrefix) {
                
                let flagCharactersEnumerator = flag.enumerated()
                for (i, c) in flagCharactersEnumerator {
                    for option in _options where option.flagMatch(String(c)) {
                        /* Values are allowed at the end of the concatenated flags, e.g.
                         * -xvf <file1> <file2>
                         */
                        let vals = (i == flagLength - 1) ? self._getFlagValues(idx, attachedArg) : [String]()
                        guard option.setValue(vals) else {
                            throw ParseError.InvalidValueForOption(option, vals)
                        }
                        
                        var claimedIdx = idx + option.claimedValues
                        if attachedArg != nil { claimedIdx -= 1 }
                        for i in idx...claimedIdx {
                            strays[i] = ""
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
        
        unparsedArguments = strays.filter { $0 != "" }
    }
    
    /**
     * Provides the default formatting of `printUsage()` output.
     *
     * - parameter s:     The string to format.
     * - parameter type:  Type of output.
     *
     * - returns: The formatted string.
     * - seealso: `formatOutput`
     */
    open func defaultFormat(_ s: String, type: OutputType) -> String {
        switch type {
        case .about:
            return "\(s)\n"
        case .error:
            return "\(s)\n\n"
        case .optionFlag:
            return "  \(s.padding(toLength: maxFlagDescriptionWidth, withPad: " ", startingAt: 0)):\n"
        case .optionHelp:
            return "      \(s)\n"
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
    public func printUsage<TargetStream: TextOutputStream>(_ to: inout TargetStream) {
        /* Nil coalescing operator (??) doesn't work on closures :( */
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        
        let name = _arguments[0]
        print(format("Usage: \(name) [options]", .about), terminator: "", to: &to)
        
        for opt in _options {
            print(format(opt.flagDescription, .optionFlag), terminator: "", to: &to)
            print(format(opt.helpMessage, .optionHelp), terminator: "", to: &to)
        }
    }
    
    /**
     * Prints a usage message.
     *
     * - parameter error: An error thrown from `parse()`. A description of the error
     *   (e.g. "Missing required option --extract") will be printed before the usage message.
     * - parameter to: An OutputStreamType to write the error message to.
     */
    public func printUsage<TargetStream: TextOutputStream>(_ error: Error, to: inout TargetStream) {
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        print(format("\(error)", .error), terminator: "", to: &to)
        printUsage(&to)
    }
    
    /**
     * Prints a usage message.
     *
     * - parameter error: An error thrown from `parse()`. A description of the error
     *   (e.g. "Missing required option --extract") will be printed before the usage message.
     */
    public func printUsage(_ error: Error) {
        var out = StderrOutputStream.stream
        printUsage(error, to: &out)
    }
    
    /**
     * Prints a usage message.
     */
    open func printUsage() {
        var out = StderrOutputStream.stream
        printUsage(&out)
    }
}

/*
 * Option.swift
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

/**
 * The base class for a command-line option.
 */
open class Option {
    open let shortFlag: String?
    open let longFlag: String?
    open let required: Bool
    open let helpMessage: String
    
    /** True if the option was set when parsing command-line arguments */
    open var wasSet: Bool {
        return false
    }
    
    open var claimedValues: Int { return 0 }
    
    open var flagDescription: String {
        switch (shortFlag, longFlag) {
        case let (sf?, lf?):
            return "\(ShortOptionPrefix)\(sf), \(LongOptionPrefix)\(lf)"
        case (nil, let lf?):
            return "\(LongOptionPrefix)\(lf)"
        case (let sf?, nil):
            return "\(ShortOptionPrefix)\(sf)"
        default:
            return ""
        }
    }
    
    internal init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        if let sf = shortFlag {
            assert(sf.count == 1, "Short flag must be a single character")
            assert(Int(sf) == nil && Double(sf) == nil, "Short flag cannot be a numeric value")
        }
        
        if let lf = longFlag {
            assert(Int(lf) == nil && Double(lf) == nil, "Long flag cannot be a numeric value")
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
    
    func flagMatch(_ flag: String) -> Bool {
        return flag == shortFlag || flag == longFlag
    }
    
    func setValue(_ values: [String]) -> Bool {
        return false
    }
}

/**
 * A boolean option. The presence of either the short or long flag will set the value to true;
 * absence of the flag(s) is equivalent to false.
 */
open class BoolOption: Option {
    fileprivate var _value: Bool = false
    
    open var value: Bool {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value = true
        return true
    }
}

/**  An option that accepts a positive or negative integer value. */
open class IntOption: Option {
    fileprivate var _value: Int?
    
    open var value: Int? {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value != nil
    }
    
    override open var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
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
open class CounterOption: Option {
    fileprivate var _value: Int = 0
    
    open var value: Int {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value > 0
    }
    
    open func reset() {
        _value = 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value += 1
        return true
    }
}

/**  An option that accepts a positive or negative floating-point value. */
open class DoubleOption: Option {
    fileprivate var _value: Double?
    
    open var value: Double? {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value != nil
    }
    
    override open var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
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
open class StringOption: Option {
    fileprivate var _value: String? = nil
    
    open var value: String? {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value != nil
    }
    
    override open var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values[0]
        return true
    }
}

/**  An option that accepts one or more string values. */
open class MultiStringOption: Option {
    fileprivate var _value: [String]?
    
    open var value: [String]? {
        return _value
    }
    
    override open var wasSet: Bool {
        return _value != nil
    }
    
    override open var claimedValues: Int {
        if let v = _value {
            return v.count
        }
        
        return 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }
        
        _value = values
        return true
    }
}

    
/** An option that represents an enum value. */
public class EnumOption<T:RawRepresentable>: Option where T.RawValue == String {
    private var _value: T?
    public var value: T? {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value != nil
    }
    
    override public var claimedValues: Int {
        return _value != nil ? 1 : 0
    }
    
    /* Re-defining the intializers is necessary to make the Swift 2 compiler happy, as
     * of Xcode 7 beta 2.
     */
    
    internal override init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
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
    
    override func setValue(_ values: [String]) -> Bool {
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


/*
 * StringExtensions.swift
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

internal extension String {
    /* Retrieves locale-specified decimal separator from the environment
     * using localeconv(3).
     */
    fileprivate func _localDecimalPoint() -> Character {
        let locale = localeconv()
        if locale != nil {
            if let decimalPoint = locale?.pointee.decimal_point {
                return Character(UnicodeScalar(UInt32(decimalPoint.pointee))!)
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
        
        #if swift(>=3.0)
            let charactersEnumerator = self.enumerated()
        #else
            let charactersEnumerator = self.enumerated()
        #endif
        for (i, c) in charactersEnumerator {
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
        
        let doubleCharacteristic = Double(Int(characteristic)!)
        return (doubleCharacteristic +
            Double(Int(mantissa)!) / pow(Double(10), Double(mantissa.count - 1))) *
            (isNegative ? -1 : 1)
    }
    
    /**
     * Splits a string into an array of string components.
     *
     * - parameter by:        The character to split on.
     * - parameter maxSplits: The maximum number of splits to perform. If 0, all possible splits are made.
     *
     * - returns: An array of string components.
     */
    func split(by: Character, maxSplits: Int = 0) -> [String] {
        var s = [String]()
        var numSplits = 0
        
        var curIdx = self.startIndex
        for i in self.indices {
            let c = self[i]
            if c == by && (maxSplits == 0 || numSplits < maxSplits) {
                let str = String(self[curIdx..<i])
                s.append(str)
                curIdx = self.index(after: i)
                numSplits += 1
            }
        }
        
        if curIdx != self.endIndex {
            let str = String(self[curIdx..<self.endIndex])
            s.append(str)
        }
        
        return s
    }
    
    /**
     * Pads a string to the specified width.
     *
     * - parameter toWidth: The width to pad the string to.
     * - parameter by: The character to use for padding.
     *
     * - returns: A new string, padded to the given width.
     */
    func padded(toWidth width: Int, with padChar: Character = " ") -> String {
        var s = self
        var currentLength = self.count
        
        while currentLength < width {
            s.append(padChar)
            currentLength += 1
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
     * - parameter atWidth: The maximum length of a line.
     * - parameter wrapBy:  The line break character to use.
     * - parameter splitBy: The character to use when splitting the string into words.
     *
     * - returns: A new string, wrapped at the given width.
     */
    func wrapped(atWidth width: Int, wrapBy: Character = "\n", splitBy: Character = " ") -> String {
        var s = ""
        var currentLineWidth = 0
        
        for word in self.split(by: splitBy) {
            let wordLength = word.count
            
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

private var BASE_CLASS_NAME : String = "Localizations"
private let OBJC_CLASS_PREFIX : String = "_"
private var OBJC_CUSTOM_SUPERCLASS: String?

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extensions
private extension String {
    
    func alphanumericString(exceptionCharactersFromString: String = "") -> String {
        
        // removes diacritic marks
        var copy = self.folding(options: .diacriticInsensitive, locale: NSLocale.current)
        
        // removes all non alphanumeric characters
        var characterSet = CharacterSet.alphanumerics.inverted
        
        // don't remove the characters that are given
        characterSet.remove(charactersIn: exceptionCharactersFromString)
        copy = copy.components(separatedBy: characterSet).reduce("") { $0 + $1 }
        
        return copy
    }
	
    func replacedNonAlphaNumericCharacters(replacement: UnicodeScalar) -> String {
        return String(describing: UnicodeScalarView(self.unicodeScalars.map { CharacterSet.alphanumerics.contains(($0)) ? $0 : replacement }))
    }
}

private extension NSCharacterSet {
    
    // thanks to http://stackoverflow.com/a/27698155/354018
    func containsCharacter(c: Character) -> Bool {
        
        let s = String(c)
        let ix = s.startIndex
        let ix2 = s.endIndex
        let result = s.rangeOfCharacter(from: self as CharacterSet, options: [], range: ix..<ix2)
        return result != nil
    }
}


private extension NSMutableDictionary {
    
    
    func setObject(object : AnyObject!, forKeyPath : String, delimiter : String = ".") {
        
        self.setObject(object: object, onObject : self, forKeyPath: forKeyPath, createIntermediates: true, replaceIntermediates: true, delimiter: delimiter)
    }
    
    
    func setObject(object : AnyObject, onObject : AnyObject, forKeyPath keyPath : String, createIntermediates: Bool, replaceIntermediates: Bool, delimiter: String) {
        
        // Make keypath mutable
        var primaryKeypath = keyPath
        
        // Replace delimiter with dot delimiter - otherwise key value observing does not work properly
        let baseDelimiter = "."
        primaryKeypath = primaryKeypath.replacingOccurrences(of: delimiter, with: baseDelimiter, options: NSString.CompareOptions.literal, range: nil)
        
        // Create path components separated by delimiter (. by default) and get key for root object
		// filter empty path components, these can be caused by delimiter at beginning/end, or multiple consecutive delimiters in the middle
        let pathComponents : Array<String> = primaryKeypath.components(separatedBy: baseDelimiter).filter({ $0.count > 0 })
        primaryKeypath = pathComponents.joined(separator: baseDelimiter)
        let rootKey : String = pathComponents[0]
		
		if pathComponents.count == 1 {
			onObject.set(object, forKey: rootKey)
		}
		
        let replacementDictionary : NSMutableDictionary = NSMutableDictionary()
        
        // Store current state for further replacement
        var previousObject : AnyObject? = onObject;
        var previousReplacement : NSMutableDictionary = replacementDictionary
        var reachedDictionaryLeaf : Bool = false;
        
        // Traverse through path from root to deepest level
        for path : String in pathComponents {
            
            let currentObject : AnyObject? = reachedDictionaryLeaf ? nil : previousObject?.object(forKey: path) as AnyObject?
            
            // Check if object already exists. If not, create new level, if allowed, or end
            if currentObject == nil {
                
                reachedDictionaryLeaf = true;
                if createIntermediates {
                    let newNode : NSMutableDictionary = NSMutableDictionary()
                    previousReplacement.setObject(newNode, forKey: path as NSString)
                    previousReplacement = newNode;
                } else {
                    return;
                }
                
            // If it does and it is dictionary, create mutable copy and assign new node there
            } else if currentObject is NSDictionary {
                
                let newNode : NSMutableDictionary = NSMutableDictionary(dictionary: currentObject as! [NSObject : AnyObject])
                previousReplacement.setObject(newNode, forKey: path as NSString)
                previousReplacement = newNode
                
            // It exists but it is not NSDictionary, so we replace it, if allowed, or end
            } else {
                
                reachedDictionaryLeaf = true;
                if replaceIntermediates {
                    
                    let newNode : NSMutableDictionary = NSMutableDictionary()
                    previousReplacement.setObject(newNode, forKey: path as NSString)
                    previousReplacement = newNode;
                } else {
                    return;
                }
            }
            
            // Replace previous object with the new one
            previousObject = currentObject;
        }
        
        // Replace root object with newly created n-level dictionary
        replacementDictionary.setValue(object, forKeyPath: primaryKeypath);
        onObject.set(replacementDictionary.object(forKey: rootKey), forKey: rootKey);
    }
}


private extension FileManager {
    
    func isDirectoryAtPath(path : String) -> Bool {
        
        let manager = FileManager.default
        
        do {
            let attribs: [FileAttributeKey : Any]? = try manager.attributesOfItem(atPath: path)
            if let attributes = attribs {
                let type = attributes[FileAttributeKey.type] as? String
                return type == FileAttributeType.typeDirectory.rawValue
            }
        } catch _ {
            return false
        }
    }
}


private extension String {
    
    var camelCasedString: String {
        
        let inputArray = self.components(separatedBy: (CharacterSet.alphanumerics.inverted))
        return inputArray.reduce("", {$0 + $1.capitalized})
    }
    
    
    var nolineString: String {
        let set = CharacterSet.newlines
        let components = self.components(separatedBy: set)
        return components.joined(separator: " ")
    }
    
    
    func isFirstLetterDigit() -> Bool {
        
        guard let c : Character = self.first else {
            return false
        }
        
        let s = String(c).unicodeScalars
        let uni = s[s.startIndex]
        
        return (uni.value >= 48 && uni.value <= 57)
        // return String(describing: UnicodeScalarView(self.unicodeScalars.map { CharacterSet.alphanumerics.contains(($0)) ? $0 : replacement }))
        
    }
    
    
    func isReservedKeyword(lang : Runtime.ExportLanguage) -> Bool {
        
        // Define keywords for each language
        var keywords : [String] = []
        if lang == .ObjC {
            keywords = ["auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long",
                        "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "swift", "typedef", "union", "unsigned", "void", "volatile", "while",
                        "BOOL", "Class", "bycopy", "byref", "id", "IMP", "in", "inout", "nil", "NO", "NULL", "oneway", "out", "Protocol", "SEL", "self", "super", "YES"]
        } else if lang == .Swift {
            keywords = ["class", "deinit", "enum", "extension", "func", "import", "init", "inout", "internal", "let", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "catch", "dynamicType", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try", "type", "__COLUMN__", "__FILE__", "__FUNCTION__", "__LINE__"]
        }
        
        // Check if it contains that keyword
        return keywords.index(of: self) != nil
    }
}


private enum SpecialCharacter {
    case String
    case Double
    case Int
    case Int64
    case UInt
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Localization Class implementation

class Localization {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var flatStructure = NSDictionary()
    var objectStructure = NSMutableDictionary()
    var autocapitalize : Bool = true
    var table: String?
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    convenience init(inputFile : URL, delimiter : String, autocapitalize : Bool, table: String? = nil) {
        
        self.init()
        self.table = table
        // Load localization file
        self.processInputFromFile(file: inputFile, delimiter: delimiter, autocapitalize: autocapitalize)
    }
    
    
    func processInputFromFile(file : URL, delimiter : String, autocapitalize : Bool) {
        
        guard let dictionary = NSDictionary(contentsOfFile: file.path) else {
            // TODO: Better error handling
            print("Bad format of input file")
            exit(EX_IOERR)
        }
        
        self.flatStructure = dictionary
        self.autocapitalize = autocapitalize
        self.expandFlatStructure(flatStructure: dictionary, delimiter: delimiter)
    }

    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func writerWithSwiftImplementation() -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName(name: "Imports")
        writer.writeSwiftImports()
                
        // Generate actual localization structures
        writer.writeMarkWithName(name: "Localizations")
        writer.writeCodeStructure(structure: self.swiftStructWithContent(content: self.codifySwift(expandedStructure: self.objectStructure), structName: BASE_CLASS_NAME, contentLevel: 0))
        
        return writer
    }
    
    
    func writerWithObjCImplementationWithFilename(filename : String) -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName(name: "Imports")
        writer.writeObjCImportsWithFileName(name: filename)
        
        // Generate actual localization structures
        writer.writeMarkWithName(name: "Header")
        writer.writeCodeStructure(structure: self.codifyObjC(expandedStructure: self.objectStructure, baseClass: BASE_CLASS_NAME, header: false))
        
        return writer
    }
    
    
    func writerWithObjCHeader() -> StreamWriter {
        
        let writer = StreamWriter()
        
        // Generate header
        writer.writeHeader()
        
        // Imports
        writer.writeMarkWithName(name: "Imports")
        writer.writeObjCHeaderImports()
        
        // Generate actual localization structures
        writer.writeMarkWithName(name: "Header")
        writer.writeCodeStructure(structure: self.codifyObjC(expandedStructure: self.objectStructure, baseClass: BASE_CLASS_NAME, header: true))
        
        // Generate macros
        writer.writeMarkWithName(name: "Macros")
        writer.writeObjCHeaderMacros()
        
        return writer
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func expandFlatStructure(flatStructure : NSDictionary, delimiter: String) {
    
        // Writes values to dictionary and also
        for (key, _) in flatStructure {
            guard let key = key as? String else { continue }
            objectStructure.setObject(object: key as NSString, forKeyPath: key, delimiter: delimiter)
        }
    }
    
    
    private func codifySwift(expandedStructure : NSDictionary, contentLevel : Int = 0) -> String {
        
        // Increase content level
        let contentLevel = contentLevel + 1
        
        // Prepare output structure
        var outputStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if let value = value as? String {
                let comment = (self.flatStructure.object(forKey: value) as! String).nolineString
                let methodParams = self.methodParamsForString(string: comment)
                let staticString: String
                
                if methodParams.count > 0 {
                    staticString = self.swiftLocalizationFuncFromLocalizationKey(key: value, methodName: key as! String, baseTranslation: comment, methodSpecification: methodParams, contentLevel: contentLevel)
                } else {
                    staticString = self.swiftLocalizationStaticVarFromLocalizationKey(key: value, variableName: key as! String, baseTranslation: comment, contentLevel: contentLevel)
                }
                outputStructure.append(staticString)
            }
        }
        
        // Then iterate through nested structures
        for (key, value) in expandedStructure {
            
            if let value = value as? NSDictionary {
                outputStructure.append(self.swiftStructWithContent(content: self.codifySwift(expandedStructure: value, contentLevel: contentLevel), structName: key as! String, contentLevel: contentLevel))
            }
        }
        
        // At the end, return everything merged together
        return outputStructure.joined(separator: "\n")
    }
    
    
    private func codifyObjC(expandedStructure : NSDictionary, baseClass : String, header : Bool) -> String {
        
        // Prepare output structure
        var outputStructure : [String] = []
        var contentStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if let value = value as? String {
                
                let comment = (self.flatStructure.object(forKey: value) as! String).nolineString
                let methodParams = self.methodParamsForString(string: comment)
                let staticString : String
                
                if methodParams.count > 0 {
                    staticString = self.objcLocalizationFuncFromLocalizationKey(key: value, methodName: self.variableName(string: key as! String, lang: .ObjC), baseTranslation: comment, methodSpecification: methodParams, header: header)
                } else {
                    staticString = self.objcLocalizationStaticVarFromLocalizationKey(key: value, variableName: self.variableName(string: key as! String, lang: .ObjC), baseTranslation: comment, header: header)
                }
                
                contentStructure.append(staticString)
            }
        }
        
        // Then iterate through nested structures
        for (key, value) in expandedStructure {
            
            if let value = value as? NSDictionary {
                outputStructure.append(self.codifyObjC(expandedStructure: value, baseClass : baseClass + self.variableName(string: key as! String, lang: .ObjC), header: header))
                contentStructure.insert(self.objcClassVarWithName(name: self.variableName(string: key as! String, lang: .ObjC), className: baseClass + self.variableName(string: key as! String, lang: .ObjC), header: header), at: 0)
            }
        }
        
        if baseClass == BASE_CLASS_NAME {
            if header {
                contentStructure.append(TemplateFactory.templateForObjCBaseClassHeader(name: OBJC_CLASS_PREFIX + BASE_CLASS_NAME))
            } else {
                contentStructure.append(TemplateFactory.templateForObjCBaseClassImplementation(name: OBJC_CLASS_PREFIX + BASE_CLASS_NAME))
            }
        }
        
        // Generate class code for current class
        outputStructure.append(self.objcClassWithContent(content: contentStructure.joined(separator: "\n"), className: OBJC_CLASS_PREFIX + baseClass, header: header))
        
        // At the end, return everything merged together
        return outputStructure.joined(separator: "\n")
    }
    
    
    private func methodParamsForString(string : String) -> [SpecialCharacter] {
        
        // Split the string into pieces by %
        let matches = self.matchesForRegexInText(regex: "%([0-9]*.[0-9]*(d|i|u|f|ld)|(\\d\\$)?@|d|i|u|f|ld)", text: string)
        var characters : [SpecialCharacter] = []
        
        for match in matches {
            characters.append(self.propertyTypeForMatch(string: match))
        }
        return characters
    }
    
    
    private func propertyTypeForMatch(string : String) -> SpecialCharacter {
        if string.contains("ld") {
            return .Int64
        } else if string.contains("d") || string.contains("i") {
            return .Int
        } else if string.contains("u") {
            return .UInt
        } else if string.contains("f") {
            return .Double
        } else {
            return .String
        }
    }
    
    
    private func variableName(string : String, lang : Runtime.ExportLanguage) -> String {
	
		// . is not allowed, nested structure expanding must take place before calling this function
        let legalCharacterString = string.replacedNonAlphaNumericCharacters(replacement: "_")
		
        if self.autocapitalize {
            return (legalCharacterString.isFirstLetterDigit() || legalCharacterString.isReservedKeyword(lang: lang) ? "_" + legalCharacterString.camelCasedString : legalCharacterString.camelCasedString)
        } else {
            return (legalCharacterString.isFirstLetterDigit() || legalCharacterString.isReservedKeyword(lang: lang) ? "_" + string : legalCharacterString)
        }
    }
    
    
    private func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text, options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
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
            case .UInt: return language == .Swift ? "UInt" : "unsigned int"
        }
    }
    
    
    private func swiftStructWithContent(content : String, structName : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStructWithName(name: self.variableName(string: structName, lang: .Swift), content: content, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStaticVarWithName(name: self.variableName(string: variableName, lang: .Swift), key: key, table: table, baseTranslation : baseTranslation, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, methodSpecification : [SpecialCharacter], contentLevel : Int = 0) -> String {
        
        var counter = 0
        var methodHeaderParams = methodSpecification.reduce("") { (string, character) -> String in
            counter += 1
            return "\(string), _ value\(counter) : \(self.dataTypeFromSpecialCharacter(char: character, language: .Swift))"
        }
        
        var methodParams : [String] = []
        for (index, _) in methodSpecification.enumerated() {
            methodParams.append("value\(index + 1)")
        }
        let methodParamsString = methodParams.joined(separator: ", ")
        
        methodHeaderParams = methodHeaderParams.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        return TemplateFactory.templateForSwiftFuncWithName(name: self.variableName(string: methodName, lang: .Swift), key: key, table: table, baseTranslation : baseTranslation, methodHeader: methodHeaderParams, params: methodParamsString, contentLevel: contentLevel)
    }
    
    
    private func objcClassWithContent(content : String, className : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCClassHeaderWithName(name: className, content: content, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCClassImplementationWithName(name: className, content: content, contentLevel: contentLevel)
        }
    }
    
    
    private func objcClassVarWithName(name : String, className : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCClassVarHeaderWithName(name: name, className: className, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCClassVarImplementationWithName(name: name, className: className, contentLevel: contentLevel)
        }
    }
    
    
    private func objcLocalizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, header : Bool, contentLevel : Int = 0) -> String {
        
        if header {
            return TemplateFactory.templateForObjCStaticVarHeaderWithName(name: variableName, key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCStaticVarImplementationWithName(name: variableName, key: key, table: table, baseTranslation : baseTranslation, contentLevel: contentLevel)
        }
    }
    
    
    private func objcLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, methodSpecification : [SpecialCharacter], header : Bool, contentLevel : Int = 0) -> String {
        
        var counter = 0
        var methodHeader = methodSpecification.reduce("") { (string, character) -> String in
            counter += 1
            return "\(string), \(self.dataTypeFromSpecialCharacter(char: character, language: .ObjC))"
        }
        counter = 0
        var blockHeader = methodSpecification.reduce("") { (string, character) -> String in
            counter += 1
            return "\(string), \(self.dataTypeFromSpecialCharacter(char: character, language: .ObjC)) value\(counter) "
        }
        
        var blockParamComponent : [String] = []
        for (index, _) in methodSpecification.enumerated() {
            blockParamComponent.append("value\(index + 1)")
        }
        let blockParams = blockParamComponent.joined(separator: ", ")
        methodHeader = methodHeader.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        blockHeader = blockHeader.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        
        if header {
            return TemplateFactory.templateForObjCMethodHeaderWithName(name: methodName, key: key, baseTranslation: baseTranslation, methodHeader: methodHeader, contentLevel: contentLevel)
        } else {
            return TemplateFactory.templateForObjCMethodImplementationWithName(name: methodName, key: key, table: table, baseTranslation: baseTranslation, methodHeader: methodHeader, blockHeader: blockHeader, blockParams: blockParams, contentLevel: contentLevel)
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
    
    var localizationFilePathToRead : URL!
    var localizationFilePathToWriteTo : URL!
    var localizationFileHeaderPathToWriteTo : URL?
    var localizationDelimiter = "."
    var localizationDebug = false
    var localizationCore : Localization!
    var localizationExportLanguage : ExportLanguage = .Swift
    var localizationExportStream : ExportStream = .File
    var localizationAutocapitalize = false
    var localizationStringsTable: String?
    
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
        let baseClassName = StringOption(shortFlag: "b", longFlag: "baseClassName", required: false,
                                         helpMessage: "Optional | String | Name of the base class | Defaults to \"Localizations\"")
        let stringsTableName = StringOption(shortFlag: "t", longFlag: "stringsTableName", required: false,
                                            helpMessage: "Optional | String | Name of strings table | Defaults to nil")
        let customSuperclass = StringOption(shortFlag: "s", longFlag: "customSuperclass", required: false,
                                            helpMessage: "Optional | String | A custom superclass name | Defaults to NSObject (only applicable in ObjC)")
        
        let cli = CommandLine()
        cli.addOptions(inputFilePath, outputFilePath, outputLanguage, delimiter, autocapitalize, baseClassName, stringsTableName, customSuperclass)
        
        // TODO: make output file path NOT optional when print output stream is selected
        do {
            
            // Parse user input
            try cli.parse(strict: true)
            
            // It passed, now process input
            self.localizationFilePathToRead = URL(fileURLWithPath: inputFilePath.value!)
            
            if let value = delimiter.value { self.localizationDelimiter = value }
            self.localizationAutocapitalize = autocapitalize.wasSet ? true : false
            if let value = outputLanguage.value, let type = ExportLanguage(rawValue: value) { self.localizationExportLanguage = type }
            if let value = outputFilePath.value {
                self.localizationFilePathToWriteTo = URL(fileURLWithPath: value)
                self.localizationExportStream = .File
            } else {
                self.localizationExportStream = .Standard
            }
            
            if let bcn = baseClassName.value {
                BASE_CLASS_NAME = bcn
            }
            
            self.localizationStringsTable = stringsTableName.value
            
            OBJC_CUSTOM_SUPERCLASS = customSuperclass.value

            return true
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }
        
        return false
    }
    
    
    private func checkIO() -> Bool {
        
        // Check if we have input file
        if !FileManager.default.fileExists(atPath: self.localizationFilePathToRead.path) {
            
            // TODO: Better error handling
            exit(EX_IOERR)
        }
        
        // Handle output file checks only if we are writing to file
        if self.localizationExportStream == .File {
            
            // Remove output file first
            _ = try? FileManager.default.removeItem(atPath: self.localizationFilePathToWriteTo.path)
            if !FileManager.default.createFile(atPath: self.localizationFilePathToWriteTo.path, contents: Data(), attributes: nil) {
                
                // TODO: Better error handling
                exit(EX_IOERR)
            }
            
            // ObjC - we also need header file for ObjC code
            if self.localizationExportLanguage == .ObjC {
                
                // Create header file name
                self.localizationFileHeaderPathToWriteTo = self.localizationFilePathToWriteTo.deletingPathExtension().appendingPathExtension("h")
                
                // Remove file at path and replace it with new one
                _ = try? FileManager.default.removeItem(atPath: self.localizationFileHeaderPathToWriteTo!.path)
                if !FileManager.default.createFile(atPath: self.localizationFileHeaderPathToWriteTo!.path, contents: Data(), attributes: nil) {
                    
                    // TODO: Better error handling
                    exit(EX_IOERR)
                }
            }
        }
        return true
    }
    
    
    private func processOutput() {
        
        // Create translation core which will process all required data
        self.localizationCore = Localization(inputFile: self.localizationFilePathToRead, delimiter: self.localizationDelimiter, autocapitalize: self.localizationAutocapitalize, table: self.localizationStringsTable)
        
        // Write output for swift
        if self.localizationExportLanguage == .Swift {
            let implementation = self.localizationCore.writerWithSwiftImplementation()
            
            // Write swift file
            if self.localizationExportStream == .Standard {
                implementation.writeToSTD(clearBuffer: true)
            } else if self.localizationExportStream == .File {
                implementation.writeToOutputFileAtPath(path: self.localizationFilePathToWriteTo)
            }
            
        // or write output for objc, based on user configuration
        } else if self.localizationExportLanguage == .ObjC {
            let implementation = self.localizationCore.writerWithObjCImplementationWithFilename(filename: self.localizationFilePathToWriteTo.deletingPathExtension().lastPathComponent)
            let header = self.localizationCore.writerWithObjCHeader()
            
            // Write .h and .m file
            if self.localizationExportStream == .Standard {
                header.writeToSTD(clearBuffer: true)
                implementation.writeToSTD(clearBuffer: true)
            } else if self.localizationExportStream == .File {
                implementation.writeToOutputFileAtPath(path: self.localizationFilePathToWriteTo)
                header.writeToOutputFileAtPath(path: self.localizationFileHeaderPathToWriteTo!)
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
        
        self.store(string: "//\n")
        self.store(string: "// Autogenerated by Laurine - by Jiri Trecak ( http://jiritrecak.com, @jiritrecak )\n")
        self.store(string: "// Do not change this file manually!\n")
        self.store(string: "//\n")
        // self.store("// \(formatter.stringFromDate(NSDate()))\n")
        // self.store("//\n")
    }
    
    
    
    func writeMarkWithName(name : String, contentLevel : Int = 0) {
        
        self.store(string: TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "\n")
        self.store(string: TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "\n")
        self.store(string: TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---\n")
        self.store(string: TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "// MARK: - \(name)\n")
        self.store(string: TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "\n")
    }
    
    
    func writeSwiftImports() {
        
        self.store(string: "import Foundation\n")
    }
    
    
    func writeObjCImportsWithFileName(name : String) {
        
        self.store(string: "#import \"\(name).h\"\n")
    }
    
    
    func writeObjCHeaderImports() {
        
        self.store(string: "@import Foundation;\n")
        if let csc = OBJC_CUSTOM_SUPERCLASS {
            self.store(string: "#import \"\(csc).h\"\n")
        }
    }
    
    
    func writeObjCHeaderMacros() {
        
        self.store(string: "// Make localization to be easily accessible\n")
        self.store(string: "#define \(BASE_CLASS_NAME) [\(OBJC_CLASS_PREFIX)\(BASE_CLASS_NAME) sharedInstance]\n")
    }
    
    
    func writeCodeStructure(structure : String) {
        
        self.store(string: structure)
        
    }
    
    
    func writeToOutputFileAtPath(path : URL, clearBuffer : Bool = true) {
        
        _ = try? self.outputBuffer.write(toFile: path.path, atomically: true, encoding: String.Encoding.utf8)
        
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
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "public struct \(name) {\n"
             + "\n"
             + "\(content)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "}"
    }
    
    
    class func templateForSwiftStaticVarWithName(name : String, key : String, table: String?, baseTranslation : String, contentLevel : Int) -> String {
        let tableName: String
        if let table = table {
            tableName = "tableName: \"\(table)\", "
        } else {
            tableName = ""
        }
        return TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "/// Base translation: \(baseTranslation)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "public static var \(name) : String = NSLocalizedString(\"\(key)\", \(tableName)comment: \"\")\n"
    }
    
    
    class func templateForSwiftFuncWithName(name : String, key : String, table: String?, baseTranslation : String, methodHeader : String, params : String, contentLevel : Int) -> String {
        let tableName: String
        if let table = table {
            tableName = "tableName: \"\(table)\", "
        } else {
            tableName = ""
        }
        return TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "/// Base translation: \(baseTranslation)\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "public static func \(name)(\(methodHeader)) -> String {\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel + 1) + "return String(format: NSLocalizedString(\"\(key)\", \(tableName)comment: \"\"), \(params))\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: contentLevel) + "}\n"
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public - ObjC templates
    
    class func templateForObjCClassImplementationWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "@implementation \(name)\n\n"
            + "\(content)\n"
            + "@end\n\n"
    }
    
    
    class func templateForObjCStaticVarImplementationWithName(name : String, key : String, table: String?, baseTranslation : String, contentLevel : Int) -> String {
        let tableName = table != nil ? "@\"\(table!)\"" : "nil"
        return "- (NSString *)\(name) {\n"
            + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "return NSLocalizedStringFromTable(@\"\(key)\", \(tableName), nil);\n"
            + "}\n"
    }
    
    
    class func templateForObjCClassVarImplementationWithName(name : String, className : String, contentLevel : Int) -> String {
        
        return "- (_\(className) *)\(name) {\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "return [\(OBJC_CLASS_PREFIX)\(className) new];\n"
             + "}\n"
    }
    
    
    class func templateForObjCMethodImplementationWithName(name : String, key : String, table: String?, baseTranslation : String, methodHeader : String, blockHeader : String, blockParams : String, contentLevel : Int) -> String {
        let tableName = table != nil ? "@\"\(table!)\"" : "nil"
        return "- (NSString *(^)(\(methodHeader)))\(name) {\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "return ^(\(blockHeader)) {\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: 2) + "return [NSString stringWithFormat: NSLocalizedStringFromTable(@\"\(key)\", \(tableName), nil), \(blockParams)];\n"
             + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "};\n"
             + "}\n"
    }
    
    
    class func templateForObjCClassHeaderWithName(name : String, content : String, contentLevel : Int) -> String {
        
        return "@interface \(name) : \(OBJC_CUSTOM_SUPERCLASS ?? "NSObject")\n\n"
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
        + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "static dispatch_once_t once;\n"
        + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "static \(name) *instance;\n"
        + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "dispatch_once(&once, ^{\n"
        + TemplateFactory.contentIndentForLevel(contentLevel: 2) + "instance = [[\(name) alloc] init];\n"
        + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "});\n"
        + TemplateFactory.contentIndentForLevel(contentLevel: 1) + "return instance;\n"
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




