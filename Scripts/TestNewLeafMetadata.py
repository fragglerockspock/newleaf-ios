from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'ManicEmu/ManicEmu/Sources/Tools/Others/GameMetadataKit.swift').read_text()
catalog = source[source.index('struct GameMetadataKit {'):]
home = (root / 'ManicEmu/ManicEmu/Sources/Business/Home/ViewControllers/HomeViewController.swift').read_text()
detection = home[home.index('extension Game {'):]
harness = '''
import Foundation
struct GameMetadata {
    var displayName = ""
    var fullName = ""
    var publisher = ""
    var franchise = ""
    var platform = ""
}
enum GameType { case _3ds, gba }
enum ExtraKey: String { case hasQueryMetadata }
final class Game {
    var gameType: GameType
    var identifierFor3DS: UInt64
    var name: String
    var aliasName: String?
    var queried = false
    init(_ identifier: UInt64, _ name: String = "renamed.3ds", _ type: GameType = ._3ds) {
        self.identifierFor3DS = identifier
        self.name = name
        self.gameType = type
    }
    func updateExtra(key: String, value: Bool) { queried = value }
}
'''
checks = '''
for id: UInt64 in [0x0004000000086200, 0x0004000000086300, 0x0004000000086400, 0x0004000000086500] {
    let game = Game(id)
    precondition(GameMetadataKit.getGameInfo(game: game)?.displayName == "Animal Crossing: New Leaf")
    precondition(game.queried)
}
for id: UInt64 in [0x0004000000198D00, 0x0004000000198E00, 0x0004000000198F00] {
    precondition(GameMetadataKit.getGameInfo(game: Game(id))?.displayName == "Animal Crossing: New Leaf - Welcome amiibo")
}
let alias = Game(0)
alias.aliasName = "Animal Crossing New Leaf Welcome amiibo"
precondition(GameMetadataKit.getGameInfo(game: alias)?.displayName.contains("amiibo") == true)
precondition(GameMetadataKit.getGameInfo(game: Game(0, "Animal Crossing: New Leaf")) != nil)
precondition(GameMetadataKit.getGameInfo(game: Game(0, "Other game")) == nil)
precondition(GameMetadataKit.getGameInfo(game: Game(0, "New Leaf", .gba)) == nil)
precondition(GameMetadataKit.searchGameInfo(displayName: " new LEAF ").count == 2)
precondition(GameMetadataKit.searchGameInfo(displayName: "amiibo").count == 1)
precondition(GameMetadataKit.searchGameInfo(displayName: "Pokemon").isEmpty)
precondition(GameMetadataKit.searchGameInfo(displayName: "  ").isEmpty)
precondition(GameMetadataKit.searchGameInfo(displayName: "%").isEmpty)
print("New Leaf and Welcome amiibo catalog checks passed")
'''
assert not (root / 'System.core/Extras.db').exists()
for path in (root / 'ManicEmu/ManicEmu/Sources').rglob('*.swift'):
    assert 'R.Path.ExtrasDB' not in path.read_text(), path
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'main.swift'
    path.write_text(harness + detection + catalog + checks)
    subprocess.run(['swift', str(path)], check=True)
