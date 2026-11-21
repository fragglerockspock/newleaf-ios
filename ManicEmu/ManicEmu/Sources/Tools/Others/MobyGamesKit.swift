import Foundation

struct MobyGamesKit {
    static func getGameInfoUrl(gameType: GameType, name: String, completion: ((URL) -> Void)? = nil) {
        DispatchQueue.main.async {
            completion?(R.URLs.MobyGames)
        }
    }

    static func getGameInfoUrl(game: Game, completion: ((URL) -> Void)? = nil) {
        getGameInfoUrl(gameType: game.gameType, name: game.translatedName ?? game.displayName, completion: completion)
    }
}
