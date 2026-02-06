import Foundation

enum KeyNote: String, CaseIterable, Identifiable {
    case c, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }

    var semitoneFromC: Int {
        switch self {
        case .c: return 0
        case .cSharp: return 1
        case .d: return 2
        case .dSharp: return 3
        case .e: return 4
        case .f: return 5
        case .fSharp: return 6
        case .g: return 7
        case .gSharp: return 8
        case .a: return 9
        case .aSharp: return 10
        case .b: return 11
        }
    }
}

enum ScaleType: String, CaseIterable, Identifiable {
    case major
    case minor
    case majorPentatonic
    case minorPentatonic
    case dorian
    case mixolydian
    case blues

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        case .majorPentatonic: return "Major Pentatonic"
        case .minorPentatonic: return "Minor Pentatonic"
        case .dorian: return "Dorian"
        case .mixolydian: return "Mixolydian"
        case .blues: return "Blues"
        }
    }

    var steps: [Int] {
        switch self {
        case .major: return [0, 2, 4, 5, 7, 9, 11]
        case .minor: return [0, 2, 3, 5, 7, 8, 10]
        case .majorPentatonic: return [0, 2, 4, 7, 9]
        case .minorPentatonic: return [0, 3, 5, 7, 10]
        case .dorian: return [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]
        case .blues: return [0, 3, 5, 6, 7, 10]
        }
    }
}

struct NoteMapper {
    private let key: KeyNote
    private let scale: ScaleType
    private let maxOctaves: Int = 3
    private let baseOctave: Int

    init(key: KeyNote, scale: ScaleType, octaveShift: Int) {
        self.key = key
        self.scale = scale
        let rawBase = 3 + octaveShift
        self.baseOctave = max(1, min(6, rawBase))
    }

    func note(for word: String, position: Int) -> UInt8 {
        let seed = Hashing.fnv1a64(word)
        let mixed = Hashing.splitmix64(seed ^ UInt64(position &* 31))
        let steps = scale.steps
        let totalNotes = steps.count * maxOctaves
        let noteIndex = Int(mixed % UInt64(totalNotes))
        let octave = noteIndex / steps.count
        let degree = noteIndex % steps.count

        let rootMidi = (baseOctave + 1) * 12 + key.semitoneFromC
        let midi = rootMidi + steps[degree] + (12 * octave)
        return UInt8(max(0, min(127, midi)))
    }
}

struct WordTracker {
    private(set) var currentWord: String = ""
    private(set) var position: Int = 0

    mutating func append(_ character: Character) -> (String, Int) {
        position = currentWord.count
        currentWord.append(character)
        return (currentWord, position)
    }

    mutating func backspace() {
        guard !currentWord.isEmpty else { return }
        currentWord.removeLast()
        position = max(0, currentWord.count)
    }

    mutating func reset() {
        currentWord = ""
        position = 0
    }

    func isWordCharacter(_ character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
    }
}

enum Hashing {
    static func fnv1a64(_ string: String) -> UInt64 {
        let prime: UInt64 = 1099511628211
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }

    static func splitmix64(_ seed: UInt64) -> UInt64 {
        var x = seed &+ 0x9E3779B97F4A7C15
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        return x ^ (x >> 31)
    }
}
