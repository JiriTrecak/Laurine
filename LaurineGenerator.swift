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
    private var _maxFlagDescriptionWidth: Int = 0
    private var _usedFlags: Set<String> {
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
     *   print("File type is \(type), files are \(cli.strayValues)")
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
    public private(set) var strayValues: [String] = [String]()
    
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
    public var formatOutput: ((String, OutputType) -> String)?
    
    /**
     * The maximum width of all options' `flagDescription` properties; provided for use by
     * output formatters.
     *
     * - seealso: `defaultFormat`, `formatOutput`
     */
    public var maxFlagDescriptionWidth: Int {
        if _maxFlagDescriptionWidth == 0 {
            _maxFlagDescriptionWidth = _options.map { $0.flagDescription.characters.count }.sort().first ?? 0
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
        case About
        
        /** An error message: `Missing required option --extract`  */
        case Error
        
        /** An Option's `flagDescription`: `-h, --help:` */
        case OptionFlag
        
        /** An Option's help message */
        case OptionHelp
    }
    
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
    private func _getFlagValues(flagIndex: Int, _ attachedArg: String? = nil) -> [String] {
        var args: [String] = [String]()
        var skipFlagChecks = false
        
        if let a = attachedArg {
            args.append(a)
        }
        
        for i in (flagIndex + 1).stride(to: _arguments.count, by: 1) {
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
    public func addOptions(options: [Option]) {
        for o in options {
            addOption(o)
        }
    }
    
    /**
     * Adds one or more Options to the command line.
     *
     * - parameter options: The options to add.
     */
    public func addOptions(options: Option...) {
        for o in options {
            addOption(o)
        }
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: An array containing the options to set.
     */
    public func setOptions(options: [Option]) {
        _options = [Option]()
        addOptions(options)
    }
    
    /**
     * Sets the command line Options. Any existing options will be overwritten.
     *
     * - parameter options: The options to set.
     */
    public func setOptions(options: Option...) {
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
    public func parse(strict: Bool = false) throws {
        /* Kind of an ugly cast here */
        var strays = _arguments.map { $0 as String? }
        
        /* Nuke executable name */
        strays[0] = nil
        
        for (idx, arg) in _arguments.enumerate() {
            if arg == ArgumentStopper {
                break
            }
            
            if !arg.hasPrefix(ShortOptionPrefix) {
                continue
            }
            
            let skipChars = arg.hasPrefix(LongOptionPrefix) ?
                LongOptionPrefix.characters.count : ShortOptionPrefix.characters.count
            let flagWithArg = arg[arg.startIndex.advancedBy(skipChars)..<arg.endIndex]
            
            /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
            if flagWithArg.isEmpty {
                continue
            }
            
            /* Remove attached argument from flag */
            let splitFlag = flagWithArg.splitByCharacter(ArgumentAttacher, maxSplits: 1)
            let flag = splitFlag[0]
            let attachedArg: String? = splitFlag.count == 2 ? splitFlag[1] : nil
            
            var flagMatched = false
            for option in _options where option.flagMatch(flag) {
                let vals = self._getFlagValues(idx, attachedArg)
                guard option.setValue(vals) else {
                    throw ParseError.InvalidValueForOption(option, vals)
                }
                
                var claimedIdx = idx + option.claimedValues
                if attachedArg != nil { claimedIdx -= 1 }
                for i in idx.stride(through: claimedIdx, by: 1) {
                    strays[i] = nil
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
                        let vals = (i == flagLength - 1) ? self._getFlagValues(idx, attachedArg) : [String]()
                        guard option.setValue(vals) else {
                            throw ParseError.InvalidValueForOption(option, vals)
                        }
                        
                        var claimedIdx = idx + option.claimedValues
                        if attachedArg != nil { claimedIdx -= 1 }
                        for i in idx.stride(through: claimedIdx, by: 1) {
                            strays[i] = nil
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
        
        strayValues = strays.flatMap { $0 }
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
    public func defaultFormat(s: String, type: OutputType) -> String {
        switch type {
        case .About:
            return "\(s)\n"
        case .Error:
            return "\(s)\n\n"
        case .OptionFlag:
            return "  \(s.paddedToWidth(maxFlagDescriptionWidth)):\n"
        case .OptionHelp:
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
    public func printUsage<TargetStream: OutputStreamType>(inout to: TargetStream) {
        /* Nil coalescing operator (??) doesn't work on closures :( */
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        
        let name = _arguments[0]
        print(format("Usage: \(name) [options]", .About), terminator: "", toStream: &to)
        
        for opt in _options {
            print(format(opt.flagDescription, .OptionFlag), terminator: "", toStream: &to)
            print(format(opt.helpMessage, .OptionHelp), terminator: "", toStream: &to)
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
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        print(format("\(error)", .Error), terminator: "", toStream: &to)
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
    
    public var claimedValues: Int { return 0 }
    
    public var flagDescription: String {
        switch (shortFlag, longFlag) {
        case let (.Some(sf), .Some(lf)):
            return "\(ShortOptionPrefix)\(sf), \(LongOptionPrefix)\(lf)"
        case (.None, let .Some(lf)):
            return "\(LongOptionPrefix)\(lf)"
        case (let .Some(sf), .None):
            return "\(ShortOptionPrefix)\(sf)"
        default:
            return ""
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
    
    override public var claimedValues: Int {
        return _value != nil ? 1 : 0
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
    
    public func reset() {
        _value = 0
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
    
    override public var claimedValues: Int {
        return _value != nil ? 1 : 0
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
    
    override public var claimedValues: Int {
        return _value != nil ? 1 : 0
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
    
    override public var claimedValues: Int {
        if let v = _value {
            return v.count
        }
        
        return 0
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
    
    override public var claimedValues: Int {
        return _value != nil ? 1 : 0
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
        for i in self.characters.indices {
            let c = self[i]
            if c == splitBy && (maxSplits == 0 || numSplits < maxSplits) {
                s.append(self[curIdx..<i])
                curIdx = i.successor()
                numSplits += 1
            }
        }
        
        if curIdx != self.endIndex {
            s.append(self[curIdx..<self.endIndex])
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
        
        while currentLength < width {
            s.append(padBy)
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

#if os(Linux)
    /**
     *  Returns `true` iff `self` begins with `prefix`.
     *
     *  A basic implementation of `hasPrefix` for Linux.
     *  Should be removed once a proper `hasPrefix` patch makes it to the Swift 2.2 development branch.
     */
    extension String {
        func hasPrefix(prefix: String) -> Bool {
            if prefix.isEmpty {
                return false
            }
            
            let c = self.characters
            let p = prefix.characters
            
            if p.count > c.count {
                return false
            }
            
            for (c, p) in zip(c.prefix(p.count), p) {
                guard c == p else {
                    return false
                }
            }
            
            return true
        }
        
        /**
         *  Returns `true` iff `self` ends with `suffix`.
         *
         *  A basic implementation of `hasSuffix` for Linux.
         *  Should be removed once a proper `hasSuffix` patch makes it to the Swift 2.2 development branch.
         */
        func hasSuffix(suffix: String) -> Bool {
            if suffix.isEmpty {
                return false
            }
            
            let c = self.characters
            let s = suffix.characters
            
            if s.count > c.count {
                return false
            }
            
            for (c, s) in zip(c.suffix(s.count), s) {
                guard c == s else {
                    return false
                }
            }
            
            return true
        }
    }
#endif


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
	
	func replacedNonAlphaNumericCharacters(replacement: Character) -> String {
		
		return String( self.characters.map { NSCharacterSet.alphanumericCharacterSet().containsCharacter($0) ? $0 : replacement } )
	}
	
}

private extension NSCharacterSet {
	
	// thanks to http://stackoverflow.com/a/27698155/354018
	func containsCharacter(c: Character) -> Bool {
		
		let s = String(c)
		let ix = s.startIndex
		let ix2 = s.endIndex
		let result = s.rangeOfCharacterFromSet(self, options: [], range: ix..<ix2)
		return result != nil
	}
	
}

private extension NSMutableDictionary {
    
    
    func setObject(object : AnyObject!, forKeyPath : String, delimiter : String = ".") {
        
        self.setObject(object, onObject : self, forKeyPath: forKeyPath, createIntermediates: true, replaceIntermediates: true, delimiter: delimiter)
    }
    
    
    func setObject(object : AnyObject, onObject : AnyObject, forKeyPath keyPath : String, createIntermediates: Bool, replaceIntermediates: Bool, delimiter: String) {
        
        // Make keypath mutable
        var primaryKeypath = keyPath
        
        // Replace delimiter with dot delimiter - otherwise key value observing does not work properly
        let baseDelimiter = "."
        primaryKeypath = primaryKeypath.stringByReplacingOccurrencesOfString(delimiter, withString: baseDelimiter, options: .LiteralSearch, range: nil)
        
        // Create path components separated by delimiter (. by default) and get key for root object
		// filter empty path components, these can be caused by delimiter at beginning/end, or multiple consecutive delimiters in the middle
		let pathComponents : Array<String> = primaryKeypath.componentsSeparatedByString(baseDelimiter).filter({ $0.characters.count > 0 })
		primaryKeypath = pathComponents.joinWithSeparator(baseDelimiter)
        let rootKey : String = pathComponents[0]
		
		if pathComponents.count == 1 {
			onObject.setObject(object, forKey: rootKey)
		}
		
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
        replacementDictionary.setValue(object, forKeyPath: primaryKeypath);
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
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            .filter { !$0.isEmpty }
            .joinWithSeparator(" ")
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


struct StringFormatSpecifier {
    
    struct Flags: OptionSetType {
        private static let charMap: [Character: Flags] = [
            "'": .GroupThousands,
            "-": .JustifyLeft,
            "+": .ExplicitSign,
            " ": .PrefixSpace,
            "#": .AlternativeForm,
            "0": .LeadingZeros
        ]
        
        let rawValue: Int
        
        init (rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init? (fromCharacter character: Character) {
            if let value = Flags.charMap[character] {
                self = value
            } else {
                return nil
            }
        }
        
        init? (fromString string: String) {
            
            var flags = Flags.None
            
            for character in string.characters {
                if let value = Flags.charMap[character] {
                    flags.unionInPlace(value)
                } else {
                    return nil
                }
            }
            
            self = flags
        }
        
        static let None = Flags(rawValue: 0)
        static let GroupThousands = Flags(rawValue: 1 << 0)
        static let JustifyLeft = Flags(rawValue: 1 << 1)
        static let ExplicitSign = Flags(rawValue: 1 << 2)
        static let PrefixSpace = Flags(rawValue: 1 << 3)
        static let AlternativeForm = Flags(rawValue: 1 << 4)
        static let LeadingZeros = Flags(rawValue: 1 << 5)
    }
    
    enum OptionalInt {
        case Unspecified
        case Value(Int)
        case Parameterized(argumentPosition: Int?)
    }
    
    enum SpecifierType {
        
        private static let charMap: [Character: SpecifierType] = [
            "@": .Object,
            "d": .Integer(.Signed, .Decimal),
            "D": .Integer(.Signed, .Decimal),
            "u": .Integer(.Unsigned, .Decimal),
            "U": .Integer(.Unsigned, .Decimal),
            "x": .Integer(.Unsigned, .Hexadecimal(.Lower)),
            "X": .Integer(.Unsigned, .Hexadecimal(.Upper)),
            "o": .Integer(.Unsigned, .Octal),
            "O": .Integer(.Unsigned, .Octal),
            "f": .Float(.Decimal),
            "F": .Float(.Decimal),
            "e": .Float(.Scientific(.Lower)),
            "E": .Float(.Scientific(.Upper)),
            "g": .Float(.DecimalOrScientific(.Lower)),
            "G": .Float(.DecimalOrScientific(.Upper)),
            "a": .Float(.HexadecimalScientific(.Lower)),
            "A": .Float(.HexadecimalScientific(.Upper)),
            "c": .UChar,
            "C": .UniChar,
            "s": .NilString,
            "S": .NilUniString,
            "p": .Pointer
        ]
        
        enum Signedness {
            case Signed, Unsigned
        }
        
        enum Case {
            case Lower, Upper
        }
        
        enum Notation {
            case
            Octal,
            Decimal,
            Hexadecimal(Case),
            Scientific(Case),
            DecimalOrScientific(Case),
            HexadecimalScientific(Case)
        }
        
        init? (fromCharacter character: Character) {
            if let value = SpecifierType.charMap[character] {
                self = value
            } else {
                return nil
            }
        }
        
        case
        Object,
        Integer(Signedness, Notation),
        Float(Notation),
        UChar,
        UniChar,
        NilString,
        NilUniString,
        Pointer
    }
    
    enum LengthModifier {
        
        private static let strMap: [String: LengthModifier] = [
            "hh": .Char,
            "h": .Short,
            "l": .Long,
            "ll": .LongLong,
            "q": .LongLong,
            "L": .LongDouble,
            "z": .Size,
            "t": .PtrDiff,
            "j": .IntMax
        ]
        
        init? (fromString string: String) {
            if let value = LengthModifier.strMap[string] {
                self = value
            } else {
                return nil
            }
        }
        
        case None, Char, Short, Long, LongLong, LongDouble, Size, PtrDiff, IntMax
    }
    
    private enum MatchCaptureGroup: Int {
        case
        Position = 1,
        Flags,
        WidthParameterizedFlag, WidthParameterizedPosition, WidthValue,
        PrecisionParameterizedFlag, PrecisionParameterizedPosition, PrecisionValue,
        UnmodifiableType,
        IntegerLengthModifier, IntegerModifiableType,
        FloatLengthModifier, FloatModifiableType
    }
    
    private static let regex = try! NSRegularExpression(pattern: "(?<!%)%(?:%%)*(?:(\\d)\\$)?([-+' #0]*)(?:(\\*)(?:(\\d)\\$)?|(\\d+))?(?:\\.(?:(\\*)(?:(\\d)\\$)?|(\\d*)))?(?:([@cCsSpDOU])|(h|hh|l|ll|q|z|t|j)?([douxX])|(L)?([aAeEfFgG]))", options: [])
    
    typealias Bundle = [StringFormatSpecifier]
    
    static func parse(text: String) -> Bundle {
        let nsString = text as NSString
        let matches = regex.matchesInString(text, options: [], range: NSMakeRange(0, nsString.length))
        
        var bundle: Bundle = []
        
        for match in matches {
            
            var position: Int?
            var flags: Flags
            var width: OptionalInt
            var precision: OptionalInt
            var lengthModifier: LengthModifier
            var type: SpecifierType
            
            // position
            let positionRange = match.rangeAtIndex(MatchCaptureGroup.Position.rawValue)
            if positionRange.location != NSNotFound {
                position = Int(nsString.substringWithRange(positionRange))
            }
            
            // flags
            let flagsRange = match.rangeAtIndex(MatchCaptureGroup.Flags.rawValue)
            flags = StringFormatSpecifier.Flags(fromString: nsString.substringWithRange(flagsRange))!
            
            // width
            let widthValueRange = match.rangeAtIndex(MatchCaptureGroup.WidthValue.rawValue)
            if widthValueRange.location != NSNotFound {
                width = .Value(Int(nsString.substringWithRange(widthValueRange))!)
            } else {
                let widthParameterizedFlagRange = match.rangeAtIndex(MatchCaptureGroup.WidthParameterizedFlag.rawValue)
                if widthParameterizedFlagRange.location != NSNotFound {
                    
                    var widthPosition: Int?
                    
                    let widthParameterizedPositionRange = match.rangeAtIndex(MatchCaptureGroup.WidthParameterizedPosition.rawValue)
                    if widthParameterizedPositionRange.location != NSNotFound {
                        widthPosition = Int(nsString.substringWithRange(widthParameterizedPositionRange))!
                    }
                    
                    width = .Parameterized(argumentPosition: widthPosition)
                } else {
                    width = .Unspecified
                }
            }
            
            // precision
            let precisionValueRange = match.rangeAtIndex(MatchCaptureGroup.PrecisionValue.rawValue)
            if precisionValueRange.location != NSNotFound {
                precision = .Value(Int(nsString.substringWithRange(precisionValueRange)) ?? 0)
            } else {
                let precisionParameterizedFlagRange = match.rangeAtIndex(MatchCaptureGroup.PrecisionParameterizedFlag.rawValue)
                if precisionParameterizedFlagRange.location != NSNotFound {
                    
                    var precisionPosition: Int?
                    
                    let precisionParameterizedPositionRange = match.rangeAtIndex(MatchCaptureGroup.PrecisionParameterizedPosition.rawValue)
                    if precisionParameterizedPositionRange.location != NSNotFound {
                        precisionPosition = Int(nsString.substringWithRange(precisionParameterizedPositionRange))!
                    }
                    
                    precision = .Parameterized(argumentPosition: precisionPosition)
                } else {
                    precision = .Unspecified
                }
            }
            
            // type + length modifier
            let unmodifiableTypeRange = match.rangeAtIndex(MatchCaptureGroup.UnmodifiableType.rawValue)
            if unmodifiableTypeRange.location != NSNotFound {
                let strType = nsString.substringWithRange(unmodifiableTypeRange)
                type = SpecifierType(fromCharacter: strType.characters.first!)!
                lengthModifier = .None
            } else {
                
                var modifiableTypeRange: NSRange
                var lengthModifierRange: NSRange
                
                let integerModifiableRange = match.rangeAtIndex(MatchCaptureGroup.IntegerModifiableType.rawValue)
                if integerModifiableRange.location != NSNotFound {
                    
                    modifiableTypeRange = integerModifiableRange
                    lengthModifierRange = match.rangeAtIndex(MatchCaptureGroup.IntegerLengthModifier.rawValue)
                    
                } else {
                    
                    let floatModifiableTypeRange = match.rangeAtIndex(MatchCaptureGroup.FloatModifiableType.rawValue)
                    if floatModifiableTypeRange.location == NSNotFound {
                        fatalError("Unknown specifier type")
                    }
                    
                    modifiableTypeRange = floatModifiableTypeRange
                    lengthModifierRange = match.rangeAtIndex(MatchCaptureGroup.FloatLengthModifier.rawValue)
                    
                }
                
                let strType = nsString.substringWithRange(modifiableTypeRange)
                type = SpecifierType(fromCharacter: strType.characters.first!)!
                
                if lengthModifierRange.location != NSNotFound {
                    lengthModifier = LengthModifier(fromString: nsString.substringWithRange(lengthModifierRange))!
                } else {
                    lengthModifier = .None
                }
            }
            
            let specifierMatch = StringFormatSpecifier(argumentPosition: position, flags: flags, width: width, precision: precision, lengthModifier: lengthModifier, type: type)
            bundle.append(specifierMatch)
        }
        
        return bundle
    }
    
    let argumentPosition: Int?
    let flags: Flags
    let width: OptionalInt
    let precision: OptionalInt
    let lengthModifier: LengthModifier
    let type: SpecifierType
}


extension StringFormatSpecifier.OptionalInt: Equatable {}


func ==(lhs: StringFormatSpecifier.OptionalInt, rhs: StringFormatSpecifier.OptionalInt) -> Bool {
    switch (lhs, rhs) {
        
    case (.Unspecified, .Unspecified):
        return true
        
    case (.Value(let value1), .Value(let value2)):
        return value1 == value2
        
    case (.Parameterized(let position1), .Parameterized(let position2)):
        return position1 == position2
        
    default:
        return false
        
    }
}


class StringFormatArgument {
    
    enum ArgumentType {
        
        init? (fromSpecifier specifier: StringFormatSpecifier) {
            
            switch (specifier.type, specifier.lengthModifier) {
                
            case (.Object, _):
                // HACK: allow different argument types using the precision flag
                self = specifier.precision == .Unspecified ? .String : .NSObject
                
            case (.Integer(let s, _), .Char):
                self = s == .Signed ? .Int8 : .UInt8
                
            case (.Integer(let s, _), .Short):
                self = s == .Signed ? .Int16 : .UInt16
                
            case (.Integer(let s, _), .None):
                self = s == .Signed ? .Int : .UInt
                
            case (.Integer(let s, _), .Long):
                self = s == .Signed ? .Int32 : .UInt32
                
            case (.Integer(let s, _), .LongLong):
                self = s == .Signed ? .Int64 : .UInt64
                
            case (.Integer(let s, _), .IntMax):
                self = s == .Signed ? .IntMax : .UIntMax
                
            case (.Float(_), .LongDouble):
                self = .Double
                
            case (.Float(_), .None):
                self = .Float
                
            case (.UChar, _):
                self = .UInt8
                
            case (.UniChar, _):
                self = .UnicodeScalar
                
            case (.NilString, _), (.NilUniString, _):
                self = .NSData
                
            case (.Pointer, _):
                self = .Pointer
                
            default:
                return nil
            }
        }
        
        case
            String,
            Int8, UInt8,
            Int16, UInt16,
            Int32, UInt32,
            Int, UInt,
            Int64, UInt64,
            IntMax, UIntMax,
            UnicodeScalar,
            Float, Double,
            NSData, NSObject,
            Pointer
    }
    
    enum EffectType {
        case Value, Width, Precision
    }
    
    struct Effect {
        let type: EffectType
        let specifierPosition: Int
    }
    
    enum Error: ErrorType {
        case MixedArguments
        case ConflictingTypes(position: Int, typeA: StringFormatArgument.ArgumentType, typeB: StringFormatArgument.ArgumentType)
        case SparsePositions
    }
    
    let type: ArgumentType
    var groups: Set<Int>
    var effects: [Effect] = []
    var hasValueEffects: Bool = false
    var hasWidthEffects: Bool = false
    var hasPrecisionEffects: Bool = false
    
    init (type: ArgumentType, group: Int? = nil, effect: Effect) {
        self.type = type
        
        if let groupValue = group {
            self.groups = [groupValue]
        } else {
            self.groups = []
        }
        
        addEffect(effect)
    }
    
    func addToGroup(group: Int) {
        groups.insert(group)
    }
    
    func addEffect(effect: Effect) {
        
        switch effect.type {
        case .Value:
            hasValueEffects = true
        case .Width:
            hasWidthEffects = true
        case .Precision:
            hasPrecisionEffects = true
        }
        
        effects.append(effect)
    }
    
    func getName() -> String {
        
        var prefix: String
        
        if hasValueEffects {
            prefix = "value"
        } else if hasWidthEffects {
            if hasPrecisionEffects {
                prefix = "options"
            } else {
                prefix = "width"
            }
        } else if hasPrecisionEffects {
            prefix = "precision"
        } else {
            prefix = "unknown"
        }
        
        return prefix + groups.sort().map({ String($0) }).joinWithSeparator("_")
    }
    
    static func inferFormatArguments(bundle: StringFormatSpecifier.Bundle) throws -> [StringFormatArgument] {
        
        if bundle.isEmpty {
            return []
        }
        
        var arguments: [StringFormatArgument] = []
        
        let first = bundle.first!
        if first.argumentPosition == nil {
            
            /**
             * Unnumbered arguments
             */
            
            // specifier position == argument group
            var position = 1
            
            for specifier in bundle {
 
                guard specifier.argumentPosition == nil else {
                    throw Error.MixedArguments
                }
                
                if case .Parameterized(argumentPosition: let widthArgumentPosition) = specifier.width {
                    guard widthArgumentPosition == nil else {
                        throw Error.MixedArguments
                    }
                    
                    arguments.append(StringFormatArgument(type: .Int, group: position,
                        effect: Effect(type: .Width, specifierPosition: position)))
                }
                
                if case .Parameterized(argumentPosition: let precisionArgumentPosition) = specifier.precision {
                    guard precisionArgumentPosition == nil else {
                        throw Error.MixedArguments
                    }
                    
                    arguments.append(StringFormatArgument(type: .Int, group: position,
                        effect: Effect(type: .Precision, specifierPosition: position)))
                }
                
                arguments.append(StringFormatArgument(type: ArgumentType(fromSpecifier: specifier)!, group: position,
                    effect:  Effect(type: .Value, specifierPosition: position)))
                
                position += 1
            }
            
        } else {
            
            /**
             * Numbered arguments
             */
            
            var argumentMap: [Int: StringFormatArgument] = [:]
            
            // map to store argument positions of specifier VALUES (not weight or precision)
            var specifierToValueArgumentMap : [Int: Int] = [:]
            
            let append = { (argumentPosition: Int, type: ArgumentType, effect: Effect) -> Void in
                
                if let existingArgument = argumentMap[argumentPosition] {
                    
                    guard existingArgument.type == type else {
                        throw Error.ConflictingTypes(position: argumentPosition,
                                                     typeA: existingArgument.type,
                                                     typeB: type)
                    }
                    
                    existingArgument.addEffect(effect)
                    
                } else {
                    argumentMap[argumentPosition] = StringFormatArgument(type: type, effect: effect)
                }
            }
            
            var specifierPosition = 1
            
            for specifier in bundle {
                
                guard let valueArgumentPosition = specifier.argumentPosition else {
                    throw Error.MixedArguments
                }
                
                if case .Parameterized(argumentPosition: let widthArgumentPosition) = specifier.width {
                    guard let positionUnwrapped = widthArgumentPosition else {
                        throw Error.MixedArguments
                    }
                    
                    try append(positionUnwrapped, .Int, Effect(type: .Width, specifierPosition: specifierPosition))
                }
                
                if case .Parameterized(argumentPosition: let precisionArgumentPosition) = specifier.precision {
                    guard let positionUnwrapped = precisionArgumentPosition else {
                        throw Error.MixedArguments
                    }
                    
                    try append(positionUnwrapped, .Int, Effect(type: .Precision, specifierPosition: specifierPosition))
                }
                
                try append(valueArgumentPosition, ArgumentType(fromSpecifier: specifier)!, Effect(type: .Value, specifierPosition: specifierPosition))
                
                specifierToValueArgumentMap[specifierPosition] = valueArgumentPosition
                
                specifierPosition += 1
            }
            
            // check that the map keys are incremental and contiguous, and assign groups
            var argumentPosition = 1
            var groupNumber = 1
            var ungroupedArguments: [StringFormatArgument] = []
            
            for (actualPosition, argument) in argumentMap.sort({ $0.0 < $1.0 }) {
                if actualPosition != argumentPosition {
                    throw Error.SparsePositions
                }
                
                argumentPosition += 1
                
                if argument.hasValueEffects {
                    // each "value" argument creates a new group
                    argument.addToGroup(groupNumber)
                    groupNumber += 1
                } else {
                    ungroupedArguments.append(argument)
                }
                
                arguments.append(argument)
            }
            
            // group the remaining arguments according to their effects on values that correspond to other arguments
            for argument in ungroupedArguments {
                for effect in argument.effects {
                    let valueArgumentPosition = specifierToValueArgumentMap[effect.specifierPosition]!
                    let valueArgument = argumentMap[valueArgumentPosition]!
                    
                    let group = valueArgument.groups.first!
                    
                    argument.addToGroup(group)
                }
            }
        }
        
        return arguments
    }
}

extension StringFormatArgument.Error : CustomStringConvertible {
    var description: String {
        switch self {
        case .MixedArguments:
            return "Mixing numbered and unnumbered argument specifications in a format string is unsupported"
        case .ConflictingTypes(let position, let typeA, let typeB):
            return "Coflicting argument types in format string. Position \(position), types \(typeA) and \(typeB)"
        case .SparsePositions:
            return "Numbered format strings must be contiguous"
        }
    }
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
    
    
    private func codifySwift(expandedStructure : NSDictionary, contentLevel : Int = 0) -> String {
        
        // Increase content level
        let contentLevel = contentLevel + 1
        
        // Prepare output structure
        var outputStructure : [String] = []
        
        // First iterate through properties
        for (key, value) in expandedStructure {
            
            if let value = value as? String {
                let comment = (self.flatStructure.objectForKey(value) as! String).nolineString
                let arguments: [StringFormatArgument]
                    
                do {
                    arguments = try self.inferArgumentsFromFormatString(comment)
                } catch let error as StringFormatArgument.Error {
                    fatalError("Error parsing format string \"\(key)\": \(error.description)")
                } catch {
                    fatalError("Unknown error")
                }
                
                let staticString: String

                if arguments.count > 0 {
                    staticString = self.swiftLocalizationFuncFromLocalizationKey(value, methodName: key as! String, baseTranslation: comment, arguments: arguments, contentLevel: contentLevel)
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
                let arguments: [StringFormatArgument]
                
                do {
                    arguments = try self.inferArgumentsFromFormatString(comment)
                } catch let error as StringFormatArgument.Error {
                    fatalError("Error parsing format string \"\(key)\": \(error.description)")
                } catch {
                    fatalError("Unknown error")
                }
                
                let staticString : String

                if arguments.count > 0 {
                    staticString = self.objcLocalizationFuncFromLocalizationKey(value, methodName: self.variableName(key as! String, lang: .ObjC), baseTranslation: comment, arguments: arguments, header: header)
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


    private func inferArgumentsFromFormatString(string : String) throws -> [StringFormatArgument] {

        let specifierBundle = StringFormatSpecifier.parse(string)
        return try StringFormatArgument.inferFormatArguments(specifierBundle)
    }
    
    
    private func variableName(string : String, lang : Runtime.ExportLanguage) -> String {
	
		// . is not allowed, nested structure expanding must take place before calling this function
		let legalCharacterString = string.replacedNonAlphaNumericCharacters("_")
		
        if self.autocapitalize {
            return (legalCharacterString.isFirstLetterDigit() || legalCharacterString.isReservedKeyword(lang) ? "_" + legalCharacterString.camelCasedString : legalCharacterString.camelCasedString)
        } else {
            return (legalCharacterString.isFirstLetterDigit() || legalCharacterString.isReservedKeyword(lang) ? "_" + string : legalCharacterString)
        }
    }


    private func dataTypeFromArgumentType(argumentType : StringFormatArgument.ArgumentType, language : Runtime.ExportLanguage) -> String {

        let swift = language == .Swift
        
        switch argumentType {
        case .String: return swift ? "String" : "NSString *"
        case .Int8: return swift ? "Int8" : "char"
        case .UInt8: return swift ? "UInt8" : "unsigned char"
        case .Int16: return swift ? "Int16" : "short"
        case .UInt16: return swift ? "UInt16" : "unsigned short"
        case .Int32: return swift ? "Int32" : "int"
        case .UInt32: return swift ? "UInt32" : "unsigned int"
        case .Int: return swift ? "Int" : "int"
        case .UInt: return swift ? "UInt" : "unsigned int"
        case .Int64: return swift ? "Int64" : "long long"
        case .UInt64: return swift ? "UInt64" : "unsigned long long"
        case .IntMax: return swift ? "IntMax" : "intmax_t"
        case .UIntMax: return swift ? "UIntMax" : "uintmax_t"
        case .UnicodeScalar: return swift ? "UnicodeScalar" : "unichar"
        case .Float: return swift ? "Float" : "float"
        case .Double: return swift ? "Double" : "double"
        case .NSData: return "NSData" 
        case .NSObject: return "NSObject" 
        case .Pointer: return swift ? "UnsafePointer<Void>" : "void *"
        }
    }
    
    
    private func swiftStructWithContent(content : String, structName : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStructWithName(self.variableName(structName, lang: .Swift), content: content, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationStaticVarFromLocalizationKey(key : String, variableName : String, baseTranslation : String, contentLevel : Int = 0) -> String {
        
        return TemplateFactory.templateForSwiftStaticVarWithName(self.variableName(variableName, lang: .Swift), key: key, baseTranslation : baseTranslation, contentLevel: contentLevel)
    }
    
    
    private func swiftLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, arguments : [StringFormatArgument], contentLevel : Int = 0) -> String {

        let argumentsSignature = arguments.map({ (name: $0.getName(), type: $0.type) })
        
        let methodHeaderParams = argumentsSignature
            .map({ "\($0.name) : \(self.dataTypeFromArgumentType($0.type, language: .Swift))" })
            .joinWithSeparator(", _ ")
 
        let methodParamsString = argumentsSignature.map({ $0.name }).joinWithSeparator(", ")

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
    
    
    private func objcLocalizationFuncFromLocalizationKey(key : String, methodName : String, baseTranslation : String, arguments : [StringFormatArgument], header : Bool, contentLevel : Int = 0) -> String {

        let argumentsSignature = arguments.map({ (name: $0.getName(), type: $0.type) })
        
        let methodHeader = argumentsSignature
            .map({ self.dataTypeFromArgumentType($0.type, language: .ObjC) })
            .joinWithSeparator(", ")
        
        let blockHeader = argumentsSignature
            .map({ "\(self.dataTypeFromArgumentType($0.type, language: .ObjC)) \($0.name) " })
            .joinWithSeparator(", ")
        
        let blockParams = argumentsSignature
            .map({ $0.name })
            .joinWithSeparator(", ")

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
        
        // we use NSString(format:) instead of String(format:) because of an issue:
        // https://bugs.swift.org/browse/SR-1378
        return TemplateFactory.contentIndentForLevel(contentLevel) + "/// Base translation: \(baseTranslation)\n"
            + TemplateFactory.contentIndentForLevel(contentLevel) + "public static func \(name)(\(methodHeader)) -> String {\n"
            + TemplateFactory.contentIndentForLevel(contentLevel + 1) + "return NSString(format: NSLocalizedString(\"\(key)\", tableName: nil, bundle: NSBundle.mainBundle(), value: \"\", comment: \"\"), \(params)) as String\n"
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




