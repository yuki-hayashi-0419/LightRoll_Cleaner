//
//  AboutView.swift
//  LightRoll_CleanerFeature
//
//  アプリ情報画面の実装（MV Pattern）
//  バージョン、ビルド番号、ライセンス、クレジット情報を表示
//  M8-T13 実装
//  Created by AI Assistant on 2025-12-06.
//

import SwiftUI

// MARK: - AboutView

/// アプリ情報画面
///
/// MV Patternに従い、ViewModelを使用せずシンプルな表示のみを実装
/// - アプリアイコン、バージョン情報
/// - 開発者情報（名前、URL、メール）
/// - 法的情報（プライバシーポリシー、利用規約、ライセンス）
/// - コピーライト表示
@MainActor
public struct AboutView: View {

    // MARK: - State

    /// プライバシーポリシーSheet表示フラグ
    @State private var showingPrivacyPolicy = false

    /// 利用規約Sheet表示フラグ
    @State private var showingTermsOfService = false

    /// ライセンスSheet表示フラグ
    @State private var showingLicenses = false

    /// 準備中アラート表示フラグ
    @State private var showingComingSoonAlert = false

    // MARK: - Body

    public var body: some View {
        List {
            headerSection
            infoSection
            legalSection
            footerSection
        }
        .navigationTitle("アプリ情報")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.automatic)
        #endif
        .alert("準備中", isPresented: $showingComingSoonAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("この機能は現在準備中です。しばらくお待ちください。")
        }
    }

    // MARK: - Header Section

    /// ヘッダーセクション（アプリアイコン、名前、バージョン）
    private var headerSection: some View {
        Section {
            VStack(spacing: 16) {
                // アプリアイコン
                appIcon

                // アプリ名
                Text("LightRoll Cleaner")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                // バージョン情報
                versionInfo
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .listRowBackground(Color.clear)
    }

    /// アプリアイコン
    private var appIcon: some View {
        Image(systemName: "photo.stack")
            .font(.system(size: 80))
            .foregroundStyle(.blue.gradient)
            .padding()
            .glassCard(cornerRadius: 24, style: .regular)
            .accessibilityLabel("アプリアイコン")
    }

    /// バージョン情報
    private var versionInfo: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text("バージョン")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(appVersion)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {
                Text("ビルド")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(buildNumber)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("バージョン \(appVersion), ビルド \(buildNumber)")
    }

    // MARK: - Info Section

    /// 情報セクション（開発者情報）
    private var infoSection: some View {
        Section {
            SettingsRow(
                icon: "person.circle",
                iconColor: .blue,
                title: "開発者",
                subtitle: developerName
            )

            Button {
                openWebsite()
            } label: {
                SettingsRow(
                    icon: "globe",
                    iconColor: .green,
                    title: "ウェブサイト",
                    subtitle: websiteURL
                )
            }
            .buttonStyle(.plain)

            Button {
                openEmail()
            } label: {
                SettingsRow(
                    icon: "envelope",
                    iconColor: .orange,
                    title: "サポート",
                    subtitle: supportEmail
                )
            }
            .buttonStyle(.plain)
        } header: {
            Text("情報")
        }
    }

    // MARK: - Legal Section

    /// 法的情報セクション
    private var legalSection: some View {
        Section {
            Button {
                showPrivacyPolicy()
            } label: {
                SettingsRow(
                    icon: "hand.raised",
                    iconColor: .purple,
                    title: "プライバシーポリシー",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Button {
                showTermsOfService()
            } label: {
                SettingsRow(
                    icon: "doc.text",
                    iconColor: .blue,
                    title: "利用規約",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            Button {
                showLicenses()
            } label: {
                SettingsRow(
                    icon: "book.closed",
                    iconColor: .indigo,
                    title: "ライセンス",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        } header: {
            Text("法的情報")
        }
    }

    // MARK: - Footer Section

    /// フッターセクション（コピーライト）
    private var footerSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("© 2025 LightRoll Cleaner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("© 2025 LightRoll Cleaner")
    }

    // MARK: - Helpers

    /// アプリバージョン（Bundle.main.infoDictionary から取得）
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// ビルド番号（Bundle.main.infoDictionary から取得）
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 開発者名
    private var developerName: String {
        "LightRoll Team"
    }

    /// ウェブサイトURL（表示用）
    private var websiteURL: String {
        "https://lightroll.app"
    }

    /// サポートメールアドレス
    private var supportEmail: String {
        "support@lightroll.app"
    }

    // MARK: - Actions

    /// ウェブサイトを開く
    private func openWebsite() {
        guard let url = URL(string: "https://\(websiteURL)") else {
            showingComingSoonAlert = true
            return
        }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    /// サポートメールを開く
    private func openEmail() {
        guard let url = URL(string: "mailto:\(supportEmail)") else {
            showingComingSoonAlert = true
            return
        }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    /// プライバシーポリシーを表示
    private func showPrivacyPolicy() {
        // 実装予定: プライバシーポリシーページへ遷移
        // 現在は準備中アラート表示
        showingComingSoonAlert = true
    }

    /// 利用規約を表示
    private func showTermsOfService() {
        // 実装予定: 利用規約ページへ遷移
        // 現在は準備中アラート表示
        showingComingSoonAlert = true
    }

    /// ライセンス情報を表示
    private func showLicenses() {
        // 実装予定: ライセンスページへ遷移
        // 現在は準備中アラート表示
        showingComingSoonAlert = true
    }
}

// MARK: - Preview

#Preview("Default") {
    NavigationStack {
        AboutView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    NavigationStack {
        AboutView()
    }
    .preferredColorScheme(.dark)
}
