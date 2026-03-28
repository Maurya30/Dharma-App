import Foundation

/// Full path content for the three featured goals.
enum GoalPathContentCatalog {

    // MARK: - Helpers

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

    private static func level(
        _ goalId: String,
        n: Int,
        name: String,
        days: [PathDay],
        reward: (String, String, String),
        unlockFirst: Bool = false
    ) -> PathLevel {
        PathLevel(
            id: "\(goalId)-L\(n)",
            levelNumber: n,
            levelName: name,
            levelEmoji: "",
            days: days,
            completedDayIndices: [],
            isUnlocked: n == 1,
            isComplete: false,
            rewardTitle: reward.0,
            rewardMeaning: reward.1,
            rewardEmoji: reward.2
        )
    }

    // MARK: - Less anxiety

    static func anxietyLevels(goalId: String) -> [PathLevel] {
        let l1Days: [PathDay] = [
            day(goalId, level: 1, slot: 0, ref: "Bhagavad Gita 2.14",
                sanskrit: "मात्रास्पर्शास्तु कौन्तेय शीतोष्णसुखदुःखदाः",
                text: "Pleasure and pain come and go like seasons. They are not you — endure them, Arjuna.",
                krishna: "You have not failed by feeling this. Even Arjuna trembled. The feeling is a wave. You are not the wave — you are the ocean it moves through.",
                prompt: "What feeling have you been fighting instead of letting pass through?"),
            day(goalId, level: 1, slot: 1, ref: "Bhagavad Gita 6.5",
                sanskrit: "उद्धरेदात्मनात्मानं नात्मानमवसादयेत्",
                text: "Elevate yourself through your own mind — do not degrade yourself. The mind is both friend and enemy.",
                krishna: "Your mind is the only thing that can truly free you or truly trap you. Today, notice which voice you are listening to.",
                prompt: "When does your mind feel like a friend? When does it feel like an enemy?"),
            day(goalId, level: 1, slot: 2, ref: "Chandogya Upanishad 6.8.7",
                sanskrit: "तत् त्वम् असि",
                text: "That thou art — you are not separate from the source of all things.",
                krishna: "The anxiety you feel is a case of mistaken identity. You think you are only this body, this situation, this worry. You are not. You are that.",
                prompt: "What would change if you remembered you were bigger than this feeling?"),
            day(goalId, level: 1, slot: 3, ref: "Bhagavad Gita 2.20",
                sanskrit: "न जायते म्रियते वा कदाचित्",
                text: "The soul is never born nor does it die. It is eternal, ancient, unslain when the body is slain.",
                krishna: "What you are afraid of losing — job, relationship, certainty — none of it touches what you actually are. The self that watches your fear is unafraid.",
                prompt: "What are you most afraid of losing right now?"),
            day(goalId, level: 1, slot: 4, ref: "Bhagavad Gita 12.15",
                sanskrit: "यस्मान्नोद्विजते लोको",
                text: "One who does not disturb the world, and whom the world cannot disturb — who is free from joy, envy, fear, and anxiety — is very dear to me.",
                krishna: "This is not indifference. It is the deep steadiness that comes after you have sat with the wave long enough to know you will not drown.",
                prompt: "What would 'undisturbed' actually look like in your life?"),
            day(goalId, level: 1, slot: 5, ref: "Kena Upanishad 1.3",
                sanskrit: "यन्मनसा न मनुते",
                text: "That which the mind cannot think, but by which the mind thinks — know that alone as Brahman.",
                krishna: "Behind every anxious thought is something that watches the thought. Find that. That is you.",
                prompt: "Can you notice the part of you that is watching your thoughts right now?"),
            day(goalId, level: 1, slot: 6, ref: "Bhagavad Gita 18.66",
                sanskrit: "सर्वधर्मान्परित्यज्य",
                text: "Abandon all varieties of dharma and simply surrender to me. I shall deliver you from all fear — do not grieve.",
                krishna: "This is Krishna's final promise. Not 'figure it out.' Not 'try harder.' Just — come. The anxiety ends not when you solve it, but when you stop carrying it alone.",
                prompt: "What would it feel like to put this down, just for today?")
        ]

        let l1 = level(goalId, n: 1, name: "The Wave", days: l1Days,
                       reward: ("Shishya", "The student who lit their first flame", "seal.fill"))

        let l2 = anxietyLevel2(goalId: goalId)
        let l3 = anxietyLevel3(goalId: goalId)
        let l4 = anxietyLevel4(goalId: goalId)
        let l5 = anxietyLevel5(goalId: goalId)

        return [l1, l2, l3, l4, l5]
    }

