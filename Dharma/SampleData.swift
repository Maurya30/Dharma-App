import Foundation

// MARK: - Sample Data
extension ScriptureItem {
    static let sampleData: [ScriptureItem] = gitaVerses + upanishadPassages + rigVedaSample + mantras
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
        title: "Om",
        subtitle: "The primordial sound",
        textEnglish: "Om is the primordial sound of the universe — the vibration from which all existence emerges. It represents the three states of consciousness: A (waking), U (dreaming), M (deep sleep), and the silence beyond.",
        source: "Mandukya Upanishad · Rig Veda",
        audioFileName: "om.mp3",
        mantraTransliteration: "Om (Aum)",
        mantraSanskrit: "ॐ",
        mantraMeaning: "Om is considered the first sound of creation — the vibration from which all existence emerges. In the Upanishads it is declared: 'That syllable is Brahman.' It represents the three states of consciousness: A (waking), U (dreaming), M (deep sleep), and the silence beyond — Turiya. Chanting Om aligns the individual consciousness with universal consciousness. It is both the beginning and the end, the known and the unknown.",
        mantraBenefits: ["Calms the nervous system", "Reduces anxiety and stress", "Deepens meditation", "Aligns body and mind", "Connects to universal consciousness"],
        mantraHowToChant: "Sit comfortably. Take a deep breath. As you exhale, chant A-U-M slowly, feeling A vibrate in the belly, U in the chest, M at the lips. Let the silence after the M be as important as the sound. Chant 3, 9, or 108 times.",
        mantraRepetitions: 108,
        mantraDeity: "Brahman (the Absolute)",
        mantraIsBeej: true,
        mantraCategory: "Universal"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Gayatri Mantra",
        subtitle: "Rig Veda 3.62.10",
        textEnglish: "Om. We meditate on the divine light of that adorable Supreme Reality. May it illuminate our intellect.",
        source: "Rig Veda 3.62.10",
        audioFileName: "gayatri_mantra.mp3",
        mantraTransliteration: "Om bhūr bhuvaḥ svaḥ, tat saviturvareṇyam, bhargo devasya dhīmahi, dhiyo yo naḥ pracodayāt",
        mantraSanskrit: "ॐ भूर्भुवः स्वः\nतत्सवितुर्वरेण्यं\nभर्गो देवस्य धीमहि\nधियो यो नः प्रचोदयात्",
        mantraMeaning: "The Gayatri Mantra is the most sacred and revered mantra in the Vedic tradition, found in the Rig Veda (3.62.10) and composed by the sage Vishwamitra over 3,500 years ago. The opening 'Om bhur bhuvah svah' invokes the three cosmic realms — Earth (bhur), Atmosphere (bhuvah), and Heaven (svah). 'Tat savitur vareṇyam' means 'that adorable divine light of the Sun.' 'Bhargo devasya dhīmahi' means 'we meditate on the splendor of that divine being.' 'Dhiyo yo naḥ pracodayāt' means 'may that Supreme Being stimulate our understanding.' It is a prayer not for material things but for illuminated intelligence — the highest form of prayer.",
        mantraBenefits: ["Purifies the mind and intellect", "Enhances concentration and memory", "Removes ignorance and brings clarity", "Awakens inner wisdom", "Said to purify all three bodies — physical, astral, causal"],
        mantraHowToChant: "Traditionally chanted three times daily — at sunrise, noon, and sunset. Face east in the morning. Sit quietly, close your eyes, and chant slowly and clearly with understanding of its meaning. 108 repetitions each morning is ideal. Use a mala to count. The Gayatri is traditionally chanted aloud, not silently.",
        mantraRepetitions: 108,
        mantraDeity: "Savitar (Solar Deity · Brahman)",
        mantraIsBeej: false,
        mantraCategory: "Surya"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Namah Shivaya",
        subtitle: "Krishna Yajurveda · Shri Rudram",
        textEnglish: "I bow to Shiva — to the auspicious one, the true inner Self. The five syllables Na-Ma-Shi-Va-Ya correspond to the five elements: earth, water, fire, air, and ether.",
        source: "Krishna Yajurveda",
        audioFileName: "om_namah_shivaya.mp3",
        mantraTransliteration: "Om Namaḥ Śivāya",
        mantraSanskrit: "ॐ नमः शिवाय",
        mantraMeaning: "Om Namah Shivaya is called the Panchakshara — the five-syllable mantra (Na-Ma-Shi-Va-Ya), each syllable corresponding to one of the five elements: Na (earth), Ma (water), Shi (fire), Va (air), Ya (ether). Together they represent the entire manifest universe offered back to its source. 'Namah' means 'I bow' or 'I surrender.' 'Shivaya' means 'to Shiva' — not only the deity with the blue throat, but the cosmic consciousness that dwells as the innermost Self in every being. Chanting this mantra is an act of recognizing that the divine is not distant but your own deepest nature.",
        mantraBenefits: ["Destroys ego and false identification", "Brings inner peace and stillness", "Purifies karma", "Awakens the Self", "Protection from negative forces"],
        mantraHowToChant: "Can be chanted silently or aloud, at any time. Especially powerful during Pradosh (13th lunar day), Mondays, or Maha Shivaratri. Chant 108 times on a rudraksha mala if possible. Let the mantra synchronize with the breath — inhale 'Om Namah,' exhale 'Shivaya.' Can also be mentally repeated throughout the day as a constant practice.",
        mantraRepetitions: 108,
        mantraDeity: "Shiva",
        mantraIsBeej: false,
        mantraCategory: "Shiva"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Mahamrityunjaya Mantra",
        subtitle: "Rig Veda 7.59.12",
        textEnglish: "We worship the three-eyed Shiva who is fragrant and nourishes all beings. May he liberate us from death for the sake of immortality, even as the cucumber is severed from its vine.",
        source: "Rig Veda 7.59.12",
        audioFileName: "maha_mrityunjaya.mp3",
        mantraTransliteration: "Om Tryambakaṃ Yajāmahe, Sugandhiṃ Puṣṭivardhanam, Urvārukamiva Bandhanān, Mṛtyormukṣīya Māmṛtāt",
        mantraSanskrit: "ॐ त्र्यम्बकं यजामहे\nसुगन्धिं पुष्टिवर्धनम्\nउर्वारुकमिव बन्धनान्\nमृत्योर्मुक्षीय माऽमृतात्",
        mantraMeaning: "The Mahamrityunjaya — the Great Death-Conquering Mantra — is one of the oldest and most powerful mantras in the Rig Veda (7.59.12), attributed to the sage Vasishtha. 'Tryambakam' refers to the three-eyed Shiva — the third eye representing transcendent wisdom. 'Sugandhim' (fragrant) and 'Pushtivardhanam' (nourisher of all) describe Shiva as the life-force sustaining all existence. The cucumber simile is profound — just as a ripe cucumber detaches naturally from its vine without being cut, may we be released naturally from death into immortality. This mantra asks not for immortality of the body but liberation from the fear of death and the cycle of rebirth.",
        mantraBenefits: ["Conquers fear of death", "Healing of body and mind", "Protection during illness or danger", "Liberation from the cycle of rebirth", "Gives courage in the face of mortality"],
        mantraHowToChant: "Chant 108 times during serious illness, danger, or fear. Also chanted regularly as a preventive practice. Especially powerful on Maha Shivaratri, Mondays, and during Pradosh. Can be chanted for someone who is ill by dedicating the merit to them.",
        mantraRepetitions: 108,
        mantraDeity: "Shiva (Tryambaka)",
        mantraIsBeej: false,
        mantraCategory: "Shiva"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Hare Krishna Maha Mantra",
        subtitle: "Kali Santarana Upanishad",
        textEnglish: "Hare Krishna, Hare Krishna, Krishna Krishna, Hare Hare. Hare Rama, Hare Rama, Rama Rama, Hare Hare. The sixteen names and thirty-two syllables of this maha-mantra are the supreme means of liberation in the age of Kali.",
        source: "Kali Santarana Upanishad",
        audioFileName: "hare_krishna.mp3",
        mantraTransliteration: "Hare Kṛṣṇa Hare Kṛṣṇa, Kṛṣṇa Kṛṣṇa Hare Hare, Hare Rāma Hare Rāma, Rāma Rāma Hare Hare",
        mantraSanskrit: "हरे कृष्ण हरे कृष्ण\nकृष्ण कृष्ण हरे हरे\nहरे राम हरे राम\nराम राम हरे हरे",
        mantraMeaning: "The Maha Mantra contains only three Sanskrit words — Hare, Krishna, and Rama — repeated in a pattern of 16 words and 32 syllables. 'Hare' addresses the divine energy (Radha, the feminine aspect of God). 'Krishna' means 'the all-attractive one.' 'Rama' means 'the source of all pleasure.' Together they are a direct call to the divine — not a philosophical statement but a cry of longing. The Kali Santarana Upanishad declares this to be the supreme mantra for the age of Kali Yuga. Chanting it is said to remove the covering of maya (illusion) from the heart.",
        mantraBenefits: ["Brings inner peace and joy", "Purifies consciousness", "Develops devotion (bhakti)", "Calms the mind during turbulence", "Said to grant liberation in Kali Yuga"],
        mantraHowToChant: "Chant aloud, softly, or mentally. The sound vibration itself is considered sacred regardless of the chanter's purity. One round on a mala equals 108 repetitions of the full mantra. Chanting in community (kirtan) amplifies the effect. No initiation required.",
        mantraRepetitions: 108,
        mantraDeity: "Krishna · Radha · Rama",
        mantraIsBeej: false,
        mantraCategory: "Krishna"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Gam Ganapataye Namaha",
        subtitle: "Ganapati Atharvashirsha Upanishad",
        textEnglish: "Om, salutations to Ganesha, remover of obstacles. This mantra is chanted at the beginning of every major undertaking to invoke Ganesha's blessing and clear the path ahead.",
        source: "Ganapati Atharvashirsha Upanishad",
        audioFileName: "om_gam_ganapataye.mp3",
        mantraTransliteration: "Om Gaṃ Gaṇapataye Namaḥ",
        mantraSanskrit: "ॐ गं गणपतये नमः",
        mantraMeaning: "This is the primary mantra of Lord Ganesha — the elephant-headed son of Shiva and Parvati, universally honored as Vighnaharta (remover of obstacles). 'Gam' is the beej (seed) syllable of Ganesha, containing the concentrated vibrational essence of his energy. 'Ganapataye' means 'lord of the ganas.' This mantra is chanted at the beginning of every major undertaking — a journey, a business, a study, a practice — because Ganesha as lord of beginnings must be honored first. Internally, it acknowledges that inner resistances — fears, doubts, karmic blocks — must be dissolved before anything new can arise.",
        mantraBenefits: ["Removes obstacles internal and external", "Brings success to new beginnings", "Sharpens focus and intellect", "Invokes divine grace at the start of any endeavor", "Dissolves fear and self-doubt"],
        mantraHowToChant: "Always chant this mantra first before beginning any spiritual practice, study, or important undertaking. 108 repetitions on a mala is ideal. Especially powerful on Chaturthi (4th lunar day), Wednesdays, and during Ganesh Chaturthi festival.",
        mantraRepetitions: 108,
        mantraDeity: "Ganesha",
        mantraIsBeej: true,
        mantraCategory: "Ganesha"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Namo Narayanaya",
        subtitle: "Taittiriya Upanishad · Vishnu Purana",
        textEnglish: "I bow to Narayana — the one who pervades all, the resting place of all beings. This eight-syllable mantra is the essence of the Vedas and the mantra of surrender.",
        source: "Taittiriya Upanishad",
        audioFileName: "om_namo_narayanaya.mp3",
        mantraTransliteration: "Om Namo Nārāyaṇāya",
        mantraSanskrit: "ॐ नमो नारायणाय",
        mantraMeaning: "The Ashtakshara — the eight-syllable mantra of Vishnu. 'Narayana' comes from 'nara' (human beings, waters) and 'ayana' (abode, refuge) — literally 'the resting place of all beings.' Vishnu is the preserver of the universe, the one who maintains dharma through his avatars. This mantra invokes the all-pervasive nature of Vishnu — the recognition that the divine is not separate from creation but its very sustaining ground. It is the mantra of surrender, of taking refuge in the one who upholds all of existence.",
        mantraBenefits: ["Cultivates surrender and trust", "Invokes divine protection", "Removes fear", "Deepens devotion (bhakti)", "Traditionally associated with liberation"],
        mantraHowToChant: "Chant 108 times on a Tulsi mala if available. Especially powerful on Ekadashi days, Thursdays, and during Vishnu-related festivals. Can be chanted while visualizing the divine light of Vishnu pervading all of existence.",
        mantraRepetitions: 108,
        mantraDeity: "Vishnu · Narayana",
        mantraIsBeej: false,
        mantraCategory: "Vishnu"
    ),
    ScriptureItem(
        category: .mantras,
        title: "Om Aim Saraswatyai Namaha",
        subtitle: "Devi Mahatmya · Saraswati Stotra",
        textEnglish: "Om, salutations to Goddess Saraswati — the goddess of knowledge, speech, music, arts, and wisdom. Invoked before all learning and creative work.",
        source: "Devi Mahatmya",
        audioFileName: "om_aim_saraswatyai.mp3",
        mantraTransliteration: "Om Aiṃ Sarasvatyai Namaḥ",
        mantraSanskrit: "ॐ ऐं सरस्वत्यै नमः",
        mantraMeaning: "The primary mantra of Saraswati — goddess of knowledge, speech, music, arts, wisdom, and learning. 'Aim' is the beej (seed) syllable of Saraswati, containing the concentrated energy of her domain. Saraswati's name derives from 'saras' (flowing) and 'wati' (she who has) — she who flows, representing the river of consciousness, speech, and creativity. This mantra is invoked before study, learning, creative work, or any endeavor requiring clarity of mind and inspired expression. It is the mantra of the student, the artist, the teacher, and the seeker of truth.",
        mantraBenefits: ["Enhances learning and memory", "Removes blocks to creative expression", "Improves speech and communication", "Invokes clarity of mind", "Especially powerful for students and artists"],
        mantraHowToChant: "Chant 108 times before study or creative work. Especially powerful on Vasant Panchami, Thursdays, and Saraswati Puja. Sit facing east. Can be chanted while placing books or instruments before her image.",
        mantraRepetitions: 108,
        mantraDeity: "Saraswati",
        mantraIsBeej: true,
        mantraCategory: "Devi"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Shrim Maha Lakshmiyei Namaha",
        subtitle: "Sri Sukta · Rig Veda · Lakshmi Tantra",
        textEnglish: "Om, salutations to the great Goddess Lakshmi — goddess of abundance, prosperity, beauty, grace, and spiritual wealth.",
        source: "Sri Sukta · Rig Veda",
        audioFileName: "om_shrim_lakshmi.mp3",
        mantraTransliteration: "Om Śrīṃ Mahālakṣmyai Namaḥ",
        mantraSanskrit: "ॐ श्रीं महालक्ष्म्यै नमः",
        mantraMeaning: "The mantra of Lakshmi — goddess of abundance, prosperity, beauty, grace, and spiritual wealth. 'Shrim' is the beej syllable of Lakshmi, the sound vibration that resonates with the energy of abundance and grace. 'Maha' means great. 'Lakshmi' derives from 'lakshya' meaning goal or aim — she who helps you achieve your highest aim. Lakshmi represents not only material prosperity but also the inner qualities that attract grace: gratitude, generosity, beauty of character, and devotion. The mantra invokes these qualities as much as external abundance.",
        mantraBenefits: ["Invokes abundance and prosperity", "Cultivates gratitude and generosity", "Removes poverty consciousness", "Attracts grace into all areas of life", "Strengthens the quality of devotion"],
        mantraHowToChant: "Chant 108 times on Fridays, on Diwali, or during Lakshmi Puja. Light a diya (oil lamp) if possible. Chant facing north or east. Can be chanted while visualizing golden light filling your heart with warmth and gratitude.",
        mantraRepetitions: 108,
        mantraDeity: "Lakshmi",
        mantraIsBeej: true,
        mantraCategory: "Devi"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Dum Durgayei Namaha",
        subtitle: "Devi Mahatmya · Durga Saptashati",
        textEnglish: "Om, salutations to Goddess Durga — the invincible one, the fierce and protective mother who destroys evil and guards her devotees.",
        source: "Devi Mahatmya",
        audioFileName: "om_dum_durgayei.mp3",
        mantraTransliteration: "Om Duṃ Durgāyai Namaḥ",
        mantraSanskrit: "ॐ दुं दुर्गायै नमः",
        mantraMeaning: "The primary mantra of Durga — the fierce, protective mother goddess who destroys evil and protects her devotees. 'Dum' is the beej syllable of Durga, carrying her protective and transformative energy. 'Durga' means 'the invincible one' — referring to her transcendence of ordinary consciousness. Durga represents the divine feminine power (Shakti) in its most active, protective form. She rides a lion and carries weapons in her many hands — not to harm but to slay the demons within us: ego, ignorance, lust, anger, and greed.",
        mantraBenefits: ["Protection from negative forces", "Courage in difficult situations", "Destroys inner demons — ego, fear, anger", "Invokes divine feminine power", "Especially potent during Navratri"],
        mantraHowToChant: "Chant 108 times during Navratri, on Tuesdays and Fridays, or when facing fear or difficulty. Can be chanted while lighting incense and visualizing Durga's golden light surrounding and protecting you.",
        mantraRepetitions: 108,
        mantraDeity: "Durga · Shakti",
        mantraIsBeej: true,
        mantraCategory: "Devi"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Mani Padme Hum",
        subtitle: "Karandavyuha Sutra · Hindu-Buddhist tradition",
        textEnglish: "The jewel in the lotus. One of the most widely chanted mantras in the world — a prayer of universal compassion and wisdom, revered across Hindu and Buddhist traditions.",
        source: "Karandavyuha Sutra",
        audioFileName: "om_mani_padme_hum.mp3",
        mantraTransliteration: "Om Maṇi Padme Hūm",
        mantraSanskrit: "ॐ मणि पद्मे हूँ",
        mantraMeaning: "One of the most widely chanted mantras in the world, revered in both Hindu and Buddhist traditions. 'Om' is the universal sound. 'Mani' means jewel — representing compassion, love, the enlightened mind. 'Padme' means lotus — the symbol of wisdom growing through mud toward light. 'Hum' represents the indivisibility of compassion and wisdom. Together: the jewel of compassion in the lotus of wisdom. The mantra is said to purify the six realms of existence — one syllable for each realm. The compassion it cultivates is boundless.",
        mantraBenefits: ["Cultivates universal compassion", "Purifies speech, body, and mind", "Brings peace to the heart", "Develops empathy and loving-kindness", "Widely used in meditation and walking practice"],
        mantraHowToChant: "Can be chanted aloud, whispered, or silently repeated with each breath. No initiation required. Especially powerful when combined with visualization of a lotus in the heart. 108 repetitions on a mala. Can also be constantly mentally repeated throughout daily activity.",
        mantraRepetitions: 108,
        mantraDeity: "Avalokiteshvara · The Divine Mother",
        mantraIsBeej: false,
        mantraCategory: "Universal"
    ),

    ScriptureItem(
        category: .mantras,
        title: "So'Ham",
        subtitle: "Isha Upanishad · Vedic tradition",
        textEnglish: "I am That. The universal mantra of the Self — the direct declaration of non-duality, of the identity between the individual self and the universal Self. Said to be the natural sound of every breath.",
        source: "Isha Upanishad",
        audioFileName: "soham.mp3",
        mantraTransliteration: "So'Ham",
        mantraSanskrit: "सोऽहम्",
        mantraMeaning: "So'Ham is considered the universal mantra — the mantra of the Self. 'Sah' means 'He' or 'That' (the Absolute, Brahman, universal consciousness). 'Aham' means 'I am.' Together: 'I am That' — the direct declaration of non-duality, of the identity between the individual self (jiva) and the universal Self (Brahman). So'Ham is said to be the natural sound of the breath itself — 'So' on the inhale, 'Ham' on the exhale. Every being breathes this mantra 21,600 times per day without knowing it. Becoming conscious of this transforms ordinary breathing into continuous meditation.",
        mantraBenefits: ["Deepens self-inquiry", "Cultivates non-dual awareness", "Can be practiced at all times as breath meditation", "Dissolves separation between self and universe", "The foundation of all meditation"],
        mantraHowToChant: "This mantra is naturally synchronized with the breath. On each inhale, mentally hear 'So.' On each exhale, mentally hear 'Ham.' No counting needed — simply become aware of the mantra in the breath itself. This can be practiced during any activity. It is the most portable of all meditations.",
        mantraRepetitions: 0,
        mantraDeity: "Atman · Brahman (the Self)",
        mantraIsBeej: false,
        mantraCategory: "Universal"
    ),
    ScriptureItem(
        category: .mantras,
        title: "Guru Mantra",
        subtitle: "Guru Gita · Skanda Purana",
        textEnglish: "The Guru is Brahma, the Guru is Vishnu, the Guru is Shiva. The Guru is the Supreme Brahman itself. To that Guru I offer my salutations.",
        source: "Guru Gita · Skanda Purana",
        audioFileName: "guru_mantra.mp3",
        mantraTransliteration: "Om Gurur Brahmā Gurur Viṣṇuḥ, Gurur Devo Maheśvaraḥ, Guruḥ Sākṣāt Paraṃ Brahma, Tasmai Śrī Gurave Namaḥ",
        mantraSanskrit: "ॐ गुरुर् ब्रह्मा गुरुर् विष्णुः\nगुरुर् देवो महेश्वरः\nगुरुः साक्षात् परं ब्रह्म\nतस्मै श्री गुरवे नमः",
        mantraMeaning: "This mantra honors the Guru — the spiritual teacher — as the embodiment of the entire divine trinity and of Brahman itself. 'Guru' derives from 'gu' (darkness, ignorance) and 'ru' (one who removes) — the one who removes darkness. The mantra declares that the Guru who removes your ignorance IS Brahma (the creator of understanding in you), Vishnu (the sustainer of your practice), and Shiva (the destroyer of your ego). The outer teacher points to the inner teacher — the Guru within, which is your own awakened consciousness.",
        mantraBenefits: ["Honors the teacher within and without", "Opens the heart to learning", "Cultivates humility and receptivity", "Invokes divine guidance", "Traditionally chanted before all spiritual study"],
        mantraHowToChant: "Chant before beginning any spiritual study, practice, or learning. On Guru Purnima, chant 108 times as an offering to your teachers. Can be directed toward a living teacher, a teacher who has passed, or the inner Guru — the witness consciousness within.",
        mantraRepetitions: 108,
        mantraDeity: "The Guru · Brahman",
        mantraIsBeej: false,
        mantraCategory: "Guru"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Sri Ram Jai Ram",
        subtitle: "Ramacharitmanas · Valmiki Ramayana tradition",
        textEnglish: "Glorious Rama, victory to Rama, victory, victory to Rama. The Rama Taraka Mantra — the mantra that carries one across the ocean of existence.",
        source: "Ramacharitmanas",
        audioFileName: "sri_ram_jai_ram.mp3",
        mantraTransliteration: "Śrī Rāma Jaya Rāma Jaya Jaya Rāma",
        mantraSanskrit: "श्री राम जय राम जय जय राम",
        mantraMeaning: "The Rama Taraka Mantra — the mantra that helps one cross the ocean of existence. 'Sri' invokes divine grace and auspiciousness. 'Rama' means 'the one who delights' or 'the source of joy.' 'Jaya' means 'victory.' Popularized by the saint Samartha Ramdas, teacher of Chhatrapati Shivaji. Gandhi's last words were 'He Ram' — Rama on his lips at death. The mantra invokes Rama not only as an avatar of Vishnu but as the embodiment of dharma, truth, and righteous action.",
        mantraBenefits: ["Cultivates courage and righteousness", "Brings victory over inner and outer obstacles", "Develops devotion to dharma", "Peace of mind and clarity", "Traditionally said to carry one across samsara"],
        mantraHowToChant: "Can be chanted continuously throughout the day as a background mantra. 108 times on a mala, especially on Ram Navami and Saturdays. Chanting in groups (sankirtan) is especially powerful.",
        mantraRepetitions: 108,
        mantraDeity: "Rama",
        mantraIsBeej: false,
        mantraCategory: "Rama"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Shanti Shanti Shantihi",
        subtitle: "Vedic tradition — used across all Upanishads",
        textEnglish: "Om, peace, peace, peace. Chanted three times to address the three sources of suffering: from within oneself, from other beings, and from cosmic forces.",
        source: "Vedic tradition",
        audioFileName: "om_shanti.mp3",
        mantraTransliteration: "Om Śāntiḥ Śāntiḥ Śāntiḥ",
        mantraSanskrit: "ॐ शान्तिः शान्तिः शान्तिः",
        mantraMeaning: "The Shanti Mantra is a prayer for peace chanted three times for a specific reason — not repetition for emphasis, but to address the three sources of suffering (tapa-traya): Adhyatmika (suffering from within oneself — physical and mental), Adhibhautika (suffering from external causes — other beings, environment), and Adhidaivika (suffering from cosmic forces — weather, fate, divine will). By chanting peace three times, one invokes relief from all three simultaneously. This mantra seals Vedic recitation and dedicates the merit to universal peace.",
        mantraBenefits: ["Brings immediate calm to the mind", "Dissolves anxiety and agitation", "Seals spiritual practice", "Invokes universal peace", "Used to close meditation and prayer sessions"],
        mantraHowToChant: "Chanted three times — always exactly three, for the three types of suffering. Used to begin or close any spiritual practice, recitation, or meditation session. Allow a moment of silence after the third Shanti.",
        mantraRepetitions: 3,
        mantraDeity: "Universal · Brahman",
        mantraIsBeej: false,
        mantraCategory: "Peace"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Lokah Samastah Sukhino Bhavantu",
        subtitle: "Ancient Sanskrit prayer · Yoga tradition",
        textEnglish: "May all beings in all worlds be happy and free, and may the thoughts, words, and actions of my life contribute in some way to that happiness and freedom for all.",
        source: "Ancient Sanskrit prayer",
        audioFileName: "lokah_samastah.mp3",
        mantraTransliteration: "Lokāḥ Samastāḥ Sukhino Bhavantu",
        mantraSanskrit: "लोकाः समस्ताः सुखिनो भवन्तु",
        mantraMeaning: "One of the most beautiful and universal prayers in the Sanskrit tradition. 'Lokah' means worlds or realms of existence. 'Samastah' means all, every one. 'Sukhino' means happy, at ease, free from suffering. 'Bhavantu' means may they be. This is not a mantra of personal benefit but of radical compassion — a dedication of one's entire life and practice to the wellbeing of all. It dissolves the boundary between self and other, recognizing that my happiness is inseparable from the happiness of all beings everywhere.",
        mantraBenefits: ["Cultivates universal compassion", "Dissolves self-centeredness", "Brings peace through service orientation", "Traditionally chanted at the end of yoga or prayer practice", "Deepens the sense of interconnection with all life"],
        mantraHowToChant: "Chanted three times at the end of any spiritual practice, yoga class, or meditation. Can also be chanted as a standalone prayer of dedication before beginning the day. Hold the intention of genuinely wishing wellbeing to all beings as you chant.",
        mantraRepetitions: 3,
        mantraDeity: "Universal · All beings",
        mantraIsBeej: false,
        mantraCategory: "Peace"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Namo Bhagavate Vasudevaya",
        subtitle: "The liberation mantra of Vishnu",
        textEnglish: "The dvadashakshara — twelve-syllable mantra of Vishnu. Considered the Mukti mantra, the mantra of liberation. First taught by Narada to Dhruva.",
        source: "Bhagavata Purana · Vishnu Purana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Namo Bhagavate Vasudevaya",
        mantraSanskrit: "ॐ नमो भगवते वासुदेवाय",
        mantraMeaning: "I bow to the Lord who dwells in all hearts — Vasudeva, the son of Vasudeva, Krishna.",
        mantraBenefits: ["Liberation from ego", "Deepens bhakti", "Purifies the mind", "Invokes Krishna's grace", "Brings inner freedom"],
        mantraHowToChant: "Chant slowly, feeling each word as a surrender. Vasudeva means 'one who lives in all' — contemplate this as you repeat.",
        mantraRepetitions: 108,
        mantraDeity: "Vishnu / Krishna",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Vakratunda Mahakaya",
        subtitle: "Invocation of Ganesha",
        textEnglish: "The most widely chanted Ganesha shloka. Recited at the beginning of all Hindu ceremonies, prayers, and undertakings as an invocation of the remover of obstacles.",
        source: "Ganesha Purana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Vakratunda Mahakaya Suryakoti Samaprabha. Nirvighnam Kuru Me Deva Sarva Karyeshu Sarvada.",
        mantraSanskrit: "वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ। निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा॥",
        mantraMeaning: "O Ganesha with the curved trunk and mighty body, radiant as a million suns — make all my works free of obstacles, always.",
        mantraBenefits: ["Removes obstacles", "Blesses new beginnings", "Brings success", "Invokes divine wisdom", "Clears the path ahead"],
        mantraHowToChant: "Chant before starting any important work, journey, or decision. Visualize Ganesha's golden form. Three or twenty-one repetitions.",
        mantraRepetitions: 21,
        mantraDeity: "Ganesha",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Asato Ma Sadgamaya",
        subtitle: "Lead me from untruth to truth",
        textEnglish: "One of the most profound prayers in all of Vedic literature. Three movements — from untruth to truth, from darkness to light, from death to immortality. The triple Shanti at the end addresses disturbances from self, nature, and the divine.",
        source: "Brihadaranyaka Upanishad 1.3.28",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Asato ma sadgamaya. Tamaso ma jyotirgamaya. Mrityorma amritam gamaya. Om shantih shantih shantih.",
        mantraSanskrit: "असतो मा सद्गमय। तमसो मा ज्योतिर्गमय। मृत्योर्मा अमृतं गमय। ॐ शान्तिः शान्तिः शान्तिः॥",
        mantraMeaning: "Lead me from untruth to truth. Lead me from darkness to light. Lead me from death to immortality. Om peace, peace, peace.",
        mantraBenefits: ["Awakens spiritual seeking", "Dissolves illusion", "Brings clarity and light", "Invokes divine guidance", "Cultivates humility"],
        mantraHowToChant: "Chant slowly, pausing between each line. Let each line land before moving to the next. This is a prayer, not a repetition — feel it as a sincere request.",
        mantraRepetitions: 3,
        mantraDeity: "Brahman (the Absolute)",
        mantraIsBeej: false,
        mantraCategory: "Universal"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Purnamadah Purnamidam",
        subtitle: "The completeness invocation",
        textEnglish: "The invocation of the Isha Upanishad. One of the most mind-bending statements in all philosophy — that reality is infinite completeness, and nothing can be added to or subtracted from it. You are that completeness.",
        source: "Isha Upanishad · Brihadaranyaka Upanishad",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Purnamadah Purnamidam Purnat Purnamudachyate. Purnasya Purnamadaya Purnamevavashishyate. Om Shantih Shantih Shantih.",
        mantraSanskrit: "ॐ पूर्णमदः पूर्णमिदम् पूर्णात् पूर्णमुदच्यते। पूर्णस्य पूर्णमादाय पूर्णमेवावशिष्यते॥ ॐ शान्तिः शान्तिः शान्तिः॥",
        mantraMeaning: "That is whole. This is whole. From wholeness, wholeness emerges. When wholeness is taken from wholeness, wholeness remains.",
        mantraBenefits: ["Dissolves sense of lack", "Awakens non-dual awareness", "Brings profound peace", "Reminds of inherent completeness", "Opens the heart"],
        mantraHowToChant: "Chant slowly and contemplate the meaning. This is a mathematical statement about infinity — any amount taken from infinity leaves infinity. You are already whole.",
        mantraRepetitions: 3,
        mantraDeity: "Brahman (the Absolute)",
        mantraIsBeej: false,
        mantraCategory: "Universal"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Hanumate Namah",
        subtitle: "Salutation to Hanuman",
        textEnglish: "The primary mantra of Hanuman, the divine devotee of Rama. Hanuman represents the perfect union of strength and surrender. Chanted for courage, protection, and the strength to serve.",
        source: "Hanuman Chalisa tradition · Valmiki Ramayana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Hanumate Namah",
        mantraSanskrit: "ॐ हनुमते नमः",
        mantraMeaning: "I bow to Hanuman — the embodiment of strength, devotion, and selfless service.",
        mantraBenefits: ["Builds physical and mental strength", "Removes fear", "Cultivates devotion", "Gives courage in difficult times", "Wards off negative energy"],
        mantraHowToChant: "Chant on Tuesdays and Saturdays, Hanuman's days. Visualize his golden form, mountain in hand, devoted to Ram. Best chanted aloud with energy.",
        mantraRepetitions: 108,
        mantraDeity: "Hanuman",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Karpur Gauram Karunavataram",
        subtitle: "Shiva-Parvati invocation at weddings",
        textEnglish: "The most widely sung Shiva aarti shloka. Sung at the end of every Shiva puja across India. Camphor (karpur) that burns without residue is the symbol of the ego dissolving in the light of consciousness.",
        source: "Shiva tradition · used in all Shiva aartis",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Karpur Gauram Karunavataram Samsara Saram Bhujagendra Haram. Sada Vasantam Hridayaravinde Bhavam Bhavani Sahitam Namami.",
        mantraSanskrit: "कर्पूरगौरं करुणावतारं संसारसारम् भुजगेन्द्रहारम्। सदावसन्तं हृदयारविन्दे भवं भवानीसहितं नमामि॥",
        mantraMeaning: "I bow to Shiva who is as pure as camphor, an incarnation of compassion, the essence of worldly existence, garlanded with the king of serpents — who dwells always in the lotus of the heart, together with Bhavani.",
        mantraBenefits: ["Purifies the heart", "Invokes divine love", "Blesses relationships", "Brings Shiva's grace", "Awakens compassion"],
        mantraHowToChant: "Chanted while waving a camphor lamp (aarti) before Shiva. The camphor that burns completely without residue symbolizes the ego dissolving in devotion.",
        mantraRepetitions: 3,
        mantraDeity: "Shiva",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Suryaya Namah",
        subtitle: "Salutation to the Sun",
        textEnglish: "The primary salutation to Surya, the sun god. One of 12 names chanted during Surya Namaskar. The sun is understood not just as a physical body but as the outer manifestation of inner consciousness.",
        source: "Rig Veda · Surya Upanishad",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Suryaya Namah",
        mantraSanskrit: "ॐ सूर्याय नमः",
        mantraMeaning: "I bow to Surya — the sun, source of all light, life, and consciousness.",
        mantraBenefits: ["Energizes body and mind", "Improves vitality", "Brings clarity", "Honors the source of life", "Best for morning practice"],
        mantraHowToChant: "Face the rising sun. Offer water (arghya) while chanting if possible. The 12 repetitions correspond to the 12 names of Surya. Part of Surya Namaskar practice.",
        mantraRepetitions: 12,
        mantraDeity: "Surya",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Shanti Mantra — Sahana Vavatu",
        subtitle: "Peace mantra for teacher and student",
        textEnglish: "The Shanti mantra of the Taittiriya and Katha Upanishads. Traditionally chanted by guru and shishya together before study begins. A prayer for mutual protection, nourishment, and harmonious learning.",
        source: "Taittiriya Upanishad · Katha Upanishad",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Saha Navavatu. Saha Nau Bhunaktu. Saha Viryam Karavavahai. Tejasvi Navadhitamastu Ma Vidvishavahai. Om Shantih Shantih Shantih.",
        mantraSanskrit: "ॐ सह नाववतु। सह नौ भुनक्तु। सह वीर्यं करवावहै। तेजस्वि नावधीतमस्तु मा विद्विषावहै। ॐ शान्तिः शान्तिः शान्तिः॥",
        mantraMeaning: "May we be protected together. May we be nourished together. May we work together with great energy. May our study be enlightening. May we not hate each other. Om peace, peace, peace.",
        mantraBenefits: ["Harmonizes relationships", "Blesses learning", "Removes conflict", "Cultivates mutual respect", "Brings peace to shared spaces"],
        mantraHowToChant: "Traditionally chanted by teacher and student together before a lesson. Chant with anyone you learn or work with. The triple Shanti dispels obstacles from three realms.",
        mantraRepetitions: 3,
        mantraDeity: "Brahman (the Absolute)",
        mantraIsBeej: false,
        mantraCategory: "Universal"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Aditya Hridayam",
        subtitle: "Hymn to the heart of the Sun",
        textEnglish: "Taught by the sage Agastya to Rama when Rama was exhausted before his battle with Ravana. One of the most powerful solar hymns — invoking the sun not as a deity but as the force of consciousness that destroys all darkness.",
        source: "Valmiki Ramayana · Yuddha Kanda",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Aditya Hridayam Punyam Sarvashatru Vinashanam. Jayavaham Japen Nityam Akshayam Paramam Shivam.",
        mantraSanskrit: "आदित्यहृदयं पुण्यं सर्वशत्रुविनाशनम्। जयावहं जपेन्नित्यम् अक्षय्यं परमं शिवम्॥",
        mantraMeaning: "This sacred hymn to Aditya destroys all enemies, brings victory, and is eternally auspicious. One who chants it daily attains the supreme good.",
        mantraBenefits: ["Destroys inner enemies (ego, anger, fear)", "Brings victory in challenges", "Energizes the solar plexus", "Grants courage", "Auspicious for difficult times"],
        mantraHowToChant: "Taught by sage Agastya to Rama before his battle with Ravana. Chant facing the sun, three times. Best at dawn. Each verse is a complete invocation.",
        mantraRepetitions: 3,
        mantraDeity: "Surya",
        mantraIsBeej: false,
        mantraCategory: "Devotional"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Rudra Gayatri",
        subtitle: "Gayatri mantra of Shiva",
        textEnglish: "The Gayatri mantra addressed to Rudra-Shiva. Follows the same structure as the original Gayatri — a request for illumination of the intellect, here directed to the destroyer-transformer aspect of the divine.",
        source: "Yajur Veda · Shiva Purana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Tatpurushaya Vidmahe Mahadevaya Dhimahi. Tanno Rudrah Prachodayat.",
        mantraSanskrit: "ॐ तत्पुरुषाय विद्महे महादेवाय धीमहि। तन्नो रुद्रः प्रचोदयात्॥",
        mantraMeaning: "We meditate on the Supreme Being, the great God. May Rudra illuminate our intellect and inspire us.",
        mantraBenefits: ["Invokes Shiva's grace", "Purifies the mind", "Removes ego", "Deepens meditation", "Connects to the destroyer of illusion"],
        mantraHowToChant: "Same meter and structure as the original Gayatri Mantra. Chant 108 times during Shiva-related practices, on Mondays, or during Pradosh.",
        mantraRepetitions: 108,
        mantraDeity: "Shiva / Rudra",
        mantraIsBeej: false,
        mantraCategory: "Gayatri"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Vishnu Gayatri",
        subtitle: "Gayatri mantra of Vishnu",
        textEnglish: "The Gayatri mantra addressed to Vishnu-Narayana. The preserver of the universe, the one who dwells in all beings as Vasudeva. Invokes the sustaining, harmonizing aspect of the divine.",
        source: "Yajur Veda · Vishnu Purana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Narayanaya Vidmahe Vasudevaya Dhimahi. Tanno Vishnuh Prachodayat.",
        mantraSanskrit: "ॐ नारायणाय विद्महे वासुदेवाय धीमहि। तन्नो विष्णुः प्रचोदयात्॥",
        mantraMeaning: "We meditate on Narayana, we contemplate Vasudeva. May Vishnu illuminate our intellect.",
        mantraBenefits: ["Invokes Vishnu's protection", "Brings clarity and sustenance", "Deepens devotion", "Balances and preserves", "Connects to cosmic order"],
        mantraHowToChant: "Chant on Thursdays, Vishnu's day, or Ekadashi. Same Gayatri meter. 108 repetitions with mala.",
        mantraRepetitions: 108,
        mantraDeity: "Vishnu",
        mantraIsBeej: false,
        mantraCategory: "Gayatri"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Ganesha Gayatri",
        subtitle: "Gayatri mantra of Ganesha",
        textEnglish: "The Gayatri mantra of Ganesha. Ekadanta — the one-tusked one — refers to how Ganesha broke off one tusk to write the Mahabharata. The single tusk represents one-pointed focus.",
        source: "Ganapati Atharva Shirsha",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Ekadantaya Vidmahe Vakratundaya Dhimahi. Tanno Dantih Prachodayat.",
        mantraSanskrit: "ॐ एकदन्ताय विद्महे वक्रतुण्डाय धीमहि। तन्नो दन्तिः प्रचोदयात्॥",
        mantraMeaning: "We meditate on the one-tusked one, we contemplate the curved-trunk one. May Ganesha illuminate our intellect.",
        mantraBenefits: ["Removes obstacles before any endeavor", "Sharpens wisdom", "Blesses new beginnings", "Invokes Ganesha's grace", "Calms anxiety about the future"],
        mantraHowToChant: "Chant before beginning any important work, study, or journey. Wednesday is Ganesha's day. 108 repetitions for removing a specific obstacle.",
        mantraRepetitions: 108,
        mantraDeity: "Ganesha",
        mantraIsBeej: false,
        mantraCategory: "Gayatri"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Hanuman Gayatri",
        subtitle: "Gayatri mantra of Hanuman",
        textEnglish: "The Gayatri of Hanuman — son of Anjana and son of Vayu the wind god. Hanuman's strength comes not from ego but from complete surrender to Ram. This mantra invokes that combination of power and devotion.",
        source: "Hanuman tradition · Ramayana",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Anjaneyaya Vidmahe Vayuputraya Dhimahi. Tanno Hanumat Prachodayat.",
        mantraSanskrit: "ॐ आञ्जनेयाय विद्महे वायुपुत्राय धीमहि। तन्नो हनुमत् प्रचोदयात्॥",
        mantraMeaning: "We meditate on the son of Anjana, we contemplate the son of Vayu. May Hanuman illuminate our intellect.",
        mantraBenefits: ["Grants strength and courage", "Removes fear", "Deepens devotion to Ram", "Builds discipline", "Protects from negative forces"],
        mantraHowToChant: "Chant on Tuesdays and Saturdays. Hanuman represents the devotee who has mastered the mind through service. Chant with energy and conviction.",
        mantraRepetitions: 108,
        mantraDeity: "Hanuman",
        mantraIsBeej: false,
        mantraCategory: "Gayatri"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Kleem Krishnaya Namaha",
        subtitle: "Beej mantra of Krishna",
        textEnglish: "The beej mantra of Krishna. KLEEM is the kamabija — the seed of divine love and attraction. In this context it is the soul's longing for union with the divine, expressed as Krishna.",
        source: "Krishna tradition · Narada Bhakti Sutras",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Kleem Krishnaya Namaha",
        mantraSanskrit: "ॐ क्लीं कृष्णाय नमः",
        mantraMeaning: "I bow to Krishna — KLEEM is the seed of attraction, drawing the devotee toward the divine.",
        mantraBenefits: ["Deepens love and devotion", "Attracts divine grace", "Opens the heart", "Brings joy", "Connects to Krishna's playful divine love"],
        mantraHowToChant: "KLEEM is the beej of attraction — not material attraction but the pull of the soul toward the divine. Chant with a feeling of longing and love, not demand.",
        mantraRepetitions: 108,
        mantraDeity: "Krishna",
        mantraIsBeej: true,
        mantraCategory: "Beej"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Pavamana Suktam",
        subtitle: "Purification mantra from Rig Veda",
        textEnglish: "The purification mantra used before Hindu rituals. Its teaching is revolutionary — purity is not a state you achieve through effort but a quality that flows from remembering the divine. It dissolves the shame of feeling unworthy.",
        source: "Vishnu Purana · used in all Vaishnava pujas",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Apavitrah Pavitro Va Sarvavastham Gato Pi Va. Yah Smaret Pundarikaksham Sa Bahyabhyantarah Shuchih.",
        mantraSanskrit: "ॐ अपवित्रः पवित्रो वा सर्वावस्थां गतोऽपि वा। यः स्मरेत् पुण्डरीकाक्षं स बाह्याभ्यन्तरः शुचिः॥",
        mantraMeaning: "Whether pure or impure, whatever state one may be in — whoever remembers the lotus-eyed one (Vishnu) becomes pure, inside and outside.",
        mantraBenefits: ["Purifies body and mind", "Removes guilt and shame", "Invokes divine cleansing", "Used before rituals", "Reminds that purity comes from remembrance not perfection"],
        mantraHowToChant: "Sprinkle water on yourself while chanting. Used to purify a space, objects, or oneself before worship. The teaching is radical — even the impure become pure through remembrance.",
        mantraRepetitions: 3,
        mantraDeity: "Vishnu",
        mantraIsBeej: false,
        mantraCategory: "Purification"
    ),

    ScriptureItem(
        category: .mantras,
        title: "Om Aim Hreem Kleem",
        subtitle: "The triple goddess beej",
        textEnglish: "The combined beej mantra of the Tridevi — the triple goddess. AIM invokes Saraswati and wisdom, HREEM invokes Lakshmi and the power of manifestation, KLEEM invokes divine love and Kali's transforming power. Together they activate the full spectrum of Shakti.",
        source: "Tantric tradition · Devi Mahatmya",
        audioFileName: nil,
        isFavourite: false,
        mantraTransliteration: "Om Aim Hreem Kleem",
        mantraSanskrit: "ॐ ऐं ह्रीं क्लीं",
        mantraMeaning: "AIM — Saraswati, wisdom. HREEM — Mahalakshmi, manifestation. KLEEM — Kali/Krishna, divine love and transformation.",
        mantraBenefits: ["Activates all three shaktis", "Wisdom, abundance, and transformation together", "Extremely powerful for spiritual growth", "Balances masculine and feminine energies", "Opens all chakras"],
        mantraHowToChant: "Each beej activates a different energy center. AIM at the throat, HREEM at the heart, KLEEM at the navel. Chant slowly, feeling each syllable in its location.",
        mantraRepetitions: 108,
        mantraDeity: "Tridevi (Saraswati, Lakshmi, Kali)",
        mantraIsBeej: true,
        mantraCategory: "Beej"
    ),
]

// MARK: - Festival Sample Data (legacy compatibility)
extension HinduFestival {
    static let sampleData: [HinduFestival] = allFestivals
}
