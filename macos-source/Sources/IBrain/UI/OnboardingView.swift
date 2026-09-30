// One-time mini welcome sheet — shown on first launch only, same visual
// language as the rest of the app (BrainBadge, purple accent, plain text).
import SwiftUI

enum OnboardingPrefs {
    static let hasSeenOnboarding = "hasSeenOnboarding"
}

struct OnboardingView: View {
    @AppStorage(Prefs.language) private var languageRaw = "en"
    let onDismiss: () -> Void

    private var language: Language {
        Language(rawValue: languageRaw) ?? .en
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            BrainBadge(size: 52)
                .padding(.bottom, 16)

            Text(Strings.get("onboarding.title", lang: language))
                .font(.system(size: 19, weight: .semibold))
                .padding(.bottom, 6)

            Text(Strings.get("onboarding.body", lang: language))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 10) {
                onboardingRow("lock.shield", "onboarding.point.private")
                onboardingRow("wifi.slash", "onboarding.point.offline")
                onboardingRow("slider.horizontal.3", "onboarding.point.custom")
            }
            .frame(maxWidth: 300, alignment: .leading)
            .padding(.bottom, 32)

            Button {
                onDismiss()
            } label: {
                Text(Strings.get("onboarding.dismiss", lang: language))
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 8) {
                Text(Strings.get("onboarding.selectLanguage", lang: language))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Picker("", selection: $languageRaw) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.rawValue).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func onboardingRow(_ symbol: String, _ textKey: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.6, green: 0.3, blue: 0.95))
                .frame(width: 18)
            Text(Strings.get(textKey, lang: language))
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }
}
