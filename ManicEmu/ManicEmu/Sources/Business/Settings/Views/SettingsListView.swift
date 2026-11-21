//
//  SettingsListView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import RealmSwift
import MessageUI

class SettingsListView: BaseView {
    enum SectionIndex: Int, CaseIterable {
        case top, general, advance, support, others, moreFromManic, bottom
        var title: String {
            switch self {
            case .top, .bottom:
                ""
            case .general:
                R.string.localizable.generalSettingTitle()
            case .advance:
                R.string.localizable.advanceSettingTitle()
            case .support:
                R.string.localizable.supportSettingTitle()
            case .others:
                R.string.localizable.othersSettingTitle()
            case .moreFromManic:
                break

            case .bottom:
                var cellHeight = 479.0
#if SIDE_LOAD
                cellHeight += 76
#endif
                sections.append(ASListPage.Section(cells: [ASListPage.Cell.custom(bottomView)],
                                                   decoration: .init(enable: false),
                                                   itemLayout: .fixedHeight(cellHeight)))
                
            }
        }
        
        let listBottomInset = R.Size.ContentSpaceLarge + R.Size.HomeTabBarSize.height + R.Size.ContentSpaceLarge
        let pageTopInset: CGFloat
        pageTopInset = (UIDevice.isPhone && !UIDevice.isPhoneDuoInnerFullScreen) && preferredLayoutStyle == .landscape ? 0 : R.Size.ContentInsetTop(window: hostingWindow)
        return ASListPage(navigation: getNavigation(),
                          sections: sections,
                          backgroundColor: .clear,
                          listInsets: .insets(bottom: listBottomInset),
                          pageInsets: .insets(top: pageTopInset))
    }
    
    private func showMemberShip(featuresType: FeaturesType = .advance) {
#if !SIDE_LOAD
        topViewController(in: hostingWindowScene)?.present(PurchaseViewController(featuresType: featuresType), animated: true)
#endif
    }
    
    @discardableResult
    private func upateSwitchSettings(extraValue: Any?,
                                     cellData: ASListPage.Cell,
                                     indexPath: IndexPath,
                                     settingsUpdation: ((Bool) -> Void)? = nil) -> Bool? {
        if let value = extraValue as? Bool {
            Settings.change { _ in
                settingsUpdation?(value)
            }
            listPageView?.updateCellData(cellData.updateNormalSwitch(state: value ? .on : .off), indexPath: indexPath, reloadView: false)
            return value
        }
        return nil
    }
    
    private func reloadData() {
        listPageView?.updatePage(getListPage())
    }
    
    private func reloadCell(for item: SettingItem) {
        var section: SectionIndex? = nil
        var row: Int? = nil
        for (sectionIndex, items) in items {
            if let itemIndex = items.firstIndex(where: { $0.type == item.type }) {
                section = sectionIndex
                row = itemIndex
                break
            }
        }
        
        if let section, let row {
            listPageView?.updateCellData(item.cellData, indexPath: IndexPath(row: row, section: section.rawValue))
        }
    }
    
    private func handleAction(_ action: ASListPage.Action) {
        switch action {
        case .normalItem(let indexPath, let cellData, let subActions):
            if let sectionIndex = SectionIndex(rawValue: indexPath.section) {
                switch sectionIndex {
                case .top:
                    break
                    
                case .general, .advance, .support, .others:
                    if let item = items[sectionIndex]?[indexPath.row] {
                        guard let _ = hostingWindow else { return }
                        switch item.type {
                        case .retro:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(RetroAchievementsLaunchView(loginedAction: .jumpProfile, showClose: false))
                            } else {
                                RetroAchievementsLaunchView.show(loginedAction: .jumpProfile)
                            }
                            
                        case .onlinePlay:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(OnlinePlaySettingView(showClose: false))
                            } else {
                                OnlinePlaySettingView.show()
                            }
                            
                        case .bios:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(BIOSSelectionView(showClose: false))
                            } else {
                                BIOSSelectionView.show()
                            }
                            
                        case .theme:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ThemeSettingView(showClose: false))
                            } else {
                                ThemeSettingView.show()
                            }
                            
                        case .FAQ:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ASWebView(url: R.URLs.FAQ, showClose: false))
                            } else {
                                ASWebView.show(url: R.URLs.FAQ)
                            }
                            
                        case .feedback:
                            if MFMailComposeViewController.canSendMail() {
                                let mailController = MFMailComposeViewController()
                                mailController.setToRecipients([R.Strings.SupportEmail])
                                mailController.mailComposeDelegate = self
                                topApplicationViewController()?.present(mailController, animated: true)
                            } else {
                                UIView.makeToast(message: R.string.localizable.noEmailSetting())
                            }
                            
                        case .shareApp:
                            ShareManager.shareApp(senderForIpad: UIDevice.isPad ? self : nil, in: hostingWindowScene)
                            
                        case .qq:
                            UIApplication.shared.open(R.URLs.JoinQQ)
                            
                        case .discord:
                            UIApplication.shared.open(R.URLs.JoinDiscord)
                            
                        case .clearCache:
                            UIView.makeLoading()
                            CacheManager.clear { [weak self] in
                                self?.listPageView?.updateCellData(cellData.updateNormalChevron(title: nil), indexPath: indexPath)
                                UIView.hideLoading()
                            }
                            
                        case .resetTips:
                            R.DefaultKey.TipsDefaultKeys.forEach({
                                UserDefaults.standard.set(false, forKey: $0)
                            })
                            UIView.makeToast(message: R.string.localizable.resetTipsSuccess())
                            
                        case .language:
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            
                        case .userAgreement:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ASWebView(url: R.URLs.TermsOfUse, showClose: false))
                            } else {
                                ASWebView.show(url: R.URLs.TermsOfUse)
                            }
                            
                        case .privacyPolicy:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ASWebView(url: R.URLs.PrivacyPolicy, showClose: false))
                            } else {
                                ASWebView.show(url: R.URLs.PrivacyPolicy)
                            }
                            
                        case .about:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ASWebView(url: R.URLs.AboutUS, showClose: false))
                            } else {
                                ASWebView.show(url: R.URLs.AboutUS)
                            }
                            
                        case .triggerPro:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(TriggerProManageView(showClose: false))
                            } else {
                                TriggerProManageView.show()
                            }
                            
                        case .skin:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(SkinSettingsView(showClose: false))
                            } else {
                                SkinSettingsView.show()
                            }
                            
                        case .iCloud:
