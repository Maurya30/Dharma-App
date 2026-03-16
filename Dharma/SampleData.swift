import Foundation

// MARK: - Sample Data
extension ScriptureItem {
    static let sampleData: [ScriptureItem] = gitaVerses + upanishadPassages + mantras + bhajans
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

// MARK: - Festival Sample Data
extension HinduFestival {
    static let sampleData: [HinduFestival] = {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        func date(_ month: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        }
        return [
            HinduFestival(
                name: "Holi",
                date: date(3, 14),
                deity: "Lord Krishna & Radha",
                shortDescription: "Festival of colours and spring",
                fullStory: "Holi commemorates the victory of good over evil through the story of Prahlad and Holika. Holika, the demoness sister of King Hiranyakashipu, tried to burn the devoted child Prahlad. But through divine grace, Prahlad emerged unscathed while Holika perished. The bonfire lit on Holi eve — Holika Dahan — symbolises this victory. The next day, people celebrate with coloured powders and water, embodying the joy of spring and divine love.",
                significance: "Victory of good over evil. Arrival of spring. Celebration of divine love between Radha and Krishna.",
                howToObserve: "Light a bonfire on the eve of Holi. On Holi day, play with natural colours. Visit friends and family. Offer sweets. Chant the names of Lord Krishna."
            ),
            HinduFestival(
                name: "Ram Navami",
                date: date(4, 6),
                deity: "Lord Rama",
                shortDescription: "Birth of Lord Rama, seventh avatar of Vishnu",
                fullStory: "Ram Navami celebrates the birth of Lord Rama, the seventh incarnation of Lord Vishnu, born to King Dasharatha and Queen Kaushalya of Ayodhya. Born at noon on the ninth day of the bright fortnight of Chaitra, Rama is the ideal human being — the embodiment of dharma, truth, and virtue. His life story, told in the Ramayana by Sage Valmiki, is the eternal story of righteousness prevailing over adharma.",
                significance: "Celebration of dharma, righteousness, and the ideal human life. Rama is the model of the perfect son, husband, king, and warrior.",
                howToObserve: "Read or listen to the Ramayana. Chant Ram Nam. Visit Rama temples. Fast until midday. Perform Rama puja with flowers, tulsi leaves, and fruits."
            ),
            HinduFestival(
                name: "Janmashtami",
                date: date(8, 26),
                deity: "Lord Krishna",
                shortDescription: "Birth of Lord Krishna, eighth avatar of Vishnu",
                fullStory: "Janmashtami celebrates the birth of Lord Krishna, the eighth avatar of Vishnu, born at midnight in a prison cell in Mathura to Devaki and Vasudeva. His birth during a dark stormy night symbolises the arrival of divine light into the world's darkness. Krishna's life — from his miraculous escape to Gokul, his childhood in Vrindavan, his teachings in the Mahabharata as the Bhagavad Gita — is the complete expression of divine love, wisdom, and play.",
                significance: "The fullest expression of divine love and wisdom. Krishna's teachings in the Gita are the foundation of this very app.",
                howToObserve: "Fast until midnight. Sing bhajans. At midnight, bathe and dress a Krishna murti. Perform aarti. Break fast with prasad. Enact the life of Krishna."
            ),
            HinduFestival(
                name: "Navratri",
                date: date(10, 2),
                deity: "Goddess Durga / Devi",
                shortDescription: "Nine nights of the Divine Mother",
                fullStory: "Navratri — nine nights — is the celebration of Goddess Durga's victory over the buffalo demon Mahishasura. Each of the nine nights honours one of Devi's nine forms: Shailaputri, Brahmacharini, Chandraghanta, Kushmanda, Skandamata, Katyayani, Kalaratri, Mahagauri, and Siddhidatri. The festival reminds us that the divine feminine — Shakti — is the power behind all creation, preservation, and dissolution.",
                significance: "Worship of the divine feminine. Victory of dharma. Inner purification through fasting, prayer, and devotion.",
                howToObserve: "Fast for nine days. Recite the Durga Saptashati. Light a lamp (akhand jyoti). Visit Devi temples. On the ninth day (Navami), perform Kanya Puja."
            ),
            HinduFestival(
                name: "Diwali",
                date: date(10, 20),
                deity: "Lord Rama & Goddess Lakshmi",
                shortDescription: "Festival of lights",
                fullStory: "Diwali marks Lord Rama's return to Ayodhya after 14 years of exile and his victory over the demon king Ravana. The people of Ayodhya lit oil lamps — diyas — to welcome their beloved king home. Diwali also celebrates Goddess Lakshmi, the deity of wealth and prosperity, who is said to visit clean and well-lit homes on this night. For Jains it marks Mahavira's nirvana, and for Sikhs the release of Guru Hargobind from prison.",
                significance: "Victory of light over darkness, knowledge over ignorance, good over evil. Welcoming of prosperity and new beginnings.",
                howToObserve: "Light diyas and candles. Perform Lakshmi puja in the evening. Burst crackers (mindfully). Share sweets. Wear new clothes. Clean and decorate the home."
            ),
        ]
    }()
}
