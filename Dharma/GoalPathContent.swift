import Foundation

/// Static path definitions keyed by full goal title from `GoalsManager`.
enum GoalPathContent {

    static let anxietyGoalId = "Reduce anxiety about the future"
    static let disciplineGoalId = "Develop self-discipline"
    static let dailyReadingGoalId = "Build a daily scripture reading habit"

    static func levels(for goalId: String) -> [PathLevel] {
        switch goalId {
        case anxietyGoalId:
            return GoalPathContentCatalog.anxietyLevels(goalId: goalId)
        case disciplineGoalId:
            return GoalPathContentCatalog.disciplineLevels(goalId: goalId)
        case dailyReadingGoalId:
            return GoalPathContentCatalog.dailyReadingLevels(goalId: goalId)
        default:
            return defaultLevels(for: goalId)
        }
    }

    // MARK: - Default path (unknown goals)

    private static let defaultLevelNames = ["First Steps", "Deepening", "The Inner Life", "Equanimity", "The Steady One"]
    private static let defaultRewards: [(String, String, String)] = [
        ("Shishya", "The student who lit their first flame", "seal.fill"),
        ("Sadhaka", "The practitioner deepening their path", "sparkles"),
        ("Gyani", "One who begins to know", "leaf.fill"),
        ("Vairagi", "The one who has learned to release", "bolt.fill"),
        ("Yogi", "United with what is", "sun.horizon.fill")
    ]

    private static func defaultLevels(for goalId: String) -> [PathLevel] {
        let daySets: [[PathDay]] = [
            defaultLevel1Days(goalId: goalId),
            defaultLevel2Days(goalId: goalId),
            defaultLevel3Days(goalId: goalId),
            defaultLevel4Days(goalId: goalId),
            defaultLevel5Days(goalId: goalId)
        ]
        return (1...5).map { n in
            let r = defaultRewards[n - 1]
            return PathLevel(
                id: "\(goalId)-L\(n)",
                levelNumber: n,
                levelName: defaultLevelNames[n - 1],
                levelEmoji: "",
                days: daySets[n - 1],
                completedDayIndices: [],
                isUnlocked: n == 1,
                isComplete: false,
                rewardTitle: r.0,
                rewardMeaning: r.1,
                rewardEmoji: r.2
            )
        }
    }

    // MARK: - Shared default days (used by `defaultLevels` and daily-reading levels 2–5)

    private static func day(
        _ goalId: String,
        level: Int,
        slot: Int,
        ref: String,
        sanskrit: String,
        text: String,
        krishna: String,
        prompt: String
    ) -> PathDay {
        PathDay(
            id: "\(goalId)-L\(level)-D\(slot)",
            dayNumber: slot + 1,
            verseReference: ref,
            sanskrit: sanskrit,
            verseText: text,
            krishnaContext: krishna,
            reflectionPrompt: prompt
        )
    }