#if !SIDE_LOAD
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ICloudSettingView(showClose: false))
                            } else {
                                ICloudSettingView.show()
                            }
#endif
                            
                        case .jit:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(JITSettingView(showClose: false))
                            } else {
                                JITSettingView.show()
                            }
                            
                        case .shaders:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(ShaderListView(initType: .normal, showClose: false))
                            } else {
                                ShaderListView.show(initType: .normal)
                            }
                            
                        case .featuredItems:
                            UIApplication.shared.open(R.URLs.PlayCasePromo)
                            
                        case .globalCoreSwitch:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                didTapDetailView?(GlobalCoreSwitchView(showClose: false))
                            } else {
                                GlobalCoreSwitchView.show()
                            }
                            
                        case .quickGame:
                            upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath) {
                                Settings.defalut.quickGame = $0
                            }
                            
                        case .airPlay:
                            if let extraValue = subActions?.extraValue {
                                upateSwitchSettings(extraValue: extraValue, cellData: cellData, indexPath: indexPath) {
                                    Settings.defalut.airPlay = $0
                                }
                            } else {
                                showMemberShip(featuresType: .airplay)
                            }
                            
                        case .fullScreenWhenConnectController:
                            upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath) {
                                Settings.defalut.fullScreenWhenConnectController = $0
                            }
                            
                        case .autoSaveState:
                            upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath) {
                                Settings.defalut.autoSaveState = $0
                            }
                            
                        case .respectSilentMode:
                            upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath) {
                                Settings.defalut.respectSilentMode = $0
                            }
                            
                        case .rumble:
                            let value = upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath)
                            Settings.defalut.updateExtra(key: ExtraKey.rumble.rawValue, value: value)
                            
                        case .appearance:
                            if let index = subActions?.extraValue as? Int {
                                Settings.appearance = Settings.Appearance(rawValue: index) ?? .dark
                                listPageView?.updateCellData(cellData.updateNormalSegment(index: index), indexPath: indexPath)
                            }
                            
                        case .skinSound:
                            let value = upateSwitchSettings(extraValue: subActions?.extraValue, cellData: cellData, indexPath: indexPath)
                            Settings.defalut.updateExtra(key: ExtraKey.skinSoundEffects.rawValue, value: value)
                            
                        case .coverScraping:
                            if isWindowHasEnoughSpaceforIpadMultiColumnLayout {
                                let realm = Database.realm
                                let games = realm.objects(Game.self).where({ !$0.isDeleted })
                                if games.count > 0 {
                                    didTapDetailView?(GameCoverScrapingView(games: Array(games),
                                                                            showClose: false))
                                } else {
                                    UIView.makeToast(message: R.string.localizable.transferPakNoGames())
                                }
                            } else {
                                GameCoverScrapingView.show()
                            }
                            
                        default:
                            break
                        }
                    }
                    
                case .moreFromManic, .bottom:
                    break
                }
            }
        default:
            break
        }
    }
}

extension SettingsListView: ViewTransition {
    func viewAlongsideTransition() {
        if UIDevice.isPhone {
            topView.removeFromSuperview()
            topView.updateViewsConstraints()
            reloadData()
        }
    }
}

extension SettingsListView: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        switch result {
        case .sent:
            UIView.makeToast(message: R.string.localizable.sendEmailSuccess())
            controller.dismiss(animated: true)
        case .failed:
            var errorMsg = ""
            if let error = error {
                errorMsg += "\n" + error.localizedDescription
            }
            UIView.makeToast(message: R.string.localizable.sendEmailFailed(errorMsg))
        default:
            controller.dismiss(animated: true)
        }
        
    }
}
