// Left sidebar — logo, New chat button, grouped history, Settings.
import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: ChatStore
    let language: Language
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            newChatButton
            searchField
            chatList
            Spacer(minLength: 0)
            settingsButton
        }
        .frame(minWidth: 220)
        .background(.background)
    }

    private var header: some View {
        HStack(spacing: 8) {
            BrainBadge(size: 26)
            Text("iBrain")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var newChatButton: some View {
        Button {
            store.newChat()
        } label: {
            Text(Strings.get("sidebar.newChat", lang: language))
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            TextField(Strings.get("sidebar.search", lang: language), text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var chatList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                let groups = groupedChats
                ForEach(groups, id: \.label) { group in
                    Text(group.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .tracking(0.5)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 2)
                    ForEach(group.chats) { chat in
                        chatRow(chat)
                    }
                }
                if groups.isEmpty {
                    Text(Strings.get("sidebar.noChats", lang: language))
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 6)
        }
    }

    private func chatRow(_ chat: Chat) -> some View {
        let selected = store.selectedChatID == chat.id
        return Button {
            store.selectedChatID = chat.id
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.title)
                    .font(.system(size: 13, weight: selected ? .medium : .regular))
                    .foregroundStyle(selected ? .primary : .secondary)
                    .lineLimit(1)
                Text(relativeLabel(chat.updatedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(selected ? Color.primary.opacity(0.07) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                store.deleteChat(chat.id)
            } label: {
                Label(Strings.get("chat.deleteChat", lang: language), systemImage: "trash")
            }
        }
    }

    private var settingsButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                openSettings()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(Strings.get("sidebar.settings", lang: language))
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private struct ChatGroup {
        let label: String
        let chats: [Chat]
    }

    private var groupedChats: [ChatGroup] {
        let calendar = Calendar.current
        var today: [Chat] = []
        var yesterday: [Chat] = []
        var previous: [Chat] = []
        for chat in store.filteredChats {
            if calendar.isDateInToday(chat.updatedAt) {
                today.append(chat)
            } else if calendar.isDateInYesterday(chat.updatedAt) {
                yesterday.append(chat)
            } else {
                previous.append(chat)
            }
        }
        var groups: [ChatGroup] = []
        if !today.isEmpty {
            groups.append(ChatGroup(label: Strings.get("sidebar.today", lang: language), chats: today))
        }
        if !yesterday.isEmpty {
            groups.append(ChatGroup(label: Strings.get("sidebar.yesterday", lang: language), chats: yesterday))
        }
        if !previous.isEmpty {
            groups.append(ChatGroup(label: Strings.get("sidebar.previous", lang: language), chats: previous))
        }
        return groups
    }

    private func relativeLabel(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: language == .es ? "es" : "en")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Purple gradient circle with white brain — the app's avatar mark.
struct BrainBadge: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.66, green: 0.33, blue: 0.97),
                            Color(red: 0.42, green: 0.18, blue: 0.85),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "brain")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