    /// DEFAULT LEVEL 1 — "First Steps"
    static func defaultLevel1Days(goalId: String) -> [PathDay] {
        [
            day(goalId, level: 1, slot: 0, ref: "Bhagavad Gita 2.47",
                sanskrit: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन",
                text: "You have a right to perform your duties, but you are not entitled to the fruits of your actions.",
                krishna: "You showed up today. That is the whole practice — not the result, not the reward. Just the showing up.",
                prompt: "What does showing up look like for you today, without any expectation of outcome?"),
            day(goalId, level: 1, slot: 1, ref: "Bhagavad Gita 6.5",
                sanskrit: "उद्धरेदात्मनात्मानं नात्मानमवसादयेत्",
                text: "Elevate yourself through your own mind — do not degrade yourself. You are your own friend, and your own enemy.",
                krishna: "The mind is the only thing that can truly free you or trap you. Today, notice which voice is louder — the one that lifts, or the one that limits.",
                prompt: "When does your mind feel like a friend? When does it feel like an enemy?"),
            day(goalId, level: 1, slot: 2, ref: "Chandogya Upanishad 6.8.7",
                sanskrit: "तत् त्वम् असि",
                text: "That thou art — you are not separate from the source of all things.",
                krishna: "Whatever you are seeking — peace, clarity, strength — it is not outside you. It has never been outside you.",
                prompt: "What would change if you truly believed the source of what you need is already within you?"),
            day(goalId, level: 1, slot: 3, ref: "Bhagavad Gita 2.20",
                sanskrit: "न जायते म्रियते वा कदाचित्",
                text: "The soul is never born nor does it die. It is eternal, ancient, unslain when the body is slain.",
                krishna: "What you are afraid of losing cannot touch what you actually are. The self that watches your fear is already free.",
                prompt: "What are you most afraid of losing right now? What part of you cannot be lost?"),
            day(goalId, level: 1, slot: 4, ref: "Rig Veda 1.89.1",
                sanskrit: "आ नो भद्राः क्रतवो यन्तु विश्वतः",
                text: "Let noble thoughts come to us from every direction.",
                krishna: "Wisdom does not care where it comes from. Stay open. The teaching you need most often arrives from the direction you least expect.",
                prompt: "Where has unexpected wisdom or clarity come to you recently?"),
            day(goalId, level: 1, slot: 5, ref: "Bhagavad Gita 9.22",
                sanskrit: "अनन्याश्चिन्तयन्तो मां ये जनाः पर्युपासते",
                text: "For those who worship me with devotion, I carry what they lack and preserve what they have.",
                krishna: "You do not have to carry this alone. The practice is not self-improvement through willpower — it is surrender through trust.",
                prompt: "What are you carrying right now that you could put down?"),
            day(goalId, level: 1, slot: 6, ref: "Bhagavad Gita 18.66",
                sanskrit: "सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज",
                text: "Abandon all varieties of dharma and simply surrender to me. I shall deliver you from all fear — do not grieve.",
                krishna: "This is Krishna's final word. Not 'try harder.' Not 'figure it out.' Simply — come. The path ends where surrender begins.",
                prompt: "What would it mean to truly surrender one thing today — not give up, but hand it over?")
        ]
    }

