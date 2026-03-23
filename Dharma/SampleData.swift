import Foundation

// MARK: - Sample Data
extension ScriptureItem {
    static let sampleData: [ScriptureItem] = gitaVerses + upanishadPassages + rigVedaSample + mantras + bhajans
}

// MARK: - Bhagavad Gita Verses (fallback only — real data loads from gita.json)
let gitaVerses: [ScriptureItem] = [
    ScriptureItem(
        category: .gita,
        title: "The Right to Action",
        subtitle: "Chapter 2, Verse 47",
        textEnglish: "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself the cause of the results of your activities, and never be attached to not doing your duty.",
        source: "Bhagavad Gita 2.47"
    ),
    ScriptureItem(
        category: .gita,
        title: "The Eternal Soul",
        subtitle: "Chapter 2, Verse 20",
        textEnglish: "The soul is never born nor dies at any time. It has not come into being, does not come into being, and will not come into being. It is unborn, eternal, ever-existing, and primeval. It is not slain when the body is slain.",
        source: "Bhagavad Gita 2.20"
    ),
    ScriptureItem(
        category: .gita,
        title: "Steadiness of Mind",
        subtitle: "Chapter 2, Verse 56",
        textEnglish: "One who is not disturbed in mind even amidst the threefold miseries or elated when there is happiness, and who is free from attachment, fear, and anger, is called a sage of steady mind.",
        source: "Bhagavad Gita 2.56"
    ),
    ScriptureItem(
        category: .gita,
        title: "The Restless Mind",
        subtitle: "Chapter 6, Verse 35",
        textEnglish: "The mind is restless and difficult to restrain, but it is subdued by practice and detachment. O son of Kunti, it is undoubtedly very difficult to curb the restless mind, but it is possible by suitable practice and by detachment.",
        source: "Bhagavad Gita 6.35"
    ),
    ScriptureItem(
        category: .gita,
        title: "Surrender to the Divine",
        subtitle: "Chapter 18, Verse 66",
        textEnglish: "Abandon all varieties of religion and just surrender unto Me. I shall deliver you from all sinful reactions. Do not fear.",
        source: "Bhagavad Gita 18.66"
    ),
    ScriptureItem(
        category: .gita,
        title: "The Indestructible Self",
        subtitle: "Chapter 2, Verse 23",
        textEnglish: "The soul can never be cut into pieces by any weapon, nor burned by fire, nor moistened by water, nor withered by the wind.",
        source: "Bhagavad Gita 2.23"
    ),
    ScriptureItem(
        category: .gita,
        title: "Equal Vision",
        subtitle: "Chapter 6, Verse 32",
        textEnglish: "He is a perfect yogi who, by comparison to his own self, sees the true equality of all beings, both in their happiness and their distress.",
        source: "Bhagavad Gita 6.32"
    ),
]

// MARK: - Upanishad Passages
let upanishadPassages: [ScriptureItem] = [
    ScriptureItem(
        category: .upanishads,
        title: "Tat Tvam Asi",
        subtitle: "Chandogya Upanishad 6.8.7",
        textEnglish: "That which is the finest essence — this whole world has that as its soul. That is Reality. That is Atman. That art thou, Shvetaketu.",
        source: "Chandogya Upanishad"
    ),
    ScriptureItem(
        category: .upanishads,
        title: "The Nature of Brahman",
        subtitle: "Mandukya Upanishad 1.2",
        textEnglish: "Brahman is all this. The Self is Brahman. This Self has four states of consciousness: waking, dreaming, deep sleep, and the fourth — pure consciousness beyond the three.",
        source: "Mandukya Upanishad"
    ),
    ScriptureItem(
        category: .upanishads,
        title: "Lead Me to Light",
        subtitle: "Brihadaranyaka Upanishad 1.3.28",
        textEnglish: "Lead me from the unreal to the real. Lead me from darkness to light. Lead me from death to immortality. Om, peace, peace, peace.",
        source: "Brihadaranyaka Upanishad"
    ),
    ScriptureItem(
        category: .upanishads,
        title: "The Self in All",
        subtitle: "Isha Upanishad 6",
        textEnglish: "He who sees all beings in the Self, and the Self in all beings, hates none. For one who sees oneness everywhere, how can there be delusion or grief?",
        source: "Isha Upanishad"
    ),
]

