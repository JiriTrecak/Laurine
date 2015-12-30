

## 0.3.0 (coming January 2016)

Enhancements:

- Support for plurals / gender [WIP]
- Support for all special symbols [WIP]

## 0.2.2 (2015-12-30)

Bugfixes:

- When last-level-string is also substring of longer string, generate special property in deeper levels instead of throwing it out (fe. profile.text & profile.text.title)
- Keywords of each language are now properly sanitized in the same way as numbers (prefixed with _)

## 0.2.1 (2015-12-10)

Enhancements:

- **Example is now pretty sweet. [check it out](https://github.com/JiriTrecak/Laurine/tree/master/Example).**

## 0.2.0 (2015-11-29)

Enhancements:

- **ObjC code generation**
- New option -c --capitalize - enables autocapitalization of the property / method names
- New option -l --language [objc|swift] - decides which language should be generated
- New option -v --verbose - when selected, creates generator.log file in the place of the generator, for debugging purposes and statistics
- New option -o - when set, will write output to file (or 2 files if objc is enabled). If ommited, will send output to stdout instead

Bugfixes:

- Properties and methods that start with numbers [0-9] or any other character that qualifies will now get prefixed with "_" instead of completely breaking output :)
- Fixed all problems that prevented scripts from build phase to actually work

## 0.1.0 (2015-11-18)

Initial release

Enhancements:

- Input parameter processing
- Translation file processing
- Swift code generation
- Nested structs
- Localize methods and extensions
- Static vars for end-level parameters
- Special characters parsed as functions