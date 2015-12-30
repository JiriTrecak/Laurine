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
        case Zero
        case One
        case Two
        case Few
        case Many
        case Other
    }
    
    enum GenderGroup {
        case Male
        case Female
        case Other
    }
    
    private func arabicRuleForCount(count : UInt) -> PluralGroup {
        
        switch count {
        case 0: return .Zero
        case 1: return .One
        case 2: return .Two
        default:
            let mod100 = count % 100
            if (mod100 >= 3 && mod100 <= 10) {
                return .Few
            } else if (mod100 >= 11) {
                return .Many
            } else {
                return .Other
            }
        }
    }
    
    private func simplifiedChineseRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func traditionalChineseRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func catalanRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func croatianRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod10 {
        case 1:
            switch mod100 {
            case 11:
                break
            default:
                return .One
            }
        case 2, 3, 4:
            switch (mod100) {
            case 12, 13, 14:
                break
            default:
                return .Few
            }
            
            break
        default:
            break
        }
        
        return .Many
    }
    
    private func czechRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        case 2, 3, 4:
            return .Few
        default:
            return .Other
        }
    }
    
    private func englishRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func frenchRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 0, 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func germanRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func danishRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func dutchRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func finnishRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func greekRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func hebrewRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        
        switch (count) {
        case 1:
            return .One
        case 2:
            return .Two
        case 3...10:
            break
        default:
            switch (mod10) {
            case 0:
                return .Many
            default:
                break
            }
        }
        
        return .Other
    }
    
    private func hungarianRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func indonesianRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func italianRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func japaneseRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func koreanRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func latvianRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if (count == 0) {
            return .Zero
        }
        
        if (count == 1) {
            return .One
        }
        
        switch (mod10) {
        case 1:
            if (mod100 != 11) {
                return .One
            }
            break
        default:
            break
        }
        
        return .Many
    }
    
    private func malayRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func norwegianBokamlRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func norwegianNynorskRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func polishRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        if (count == 1) {
            return .One
        }
        
        switch mod10 {
        case 2...4:
            switch (mod100) {
            case 12...14:
                break
            default:
                return .Few
            }
            
            break
        default:
            break
        }
        
        return .Many
    }
    
    private func portugeseRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func romanianRuleForCount(count : UInt) -> PluralGroup {
        let mod100 = count % 100
        
        switch (count) {
        case 0:
            return .Few
        case 1:
            return .One
        default:
            if (mod100 > 1 && mod100 <= 19) {
                return .Few
            }
            break
        }
        
        return .Other
    }
    
    private func russianRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod100 {
        case 11...14:
            break
            
        default:
            switch mod10 {
            case 1:
                return .One
            case 2...4:
                return .Few
            default:
                break
            }
            
        }
        
        return .Many
    }
    
    private func slovakRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        case 2...4:
            return .Few
        default:
            return .Other
        }
    }
    
    private func spanishRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func swedishRuleForCount(count : UInt) -> PluralGroup {
        switch (count) {
        case 1:
            return .One
        default:
            return .Other
        }
    }
    
    private func thaiRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func turkishRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
    
    private func ukrainianRuleForCount(count : UInt) -> PluralGroup {
        let mod10 = count % 10
        let mod100 = count % 100
        
        switch mod100 {
        case 11...14:
            break
            
        default:
            switch (mod10) {
            case 1:
                return .One
            case 2...4:
                return .Few
            default:
                break
            }
            
        }
        
        return .Many
    }
    
    private func vietnameseRuleForCount(count : UInt) -> PluralGroup {
        return .Other
    }
}