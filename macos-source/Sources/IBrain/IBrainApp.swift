// iBrain — local Ollama chat by default, with optional cloud API mode.
// Regular windowed app (Dock icon, Applications/Spotlight visible) with a
// small menu bar quick-open extra, matching the rest of the iSuite apps.
import AppKit
import SwiftUI

@main
struct IBrainApp: App {
    @StateObject private var store = ChatStore()
    @AppStorage(Prefs.language) private var languageRaw = "en"
    @AppStorage(Prefs.appearance) private var appearanceRaw = Appearance.system.rawValue

    init() {
        Prefs.registerDefaults()
    }

    private var language: Language {
        Language(rawValue: languageRaw) ?? .en
    }

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some Scene {
        Window("iBrain", id: "main") {
            MainView(store: store)
                .preferredColorScheme(colorScheme)
                .onAppear { store.boot() }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 620)

        Settings {
            SettingsView(store: store)
        }

        MenuBarExtra {
            Button(Strings.get("menu.open", lang: language)) {
                openMainWindow()
            }
            Divider()
            Button(Strings.get("menu.quit", lang: language)) {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "brain")
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}

struct MainView: View {
    @ObservedObject var store: ChatStore
    @AppStorage(Prefs.language) private var languageRaw = "en"
    @AppStorage(OnboardingPrefs.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(Prefs.useCloudAPI) private var cloudModeEnabled = false

    private var language: Language {
        Language(rawValue: languageRaw) ?? .en
    }

    var body: some View {
        if hasSeenOnboarding {
            HSplitView {
                SidebarView(store: store, language: language)
                    .frame(minWidth: 220, idealWidth: 240, maxWidth: 320)
                Group {
                    if cloudModeEnabled && !store.hasCloudKey {
                        CloudKeyRequiredView(language: language)
                    } else if store.useCloudAPI || (store.serverStatus == .running && !store.models.isEmpty) {
                        ChatView(store: store, language: language)
                    } else if store.serverStatus == .checking && store.models.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        SetupView(store: store, language: language)
                    }
                }
                .frame(minWidth: 480, maxWidth: .infinity)
            }
            .frame(minWidth: 760, minHeight: 520)
        } else {
            OnboardingView {
                hasSeenOnboarding = true
            }
            .frame(minWidth: 760, minHeight: 520)
        }
    }
}

private struct CloudKeyRequiredView: View {
    let language: Language

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(Strings.get("cloud.missing.title", lang: language))
                .font(.headline)
            Text(Strings.get("cloud.missing.body", lang: language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