    /// DEFAULT LEVEL 2 — "Deepening" — Bhagavad Gita Chapter 3 (karma yoga)
    static func defaultLevel2Days(goalId: String) -> [PathDay] {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 3.8", "नियतं कुरु कर्म त्वं", "Perform your prescribed duty, for action is superior to inaction; even maintaining your body depends on action.",
             "Sustained practice is not a single heroic day — it is returning to duty when no one applauds. Krishna ties action to the health of your whole life.",
             "What duty will you keep steady across ordinary days, not only inspired ones?"),
            ("Bhagavad Gita 3.16", "एवं प्रवर्तितं चक्रं", "Thus the wheel of sacrifice revolves; one who does not follow this cycle lives in vain, led by selfish desire.",
             "When you give and participate, the wheel turns; when you only take, life narrows. Karma yoga is joining the larger turning of the world.",
             "Where did you participate generously today, not only consume?"),
            ("Bhagavad Gita 3.19", "तस्मात् सर्वेषु कालेषु", "Therefore, without attachment, always perform action that is duty — for by doing action without attachment, one attains the highest.",
             "Detachment here is not coldness; it is steadiness. The same hand returns to work whether yesterday succeeded or failed.",
             "What will you do again tomorrow without bargaining for how it felt today?"),
            ("Bhagavad Gita 3.21", "यद्यदाचरति श्रेष्ठः", "Whatever the best do, others follow; whatever standard they set, the world follows that.",
             "Your discipline quietly teaches. Sustained practice over time shapes more than your mood — it shapes what others dare to try.",
             "Who might be learning from how you show up?"),
            ("Bhagavad Gita 3.27", "प्रकृतेः क्रियमाणानि", "While the modes of nature perform all actions, one whose self is confused by ego thinks: 'I am the doer.'",
             "Notice the difference between effort and the story of being solely responsible. Humility saves the practitioner from burnout.",
             "Where did effort feel lighter when you released the need to control every outcome?"),
            ("Bhagavad Gita 3.30", "मयि सर्वाणि कर्माणि", "Renounce all actions to me — with mind fixed on the Self, free from hope and selfishness, fight!",
             "Offering action upward unburdens the heart. The practice continues — but you are not carrying it alone.",
             "What will you place in that offering today?"),
            ("Bhagavad Gita 3.35", "श्रेयान् स्वधर्मो विगुणः", "Better one's own duty, though imperfect, than another's duty well performed; doing duty prescribed by nature, one incurs no stain.",
             "Your path will not look like anyone else's timeline. Staying with your own dharma is the long work Krishna blesses.",
             "Where are you tempted to copy another's path instead of honoring yours?")
        ]
        return verses.enumerated().map { i, v in
            day(goalId, level: 2, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
    }

    /// DEFAULT LEVEL 3 — "The Inner Life" — Upanishads
    static func defaultLevel3Days(goalId: String) -> [PathDay] {
        let verses: [(String, String, String, String, String)] = [
            ("Mandukya Upanishad 1.1", "हरिः ॐ", "Om — this syllable is all this. Its explanation follows.",
             "The shortest teaching holds the whole: the waking, dreaming, and deep sleep worlds resolve in what knows them.",
             "What did you notice today when you simply listened inward?"),
            ("Mandukya Upanishad 2", "सर्वं ह्येतद् ब्रह्म", "All this is Brahman. From it the Self is born as name and form — the inner life is one with what the senses report.",
             "The inner life is not adding noise but seeing through divisions to one awareness.",
             "Where did a boundary soften when you rested as awareness?"),
            ("Kena Upanishad 1.3", "यस्यामतं तस्य मतं", "That which the mind cannot think, but by which the mind thinks — know that alone is Brahman.",
             "The source of thought is not another thought. Rest there.",
             "Can you sense the witness beneath today's mental weather?"),
            ("Isha Upanishad 1", "ईशा वास्यम्", "The Lord is enwrapped in all that moves in this world. Renounce and enjoy — do not covet.",
             "The inner life includes the world — not escape, but clear seeing.",
             "What could you enjoy without grasping?"),
            ("Mundaka Upanishad 3.1.6", "सत्यमेव जयते", "Truth alone triumphs — not falsehood. By truth the path is laid out, divine — by which the seers ascend.",
             "Truth is not a slogan; it is the axis the inner life turns on.",
             "What small truth did you refuse to bend today?"),
            ("Taittiriya Upanishad 2.1", "सत्यं ज्ञानम् अनन्तं ब्रह्म", "Brahman is truth, knowledge, infinite.",
             "The infinite is not elsewhere — it is what knowing rests in.",
             "When did knowledge feel like opening rather than accumulating?"),
            ("Chandogya Upanishad 3.14.1", "सर्वं खल्विदं ब्रह्म", "All this, indeed, is Brahman. From it calm mind, from it breath and name — all rise.",
             "When the inner life matures, the ordinary world glows with one life.",
             "Where did you glimpse one life in many forms?")
        ]
        return verses.enumerated().map { i, v in
            day(goalId, level: 3, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
    }

    /// DEFAULT LEVEL 4 — "Equanimity"
    static func defaultLevel4Days(goalId: String) -> [PathDay] {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 2.14", "मात्रास्पर्शास्तु कौन्तेय", "The contacts of senses with their objects, O son of Kunti, give rise to cold and heat, pleasure and pain — they come and go; endure them.",
             "Equanimity begins with weathering pairs of opposites without being owned by either.",
             "Which pair — praise and blame, gain and loss — tested you today?"),
            ("Bhagavad Gita 2.48", "योगस्थः कुरु कर्माणि", "Established in yoga, perform actions, abandoning attachment — remain the same in success and failure.",
             "Steadiness is not numbness; it is evenness of heart while you still care.",
             "Where did you stay kind to yourself in both success and setback?"),
            ("Bhagavad Gita 2.56", "दुःखेष्वनुद्विग्नमनाः", "Unmoved by sorrow, free from craving, passion, fear, and anger — such a sage is called steady in wisdom.",
             "Feelings may move through you; equanimity means they do not command you.",
             "What feeling visited without taking the throne?"),
            ("Bhagavad Gita 4.18", "कर्मण्यकर्म यः पश्येद्", "One who sees inaction in action, and action in inaction — he is wise among people.",
             "Seeing clearly transforms how effort lands — less strain, more alignment.",
             "Where did right action feel quiet instead of frantic?"),
            ("Bhagavad Gita 5.18", "विद्याविनयसम्पन्ने", "The wise see the same in a learned Brahmin, a cow, an elephant, a dog, and an outcaste.",
             "Equanimity widens the circle of respect — the same light in different forms.",
             "Who did you meet without the usual labels?"),
            ("Bhagavad Gita 5.19", "इहैव तैर्जितः सर्गो", "Even here on earth the world is conquered by those whose mind rests in equality; Brahman is stainless and the same to all.",
             "Peace is possible before circumstances perfect — because it is trained inwardly.",
             "Where did equality feel like freedom today?"),
            ("Bhagavad Gita 6.29", "सर्वभूतस्थमात्मानं", "One who sees the Self in all beings and all beings in the Self — through that vision, is not lost.",
             "When selfhood expands, anxiety loses its monopoly.",
             "When did you see yourself in another's struggle?")
        ]
        return verses.enumerated().map { i, v in
            day(goalId, level: 4, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
    }

    /// DEFAULT LEVEL 5 — "The Steady One" — Sthitaprajna (BG 2.54–2.72)
    static func defaultLevel5Days(goalId: String) -> [PathDay] {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 2.54", "स्थितप्रज्ञस्य का भाषा", "What is the mark of a person of steady wisdom, Krishna, who is settled in samadhi?",
             "The journey narrows to one question: what does steadiness look like in living speech and breath?",
             "What first sign of steadiness do you trust in yourself?"),
            ("Bhagavad Gita 2.55", "प्रजहाति यदा कामान्", "When one gives up all desires that enter the mind, Arjuna, and is content in the Self alone — that one is called steady.",
             "Contentment in the Self is not smugness; it is homecoming.",
             "What desire loosened its grip when you rested in awareness?"),
            ("Bhagavad Gita 2.56", "दुःखेष्वनुद्विग्नमनाः", "Unmoved by sorrow, free from craving, passion, fear, and anger — such a sage is called a muni of steady wisdom.",
             "The steady one is not unfeeling — they are unthrown.",
             "What fear shrank when you stayed present?"),
            ("Bhagavad Gita 2.57", "यः सर्वत्रानभिस्नेहः", "Whoever is unattached everywhere — neither rejoicing on meeting the good nor hating the evil — has steady wisdom.",
             "Equanimity is not loving less — it is clinging less.",
             "Where did you receive good news without clutching it?"),
            ("Bhagavad Gita 2.64", "रागद्वेषवियुक्तैस्तु", "But one who controls the senses by the mind, and is free from attachment and aversion — such a one attains serenity.",
             "Serenity is trained — sense by sense, day by day.",
             "Which sense asked for your patience today?"),
            ("Bhagavad Gita 2.65", "प्रसादे सर्वदुःखानाम्", "In that serenity all sorrows end; the intellect of the serene soon becomes steady.",
             "When clarity returns, the heart remembers how to rest.",
             "What sorrow felt smaller in a moment of clarity?"),
            ("Bhagavad Gita 2.72", "एषा ब्राह्मी स्थितिः", "This is the state of Brahman, O son of Pritha — attaining it, one is not deluded; abiding in it, one attains peace at the end.",
             "The steady one's path ends in peace — not escape from life, but peace within it.",
             "What peace did you touch that did not depend on everything going right?")
        ]
        return verses.enumerated().map { i, v in
            day(goalId, level: 5, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
    }
}
