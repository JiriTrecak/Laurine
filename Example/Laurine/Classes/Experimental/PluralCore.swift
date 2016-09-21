//
// Laurine - Plural Core Plugin
//
// Generate swift localization file based on localizables.string in plural form
//
// Note:
// Only for development. Will be merged to primary generator as soon as the rules are complete
//
// Licence: MIT
// Author: Jiří Třečák http://www.jiritrecak.com @jiritrecak
//

class PluralCore {
    
    // Plural groups base on CLDR definition
    enum PluralGroup {
        case zero
        case one
        case two
        case few
        case many
        case other
    }
    
    enum GenderGroup {
        case male
        case female
        case other
    }
    
    fileprivate func arabicRuleForCount(_ count : UInt) -> PluralGroup {
        
        switch count {
        case 0: return .zero
        case 1: return .one
        case 2: return .two
        default:
            let mod100 = count % 100
            if (mod100 >= 3 && mod100 <= 10) {
                return .few
            } else if (mod100 >= 11) {
                return .many
            } else {
                return .other
            }
        }
    }
    
    fileprivate func simplifiedChineseRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func traditionalChineseRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func catalanRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func croatianRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod10 {
        case 1:
            switch mod100 {
            case 11:
                break
            default:
                return .one
            }
        case 2, 3, 4:
            switch (mod100) {
            case 12, 13, 14:
                break
            default:
                return .few
            }
            
            break
        default:
            break
        }
        
        return .many
    }
    
    fileprivate func czechRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        case 2, 3, 4:
            return .few
        default:
            return .other
        }
    }
    
    fileprivate func englishRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func frenchRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 0, 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func germanRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func danishRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func dutchRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func finnishRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func greekRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func hebrewRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        
        switch (count) {
        case 1:
            return .one
        case 2:
            return .two
        case 3...10:
            break
        default:
            switch (mod10) {
            case 0:
                return .many
            default:
                break
            }
        }
        
        return .other
    }
    
    fileprivate func hungarianRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func indonesianRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func italianRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func japaneseRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func koreanRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func latvianRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if (count == 0) {
            return .zero
        }
        
        if (count == 1) {
            return .one
        }
        
        switch (mod10) {
        case 1:
            if (mod100 != 11) {
                return .one
            }
            break
        default:
            break
        }
        
        return .many
    }
    
    fileprivate func malayRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func norwegianBokamlRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func norwegianNynorskRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func polishRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if (count == 1) {
            return .one
        }
        
        switch mod10 {
        case 2...4:
            switch (mod100) {
            case 12...14:
                break
            default:
                return .few
            }
            
            break
        default:
            break
        }
        
        return .many
    }
    
    fileprivate func portugeseRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func romanianRuleForCount(_ count : UInt) -> PluralGroup {
        let mod100 = count % 100
        
        switch (count) {
        case 0:
            return .few
        case 1:
            return .one
        default:
            if (mod100 > 1 && mod100 <= 19) {
                return .few
            }
            break
        }
        
        return .other
    }
    
    fileprivate func russianRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod100 {
        case 11...14:
            break
            
        default:
            switch mod10 {
            case 1:
                return .one
            case 2...4:
                return .few
            default:
                break
            }
            
        }
        
        return .many
    }
    
    fileprivate func slovakRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        case 2...4:
            return .few
        default:
            return .other
        }
    }
    
    fileprivate func spanishRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func swedishRuleForCount(_ count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .one
        default:
            return .other
        }
    }
    
    fileprivate func thaiRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func turkishRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func ukrainianRuleForCount(_ count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod100 {
        case 11...14:
            break
            
        default:
            switch (mod10) {
            case 1:
                return .one
            case 2...4:
                return .few
            default:
                break
            }
            
        }
        
        return .many
    }
    
    fileprivate func vietnameseRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    
    fileprivate func unknownRuleForCount(_ count : UInt) -> PluralGroup {
        return .other
    }
    
    fileprivate func ruleForLanguageCode(_ code : String) -> ((_ count : UInt) -> PluralGroup) {
        
        switch code {
            case "ar": return self.vietnameseRuleForCount
            case "ca": return self.catalanRuleForCount
            case "zh-Hans": return self.simplifiedChineseRuleForCount
            case "zh-Hant": return self.traditionalChineseRuleForCount
            case "cr": return croatianRuleForCount
            case "cs": return czechRuleForCount
            case "da": return danishRuleForCount
            case "nl": return dutchRuleForCount
            case "en": return englishRuleForCount
            case "fr": return frenchRuleForCount
            case "de": return germanRuleForCount
            case "fi": return finnishRuleForCount
            case "el": return greekRuleForCount
            case "he": return hebrewRuleForCount
            case "hu": return hungarianRuleForCount
            case "id": return indonesianRuleForCount
            case "it": return italianRuleForCount
            case "ja": return japaneseRuleForCount
            case "ko": return koreanRuleForCount
            case "lv": return latvianRuleForCount
            case "ms": return malayRuleForCount
            case "nb": return norwegianBokamlRuleForCount
            case "nn": return norwegianNynorskRuleForCount
            case "pl": return polishRuleForCount
            case "pt": return portugeseRuleForCount
            case "ro": return romanianRuleForCount
            case "ru": return russianRuleForCount
            case "es": return spanishRuleForCount
            case "sk": return slovakRuleForCount
            case "sv": return swedishRuleForCount
            case "th": return thaiRuleForCount
            case "tr": return turkishRuleForCount
            case "uk": return ukrainianRuleForCount
            case "vi": return vietnameseRuleForCount
            default:
            print("whoa whoa, unsupported language %@ bro!", code)
            return unknownRuleForCount
        }
    }
}
