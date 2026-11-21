//
//  GameMetadataKit.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/8/8.
//  Copyright © 2026 Manic EMU. All rights reserved.
//

import SmartCodable

struct GameMetadata: SmartCodable {
    var developer: String = ""
    var publisher: String = ""
    var ratingId: Int = 0
    var users: Int = 0
    var franchise: String = ""
    var releaseYear: Int = 0
    var releaseMonth: Int = 0
    var region: String = ""
    var genre: String = ""
    var displayName: String = ""
    var fullName: String = ""
    var platform: String = ""
    var overview: String = ""
    
    var ESRPRating: ESRP? {
        switch ratingId {
        case 1:
            return .T
        case 2:
            return .M
        case 3:
            return .K_A
        case 4:
            return .E10
        case 5:
            return .E
        case 7:
            return .EC
        case 8:
            return .AO
        case 9:
            return .RP
        case 10:
            return .RP17
        default:
            return nil
        }
    }
    
    /// extras → DB → 空实例，保证编辑页始终可打开
    static func resolved(for game: Game) -> GameMetadata {
        if let metadata = getGameMetadata(game: game) {
            return metadata
        }
        if let metadata = GameMetadataKit.getGameInfo(game: game) {
            return metadata
        }
        return GameMetadata()
    }
    
    var releaseDateDisplay: String {
        if releaseYear > 0, (1...12).contains(releaseMonth) {
            return String(format: "%d-%02d", releaseYear, releaseMonth)
        }
        if releaseYear > 0 {
            return "\(releaseYear)"
        }
        return "—"
    }
    
    var esrpDisplay: String {
        ESRPRating?.abbr ?? "—"
    }
    
    mutating func setESRP(_ esrp: ESRP?) {
        ratingId = esrp?.ratingId ?? 0
    }
    
    func persist(to game: Game) {
        if let json = toJSONString() {
            game.updateExtra(key: ExtraKey.gameMetadata.rawValue, value: json)
            NotificationCenter.default.post(name: R.NotificationName.GameMetadataChange, object: game.id)
        }
    }
    
    static func getGameMetadata(game: Game) -> Self? {
        guard let metadataString = game.getExtraString(key: ExtraKey.gameMetadata.rawValue) else {
            return nil
        }
        guard let metadata = GameMetadata.deserialize(from: metadataString) else {
            return nil
        }
        return metadata
    }
}

struct GameMetadataKit {
    private static let welcomeAmiiboIdentifiers: Set<UInt64> = [
        0x0004000000198D00, 0x0004000000198E00, 0x0004000000198F00
    ]

    private static func metadata(welcomeAmiibo: Bool) -> GameMetadata {
        var info = GameMetadata()
        info.displayName = welcomeAmiibo
            ? "Animal Crossing: New Leaf - Welcome amiibo"
            : "Animal Crossing: New Leaf"
        info.fullName = info.displayName
        info.publisher = "Nintendo"
        info.franchise = "Animal Crossing"
        info.platform = "Nintendo 3DS"
        return info
    }

    static func getGameInfo(game: Game) -> GameMetadata? {
        guard game.isNewLeafGame else { return nil }
        game.updateExtra(key: ExtraKey.hasQueryMetadata.rawValue, value: true)
        let welcomeAmiibo = welcomeAmiiboIdentifiers.contains(game.identifierFor3DS)
            || (game.name + " " + (game.aliasName ?? "")).localizedCaseInsensitiveContains("amiibo")
        return metadata(welcomeAmiibo: welcomeAmiibo)
    }

    static func searchGameInfo(displayName query: String) -> [GameMetadata] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [metadata(welcomeAmiibo: false), metadata(welcomeAmiibo: true)].filter {
            $0.displayName.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