    private static func anxietyLevel2(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 6.10", "योगी युञ्जीत सततम्", "Let the yogi constantly strive to abide in solitude, controlling mind and body, alone, with mind and thoughts restrained.",
             "Sit quietly and watch the mind without judging what arises. The witness is already there.", "What did you notice when you watched without fixing?"),
            ("Bhagavad Gita 6.11", "शुचौ देशे", "In a clean place, neither too high nor too low, firm cloth, seat, and mind — this is the seat of practice.",
             "Create a small, steady place for the practice of seeing. The witness grows in consistency.", "Where is your simplest place of stillness?"),
            ("Bhagavad Gita 6.12", "तत्रैकाग्रं मनः कृत्वा", "There, fixing the mind on one point, let him practice yoga for the purification of the self.",
             "One-pointed seeing is not force — it is gentle return, again and again.", "What did you return to today?"),
            ("Bhagavad Gita 6.13", "ततः शान्तिम्", "Then, holding body, head, and neck aligned, still, gaze at the tip of the nose — not looking outward.",
             "The witness is not outward drama. It is inward steadiness.", "What happened when you softened the gaze?"),
            ("Bhagavad Gita 6.14", "प्रशान्तात्मा", "Serene, fearless, firm in vow, the yogi meditates on me — that yogi is dear to me.",
             "Fearlessness is not the absence of fear — it is not letting fear own the witness.", "What fear loosened when you stayed present?"),
            ("Bhagavad Gita 6.15", "युञ्जन्नेवं सदा योगी", "Thus always striving, the yogi of restrained mind attains peace — the supreme abode in me.",
             "Peace is not a prize — it is the nature of the one who watches with love.", "Where did you touch peace today?"),
            ("Bhagavad Gita 6.16", "नात्यश्नतस्तु योगो", "Yoga is not for one who eats too much or too little — neither for one who sleeps too much nor too little.",
             "Balance in body supports balance in the witness. Gently, not harshly.", "What one habit supported your steadiness today?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 2, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 2, name: "The Witness", days: days,
                     reward: ("Sadhaka", "The practitioner deepening their path", "sparkles"))
    }

    private static func anxietyLevel3(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Katha Upanishad 1.2.20", "अणोरणीयान्", "Finer than the finest, greater than the greatest — the Self dwells in the heart of all beings.",
             "Silence is not empty — it is where the Self shines without noise.", "When did silence feel more honest than words?"),
            ("Mundaka Upanishad 2.2.3", "यथोदकं शुद्धे", "As pure water poured into pure water becomes one — so the knower of the Self becomes one with Brahman.",
             "Rest in the simple knowing that you are not separate from the source.", "What dropped away when you felt less separate?"),
            ("Prashna Upanishad 4.8", "स एव संवृत्सु", "That in whom all beings merge, as birds go to the tree — know that as Brahman.",
             "Anxiety seeks a perch. The Self is the tree that never falls.", "What are you resting in tonight?"),
            ("Taittiriya Upanishad 2.1", "सत्यं ज्ञानं अनन्तं ब्रह्म", "Truth, knowledge, infinite — that is Brahman.",
             "The infinite does not hurry. It holds your worry without gripping back.", "What feels infinite underneath your worry?"),
            ("Isha Upanishad 1", "ईशा वास्यम्", "The Lord is enwrapped in all that moves — enjoy by renunciation.",
             "Hold life lightly — not as threat, but as gift.", "What can you hold more lightly today?"),
            ("Isha Upanishad 6", "यस्तु सर्वाणि भूतानि", "He who sees all beings in the Self — how can sorrow or delusion touch him?",
             "When the witness widens, sorrow shrinks.", "Who did you see differently when you widened?"),
            ("Mundaka Upanishad 2.2.11", "अङ्गुष्ठमात्रः", "The Self, the size of a thumb, dwells in the heart — always know that with clarity.",
             "The smallest space is enough — the Self is not a volume.", "What small space felt enough today?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 3, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 3, name: "Stillness", days: days,
                     reward: ("Gyani", "One who begins to know", "leaf.fill"))
    }

    private static func anxietyLevel4(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 9.22", "अनन्याश्चिन्तयन्तो मां", "To those who think of me alone, I carry what they lack and preserve what they have.",
             "Devotion is not performance — it is turning toward what can hold you.", "What did you trust today that was larger than fear?"),
            ("Bhagavad Gita 9.26", "पत्रं पुष्पं फलं तोयं", "If one offers me with devotion a leaf, a flower, fruit, or water — I accept that offering of love.",
             "Small offerings count. The heart is the measure.", "What small offering did you make today?"),
            ("Bhagavad Gita 9.27", "यत्करोषि यदश्नासि", "Whatever you do, whatever you eat, whatever you offer — dedicate it to me.",
             "Surrender is not defeat — it is partnership with the sacred.", "What did you do as an offering instead of a worry?"),
            ("Bhagavad Gita 9.29", "समोऽहं सर्वभूतेषु", "I am the same to all beings — none are hated, none are dear — but those who worship me with devotion dwell in me.",
             "You are not graded on anxiety — you are invited into closeness.", "Where did you feel welcomed today?"),
            ("Bhagavad Gita 9.31", "क्षिप्रं भवति धर्मात्मा", "Quickly the righteous becomes secure — they never perish.",
             "Trust in the slow work of becoming — not the fast fix of control.", "What slow trust is growing in you?"),
            ("Bhagavad Gita 9.34", "मन्मना भव मद्भक्तः", "Fix your mind on me, be devoted to me — you shall come to me without doubt.",
             "The path home is simple: return, again and again.", "Where did you return today?"),
            ("Bhagavad Gita 9.18", "गतिर्भर्ता प्रभुः", "I am the goal, the sustainer, the master, the witness, the abode, the refuge, the friend.",
             "When anxiety names itself as the whole story, remember the Friend who holds the whole.", "Who is friend to your anxious mind today?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 4, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 4, name: "Surrender", days: days,
                     reward: ("Vairagi", "The one who has learned to release", "bolt.fill"))
    }

    private static func anxietyLevel5(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 2.48", "योगस्थः कुरु कर्माणि", "Established in yoga, perform actions — abandon attachment — remain the same in success and failure.",
             "Equanimity is the steadied heart — not the flat heart.", "Where did you stay steady without going numb?"),
            ("Bhagavad Gita 2.49", "बुद्धियुक्तो जहातीह", "With the mind harmonized by yoga, one abandons here both good and evil — therefore strive for yoga.",
             "Yoga is skill in action — not the absence of feeling.", "What skill did you practice under pressure?"),
            ("Bhagavad Gita 2.53", "श्रुतिविप्रतिपन्ना ते", "When your mind, once confused by conflicting words, stands firm in samadhi — then you will attain yoga.",
             "Confusion is not failure — it is the doorway to deeper seeing.", "What confusion are you willing to sit with?"),
            ("Bhagavad Gita 2.54", "स्थितप्रज्ञस्य का भाषा", "What is the mark of a person of steady wisdom?",
             "The steadied one is not thrown by praise or blame — the witness holds the center.", "What praise or blame lost its grip today?"),
            ("Bhagavad Gita 2.55", "प्रजहाति यदा कामान्", "When one abandons all desires of the mind, content in the Self — that one is called steady.",
             "Contentment is not the end of longing — it is the end of being owned by longing.", "What desire loosened?"),
            ("Bhagavad Gita 2.56", "दुःखेष्वनुद्विग्नमनाः", "Unmoved by sorrow, free from craving, passion, fear, and anger — such a sage is called steady.",
             "Anxiety may visit — but it need not own the house.", "What did you refuse to hand the keys to?"),
            ("Bhagavad Gita 2.57", "यः सर्वत्रानभिस्नेहः", "Whoever is unattached everywhere — neither rejoicing nor hating — has steady wisdom.",
             "Freedom is not coldness — it is warmth without clinging.", "Where did you love without clutching?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 5, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 5, name: "Equanimity", days: days,
                     reward: ("Yogi", "United with what is", "sun.horizon.fill"))
    }

    // MARK: - Self-discipline

    static func disciplineLevels(goalId: String) -> [PathLevel] {
        let l1 = disciplineLevel1(goalId: goalId)
        let l2 = disciplineLevel2(goalId: goalId)
        let l3 = disciplineLevel3(goalId: goalId)
        let l4 = disciplineLevel4(goalId: goalId)
        let l5 = disciplineLevel5(goalId: goalId)
        return [l1, l2, l3, l4, l5]
    }

    private static func disciplineLevel1(goalId: String) -> PathLevel {
        let days: [PathDay] = [
            day(goalId, level: 1, slot: 0, ref: "Bhagavad Gita 2.47",
                sanskrit: "कर्मण्येवाधिकारस्ते",
                text: "You have a right to perform your duties but not to the fruits of your actions.",
                krishna: "Discipline is not punishment. It is the decision to show up regardless of whether today feels worthy of showing up.",
                prompt: "What is one thing you keep starting and stopping?"),
            day(goalId, level: 1, slot: 1, ref: "Bhagavad Gita 3.8",
                sanskrit: "नियतं कुरु कर्म त्वं",
                text: "Perform your prescribed duty — action is superior to inaction.",
                krishna: "Action shapes your inner world. Choose one small duty and keep it steady.",
                prompt: "What duty will you keep even when no one is watching?"),
            day(goalId, level: 1, slot: 2, ref: "Bhagavad Gita 3.19",
                sanskrit: "तस्मात् सर्वेषु कालेषु",
                text: "Therefore, without attachment, always perform action that is duty — for by doing so, one attains the highest.",
                krishna: "Attachment to outcomes steals energy. Consistency is the quiet victory.",
                prompt: "Where can you release attachment for the sake of steadiness?"),
            day(goalId, level: 1, slot: 3, ref: "Bhagavad Gita 6.16",
                sanskrit: "नात्यश्नतस्तु योगो",
                text: "Yoga is not for one who eats too much or too little — nor sleeps too much or too little.",
                krishna: "Discipline is balance — not heroic extremes that collapse tomorrow.",
                prompt: "What one boundary would help your body support your practice?"),
            day(goalId, level: 1, slot: 4, ref: "Bhagavad Gita 6.17",
                sanskrit: "युक्ताहारविहारस्य",
                text: "For one whose diet and recreation are balanced, whose effort is balanced — yoga becomes the destroyer of sorrow.",
                krishna: "Small steady rhythms train the mind more than rare bursts of zeal.",
                prompt: "What rhythm could you repeat tomorrow without drama?"),
            day(goalId, level: 1, slot: 5, ref: "Bhagavad Gita 17.14",
                sanskrit: "देवद्विजगुरुप्राज्ञपूजनं",
                text: "Worship of gods, teachers, and the wise — purity, uprightness, celibacy, nonviolence — this is austerity of the body.",
                krishna: "Discipline is reverence expressed — in posture, speech, and daily care.",
                prompt: "Who or what do you practice reverence toward today?"),
            day(goalId, level: 1, slot: 6, ref: "Bhagavad Gita 18.23",
                sanskrit: "नियतं सङ्गरहितम्",
                text: "Action that is prescribed, done without attachment, without desire for fruit — that is sattvic — lucid.",
                krishna: "Clear action is the fruit of discipline — not applause, but alignment.",
                prompt: "What clear action will you choose without bargaining for the outcome?")
        ]
        return level(goalId, n: 1, name: "The Vow", days: days,
                       reward: ("Shishya", "The student who lit their first flame", "seal.fill"))
    }

    private static func disciplineLevel2(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 3.9", "यज्ञार्थात् कर्मणो", "Work done as sacrifice frees you — but work done for selfish ends binds.",
             "Offer today’s action as practice — not proof.", "What will you offer as sacrifice today?"),
            ("Bhagavad Gita 3.19", "तस्मात् सर्वेषु कालेषु", "Therefore always do duty without attachment — thus attaining the highest.",
             "Consistency beats intensity when the heart is right.", "What will you repeat tomorrow?"),
            ("Bhagavad Gita 3.30", "मयि सर्वाणि कर्माणि", "Renounce all actions to me — I will release you from sin.",
             "Discipline is lighter when you are not alone in carrying it.", "What can you surrender upward today?"),
            ("Bhagavad Gita 3.35", "श्रेयान् स्वधर्मो विगुणः", "Better one's own duty, though imperfect, than another's duty well done.",
             "Your path is yours — comparison is a thief of discipline.", "Where are you comparing instead of committing?"),
            ("Bhagavad Gita 3.43", "एवं ज्ञात्वा", "Thus knowing the mind, conquer the enemy — desire, difficult though it be.",
             "Desire is not defeated by shame — it is trained by steady attention.", "What desire did you meet with steadiness?"),
            ("Bhagavad Gita 3.8", "नियतं कुरु कर्म त्वं", "Perform your prescribed duty — for inaction is not the way.",
             "Inaction is also a choice — choose movement.", "What duty will you not postpone?"),
            ("Bhagavad Gita 3.20", "कर्मणैव हि संसिद्धिम्", "By action alone did kings attain perfection — seek not inaction.",
             "Greatness is not stillness only — it is right action sustained.", "What greatness are you building in small steps?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 2, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 2, name: "The Practice", days: days,
                     reward: ("Sadhaka", "The practitioner deepening their path", "sparkles"))
    }

    private static func disciplineLevel3(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Rig Veda 1.1.1", "अग्निमीळे पुरोहितं", "I praise Agni, the priest, the god of the ritual.",
             "Daily ritual begins with a spark — a small flame of intention.", "What small flame will you tend today?"),
            ("Rig Veda 1.89.1", "आ नो भद्राः क्रतवो", "Let noble thoughts come to us from every direction.",
             "Discipline widens the mind to receive good counsel.", "What noble thought came to you today?"),
            ("Rig Veda 10.191.2", "सं गच्छध्वं सं वदध्वं", "Walk together, speak together — let your minds be of one accord.",
             "Practice is not only private — harmony strengthens the vow.", "Where did harmony strengthen your discipline?"),
            ("Rig Veda 1.14.1", "इमं स्तोमं अरंकृतम्", "This praise, well fashioned — I offer.",
             "Offer your day as a crafted offering — not perfect, but honest.", "What did you offer honestly today?"),
            ("Rig Veda 1.50.1", "उद् उद्यत्", "Arise, rise up — the sun climbs the sky.",
             "The dawn is a daily invitation — meet it.", "What did you rise to today?"),
            ("Rig Veda 2.1.1", "यज्ञेन वाचः", "By sacrifice the voice was born — by sacrifice the radiant ones.",
             "Your words are shaped by what you practice.", "How did your practice shape your words today?"),
            ("Rig Veda 5.82.1", "प्र वाता वातु", "May the winds blow — may the dawns light the path.",
             "Let the path be lit — keep walking.", "What step forward will you not skip tomorrow?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 3, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 3, name: "The Habit", days: days,
                     reward: ("Gyani", "One who begins to know", "leaf.fill"))
    }

    private static func disciplineLevel4(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 17.14", "देवद्विजगुरुप्राज्ञपूजनं", "Worship of the gods, teachers, and wise — purity, uprightness — austerity of body.",
             "Tapas begins in the body — not as cruelty, but as care.", "What body practice honored your vow today?"),
            ("Bhagavad Gita 17.15", "अनुद्वेगकरं वाक्यं", "Speech that causes no hurt, truthful, pleasant — austerity of speech.",
             "Discipline of speech is discipline of mind.", "Where did your speech serve peace?"),
            ("Bhagavad Gita 17.16", "मनः प्रसादः", "Serenity of mind, silence, self-control, purity of heart — austerity of mind.",
             "Inner heat is not rage — it is clarity.", "What mental habit did you cool?"),
            ("Bhagavad Gita 17.17", "श्रद्धया परया", "Tapa performed with faith — without desire for fruit — is sattvic.",
             "Faith without bargaining — that is the heart of tapas.", "What did you do without needing a receipt?"),
            ("Bhagavad Gita 17.18", "सत्कारमानपूजार्थं", "Tapas done for honor, respect, or show — know that to be rajasic — unstable.",
             "Notice when discipline becomes performance.", "Where was your practice honest?"),
            ("Bhagavad Gita 17.19", "मूढग्राहेणात्मनो", "Tapas done with self-torture, or to harm another — that is tamasic.",
             "Discipline is not self-harm — it is self-honoring.", "Where did you choose kindness over cruelty?"),
            ("Bhagavad Gita 17.5", "अश्रद्धया हुतं", "Sacrifice without faith — what is the use?",
             "Tapas without faith is empty — return to why you began.", "What is your faith beneath the effort?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 4, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 4, name: "The Fire", days: days,
                     reward: ("Vairagi", "The one who has learned to release", "bolt.fill"))
    }

    private static func disciplineLevel5(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 18.42", "शमो दमस्तपः", "Serenity, self-control, austerity, purity — these are the qualities of Brahmanas.",
             "The perfected person is not loud — they are aligned.", "Where did you choose alignment over noise?"),
            ("Bhagavad Gita 18.49", "असक्तबुद्धिः सर्वत्र", "With unattached intellect everywhere — such a one attains the highest.",
             "Release the outcome — keep the vow.", "What outcome did you release today?"),
            ("Bhagavad Gita 18.50", "सिद्धिं प्राप्तो यथा", "Learn how one who has attained perfection acts — thus in brief is the essence of karma.",
             "The perfected person acts — but is not bound.", "What action did you carry without being bound?"),
            ("Bhagavad Gita 18.58", "मच्चित्तः सर्वदुर्गाणि", "With mind fixed on me — you shall cross all difficulties by my grace.",
             "Grace meets discipline — not instead of it.", "Where did grace meet your effort?"),
            ("Bhagavad Gita 18.63", "इति ते ज्ञानम्", "Thus I have declared this most secret wisdom — reflect on it fully, then act as you choose.",
             "Freedom is yours — choose the vow again.", "What will you choose freely tomorrow?"),
            ("Bhagavad Gita 18.65", "मन्मना भव मद्भक्तः", "Fix your mind on me — be devoted to me — worship me — you shall come to me.",
             "The journey ends in union — not in exhaustion.", "Where did devotion soften your effort?"),
            ("Bhagavad Gita 18.78", "यत्र योगेश्वरः कृष्णो", "Where Krishna is, there is victory — so I believe.",
             "Victory is steadiness of heart — not the absence of struggle.", "Where did you feel victory today?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 5, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 5, name: "The Master", days: days,
                     reward: ("Yogi", "United with what is", "sun.horizon.fill"))
    }

    // MARK: - Daily reading

    static func dailyReadingLevels(goalId: String) -> [PathLevel] {
        let l1 = dailyReadingLevel1(goalId: goalId)
        let l2 = dailyReadingLevel2(goalId: goalId)
        let l3 = dailyReadingLevel3(goalId: goalId)
        let l4 = dailyReadingLevel4(goalId: goalId)
        let l5 = dailyReadingLevel5(goalId: goalId)
        return [l1, l2, l3, l4, l5]
    }

    private static func dailyReadingLevel1(goalId: String) -> PathLevel {
        let verses: [(String, String, String, String, String)] = [
            ("Bhagavad Gita 2.47", "कर्मण्येवाधिकारस्ते", "You have a right to act, not to the fruits of action.",
             "Begin with the heart of karma yoga — gentle, steady reading.", "What will you read without rushing for results?"),
            ("Isha Upanishad 1", "ईशा वास्यम्", "All this — whatever moves — is enveloped by the Lord.",
             "Short Upanishads teach vastness in few words.", "What vastness did you feel in few words?"),
            ("Kena Upanishad 1.1", "केनेषितं पतति प्रेषितं मनः", "By whom is the mind directed? Who is the first among the gods?",
             "Questions open the door to wonder — not answers.", "What question stayed with you?"),
            ("Rig Veda 1.89.1", "आ नो भद्राः क्रतवो", "Let noble thoughts come from every side.",
             "The Veda invites breadth — let your reading widen.", "What noble thought did you welcome?"),
            ("Mundaka Upanishad 3.1.6", "सत्यमेव जयते", "Truth alone triumphs — not falsehood.",
             "Return to truth when reading feels noisy.", "What truth felt simple today?"),
            ("Bhagavad Gita 9.22", "अनन्याश्चिन्तयन्तो मां", "Those who worship me with devotion — I preserve what they have.",
             "Reading as devotion is never wasted.", "How did reading feel like devotion today?"),
            ("Chandogya Upanishad 6.8.7", "तत् त्वम् असि", "That thou art.",
             "One line can carry a lifetime — sit with it.", "What single line will you carry this week?")
        ]
        let days = verses.enumerated().map { i, v in
            day(goalId, level: 1, slot: i, ref: v.0, sanskrit: v.1, text: v.2, krishna: v.3, prompt: v.4)
        }
        return level(goalId, n: 1, name: "First Light", days: days,
                     reward: ("Shishya", "The student who lit their first flame", "seal.fill"))
    }

    private static func dailyReadingLevel2(goalId: String) -> PathLevel {
        let days = GoalPathContent.defaultLevel2Days(goalId: goalId)
        return level(goalId, n: 2, name: "Deepening Gita", days: days,
                     reward: ("Sadhaka", "The practitioner deepening their path", "sparkles"))
    }

    private static func dailyReadingLevel3(goalId: String) -> PathLevel {
        let days = GoalPathContent.defaultLevel3Days(goalId: goalId)
        return level(goalId, n: 3, name: "Sacred Questions", days: days,
                     reward: ("Gyani", "One who begins to know", "leaf.fill"))
    }

    private static func dailyReadingLevel4(goalId: String) -> PathLevel {
        let days = GoalPathContent.defaultLevel4Days(goalId: goalId)
        return level(goalId, n: 4, name: "Song of Ages", days: days,
                     reward: ("Vairagi", "The one who has learned to release", "bolt.fill"))
    }

    private static func dailyReadingLevel5(goalId: String) -> PathLevel {
        let days = GoalPathContent.defaultLevel5Days(goalId: goalId)
        return level(goalId, n: 5, name: "One Thread", days: days,
                     reward: ("Yogi", "United with what is", "sun.horizon.fill"))
    }
}
