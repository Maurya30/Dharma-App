//
//  AppIntent.swift
//  DharmaWidget
//
//  Created by Maurya Panchal on 2026-03-16.
//

import WidgetKit
import AppIntents

enum WidgetContentType: String, AppEnum {
    case daily = "Daily Verse"
    case gita = "Daily Gita Verse"
    case upanishad = "Daily Upanishad"
    case mantra = "Daily Mantra"
    case favourites = "From Favourites"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content Type"
    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .daily: "Daily Verse",
        .gita: "Daily Gita Verse",
        .upanishad: "Daily Upanishad",
        .mantra: "Daily Mantra",
        .favourites: "From Favourites"
    ]
}

struct DharmaWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dharma Widget"
    static var description = IntentDescription("Choose what scripture to display")

    @Parameter(title: "Content Type", default: .daily)
    var contentType: WidgetContentType
}