// MARK: - Rig Veda (fallback only — real data loads from rigveda.json)
let rigVedaSample: [ScriptureItem] = [
    ScriptureItem(
        category: .rigVeda,
        title: "Book 10 · Hymn 10.129.1",
        subtitle: "Rig Veda 10.129.1",
        textEnglish: "There was neither non-existence nor existence then; there was neither the realm of space nor the sky which is beyond.",
        source: "Rig Veda 10.129.1"
    ),
]

// MARK: - Mantras
let mantras: [ScriptureItem] = [
    ScriptureItem(
        category: .mantras,
        title: "Gayatri Mantra",
        subtitle: "Rig Veda 3.62.10",
        textEnglish: "Om. We meditate on the glory of the Creator who has created the Universe, who is worthy of worship, who is the embodiment of knowledge and light, who is the remover of sin and ignorance. May He enlighten our intellect.",
        source: "Rig Veda 3.62.10",
        audioFileName: "gayatri_mantra.mp3"
    ),
    ScriptureItem(
        category: .mantras,
        title: "Maha Mrityunjaya Mantra",
        subtitle: "Rig Veda 7.59.12",
        textEnglish: "Om. We worship the three-eyed one — Lord Shiva — who is fragrant and nourishes all beings. May he liberate us from death for the sake of immortality, even as the cucumber is severed from its bondage to the creeper.",
        source: "Rig Veda 7.59.12",
        audioFileName: "maha_mrityunjaya.mp3"
    ),
    ScriptureItem(
        category: .mantras,
        title: "Om Namah Shivaya",
        subtitle: "Krishna Yajurveda",
        textEnglish: "I bow to Shiva. Om and salutations to that which I am capable of becoming. This mantra is the great redeeming mantra of the Shaiva tradition, known as the Panchakshara — the five syllables.",
        source: "Krishna Yajurveda",
        audioFileName: "om_namah_shivaya.mp3"
    ),
    ScriptureItem(
        category: .mantras,
        title: "Om Namo Narayanaya",
        subtitle: "Taittiriya Upanishad",
        textEnglish: "I bow to Narayana — the one who is the resting place of all beings. This ashtakshara mantra is the essence of the Vedas, revealing the relationship between the individual soul and the Supreme.",
        source: "Taittiriya Upanishad",
        audioFileName: "om_namo_narayanaya.mp3"
    ),
]

// MARK: - Bhajans
let bhajans: [ScriptureItem] = [
    ScriptureItem(
        category: .bhajans,
        title: "Hare Krishna Maha Mantra",
        subtitle: "Kali-Santarana Upanishad",
        textEnglish: "Hare Krishna, Hare Krishna, Krishna Krishna, Hare Hare. Hare Rama, Hare Rama, Rama Rama, Hare Hare. The sixteen names and thirty-two syllables of this maha-mantra are the supreme means of liberation in the age of Kali.",
        source: "Kali-Santarana Upanishad",
        audioFileName: "hare_krishna.mp3"
    ),
    ScriptureItem(
        category: .bhajans,
        title: "Vaishnav Jan To",
        subtitle: "Narsinh Mehta, 15th century",
        textEnglish: "One who is a Vaishnava knows the pain of others, does good to others without letting pride enter his mind. A Vaishnava tolerates and praises the entire world, and does not speak ill of anyone.",
        source: "Narsinh Mehta",
        audioFileName: "vaishnav_jan_to.mp3"
    ),
]

// MARK: - Festival Sample Data (legacy compatibility)
extension HinduFestival {
    static let sampleData: [HinduFestival] = allFestivals
}
