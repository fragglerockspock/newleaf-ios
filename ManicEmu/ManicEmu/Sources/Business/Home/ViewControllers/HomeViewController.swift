import UIKit
import RealmSwift
import UniformTypeIdentifiers

class HomeViewController: BaseViewController {
    let homeTabBar = HomeTabBar(orientation: .portrait)
    private var games: Results<Game>?
    private var observation: NotificationToken?
    private var selectedGame: Game?
    private let artwork = UIImageView()
    private let statusLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.13, blue: 0.08, alpha: 1)
        view.accessibilityIdentifier = "ACNL Dedicated Launcher 1"
        artwork.contentMode = .scaleAspectFit
        artwork.layer.cornerRadius = 28
        artwork.clipsToBounds = true
        artwork.image = UIImage(named: "NewLeafIcon")
        artwork.heightAnchor.constraint(equalToConstant: 220).isActive = true
        let title = UILabel()
        title.text = "Animal Crossing:\nNew Leaf"
        title.font = .systemFont(ofSize: 32, weight: .bold)
        title.textColor = .white
        title.textAlignment = .center
        title.numberOfLines = 2
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        var play = UIButton.Configuration.filled()
        play.title = "Play"
        play.image = UIImage(systemName: "play.fill")
        play.imagePadding = 12
        play.baseBackgroundColor = UIColor(red: 0.23, green: 0.66, blue: 0.21, alpha: 1)
        play.baseForegroundColor = .white
        play.cornerStyle = .capsule
        play.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 32, bottom: 18, trailing: 32)
        playButton.configuration = play
        playButton.addTarget(self, action: #selector(playGame), for: .touchUpInside)
        var settings = UIButton.Configuration.tinted()
        settings.title = "Settings"
        settings.image = UIImage(systemName: "gearshape.fill")
        settings.imagePadding = 12
        settings.baseForegroundColor = .white
        settings.cornerStyle = .capsule
        settings.contentInsets = play.contentInsets
        settingsButton.configuration = settings
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [artwork, title, statusLabel, playButton, settingsButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 32),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, multiplier: 0.82)
        ])
        games = Database.realm.objects(Game.self).filter("isDeleted == false").sorted(byKeyPath: "latestPlayDate", ascending: false)
        observation = games?.observe { [weak self] _ in self?.refreshGame() }
        refreshGame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshGame()
    }

    private func refreshGame() {
        selectedGame = games?.first(where: { $0.isNewLeafGame })
        playButton.configuration?.title = selectedGame == nil ? "Import New Leaf" : "Play"
        statusLabel.text = selectedGame == nil ? "Import your Animal Crossing: New Leaf game to get started." : "Your town is ready."
        let gameID = selectedGame?.id
        selectedGame?.getCoverImage { [weak self] image in
            guard let self, self.selectedGame?.id == gameID else { return }
            self.artwork.image = image ?? UIImage(named: "NewLeafIcon")
        }
    }

    @objc private func playGame() {
        guard let game = selectedGame, !game.isInvalidated else {
            importGame()
            return
        }
        game.changeDefaultCore(coreIndex: 1)
        game.handleTapAction(forceQuick: true, in: hostingWindowScene)
    }

    private func importGame() {
        FilesImporter.shared.presentImportController(supportedTypes: [.data, .archive], allowsMultipleSelection: false, manualHandle: { [weak self] urls in
            FilesImporter.importFiles(urls: urls, in: self?.hostingWindowScene, importCompletion: { [weak self] in
                self?.refreshGame()
            })
        }, in: hostingWindowScene)
    }

    @objc private func showSettings() {
        let menu = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        if let game = selectedGame, !game.isInvalidated {
            menu.addAction(UIAlertAction(title: "Game, controls & saves", style: .default) { _ in
                guard !game.isInvalidated else { return }
                game.changeDefaultCore(coreIndex: 1)
                GameOptionsView.show(scene: .gameInfo, games: [game], shouldHide: { option in
                    [.switchCore, .platformChange, .changeCategory, .delete, .shareRom, .copyLink].contains(option)
                })
            })
        }
        menu.addAction(UIAlertAction(title: "App settings & JIT", style: .default) { [weak self] _ in
            guard let self else { return }
            let settings = SettingsViewController()
            settings.title = "Settings"
            settings.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeSettings))
            self.present(UINavigationController(rootViewController: settings), animated: true)
        })
        menu.addAction(UIAlertAction(title: "Import New Leaf", style: .default) { [weak self] _ in self?.importGame() })
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        menu.popoverPresentationController?.sourceView = settingsButton
        menu.popoverPresentationController?.sourceRect = settingsButton.bounds
        present(menu, animated: true)
    }

    @objc private func closeSettings() {
        dismiss(animated: true)
    }
}

extension Game {
    var isNewLeafGame: Bool {
        guard gameType == ._3ds else { return false }
        let identifiers: Set<UInt64> = [0x0004000000086200, 0x0004000000086300, 0x0004000000086400, 0x0004000000086500, 0x0004000000198D00, 0x0004000000198E00, 0x0004000000198F00]
        return identifiers.contains(identifierFor3DS) || (name + " " + (aliasName ?? "")).localizedCaseInsensitiveContains("new leaf")
    }
}
