import SwiftUI

// MARK: - Sample Themed Component
struct ThemedComponentExample: View {
    @Environment(\.theme) private var theme
    @State private var isExpanded = false
    @State private var selectedOption = 0
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    let options = ["Option 1", "Option 2", "Option 3"]

    var body: some View {
        VStack(spacing: theme.spacing.medium) {
            // Header Section
            headerSection

            // Search Section
            searchSection

            // Content Cards
            contentCards

            // Action Buttons
            actionButtons
        }
        .themedSpacing(.medium)
        .background(theme.colors.background)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Themed Component Example")
                    .font(theme.typography.title)
                    .foregroundColor(theme.colors.text.primary)

                Text("Demonstrating the theming system")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }

            Spacer()

            Button(action: {
                withAnimation(EmojiAnimations.selection) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .iconStyle(color: .accent, size: .medium)
            }
            .themedButton(.ghost, size: .small)
        }
        .themedCard(.low)
    }

    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: theme.spacing.small) {
            Image(systemName: "magnifyingglass")
                .iconStyle(color: .secondary, size: .medium)

            TextField("Search components...", text: $searchText)
                .focused($isSearchFocused)
                .themedTextField(isFocused: isSearchFocused)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .iconStyle(color: .secondary, size: .small)
                }
                .themedButton(.ghost, size: .small)
            }
        }
        .themedCard(.medium)
    }

    // MARK: - Content Cards
    private var contentCards: some View {
        VStack(spacing: theme.spacing.small) {
            ForEach(options.indices, id: \.self) { index in
                optionCard(for: index)
            }
        }
    }

    private func optionCard(for index: Int) -> some View {
        Button(action: {
            withAnimation(EmojiAnimations.selection) {
                selectedOption = index
            }
        }) {
            HStack {
                // Selection indicator
                Image(systemName: selectedOption == index ? "checkmark.circle.fill" : "circle")
                    .iconStyle(
                        color: selectedOption == index ? .accent : .secondary,
                        size: .medium
                    )

                // Content
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(options[index])
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.text.primary)

                    Text("Sample description for \(options[index])")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.text.secondary)
                }

                Spacer()

                // Status badge
                Text("Active")
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.text.inverse)
                    .padding(.horizontal, theme.spacing.small)
                    .padding(.vertical, theme.spacing.xs)
                    .background(
                        Capsule()
                            .fill(theme.colors.semantic.success)
                    )
            }
        }
        .themedCard(selectedOption == index ? .medium : .low)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(
                    selectedOption == index ? theme.colors.border.selected : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(selectedOption == index ? 1.02 : 1.0)
        .animation(EmojiAnimations.selection, value: selectedOption)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: theme.spacing.small) {
            Button("Cancel") {
                // Handle cancel
            }
            .themedButton(.secondary, size: .medium)

            Button("Save") {
                // Handle save
            }
            .themedButton(.primary, size: .medium)

            Button("Delete") {
                // Handle delete
            }
            .themedButton(.destructive, size: .medium)
        }
        .themedCard(.low)
    }
}

// MARK: - Themed List Component
struct ThemedListExample: View {
    @Environment(\.theme) private var theme
    @State private var items = [
        ListItem(
            id: 1, title: "First Item", subtitle: "This is the first item", isCompleted: false),
        ListItem(
            id: 2, title: "Second Item", subtitle: "This is the second item", isCompleted: true),
        ListItem(
            id: 3, title: "Third Item", subtitle: "This is the third item", isCompleted: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            // Header
            HStack {
                Text("Themed List")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.text.primary)

                Spacer()

                Button(action: addItem) {
                    Image(systemName: "plus")
                        .iconStyle(color: .accent, size: .medium)
                }
                .themedButton(.ghost, size: .small)
            }

            // List items
            LazyVStack(spacing: theme.spacing.small) {
                ForEach(items) { item in
                    listItemView(item)
                }
            }
        }
        .themedSpacing(.medium)
        .background(theme.colors.background)
    }

    private func listItemView(_ item: ListItem) -> some View {
        HStack(spacing: theme.spacing.medium) {
            // Completion toggle
            Button(action: {
                toggleCompletion(for: item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .iconStyle(
                        color: item.isCompleted ? .success : .secondary,
                        size: .medium
                    )
            }
            .themedButton(.ghost, size: .small)

            // Content
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(item.title)
                    .font(theme.typography.body)
                    .foregroundColor(
                        item.isCompleted ? theme.colors.text.secondary : theme.colors.text.primary
                    )
                    .strikethrough(item.isCompleted)

                Text(item.subtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }

            Spacer()

            // Actions
            HStack(spacing: theme.spacing.xs) {
                Button(action: { editItem(item) }) {
                    Image(systemName: "pencil")
                        .iconStyle(color: .secondary, size: .small)
                }
                .themedButton(.ghost, size: .small)

                Button(action: { deleteItem(item) }) {
                    Image(systemName: "trash")
                        .iconStyle(color: .error, size: .small)
                }
                .themedButton(.ghost, size: .small)
            }
        }
        .themedCard(.low)
        .opacity(item.isCompleted ? 0.7 : 1.0)
        .animation(EmojiAnimations.fade, value: item.isCompleted)
    }

    private func addItem() {
        let newItem = ListItem(
            id: items.count + 1,
            title: "New Item",
            subtitle: "This is a new item",
            isCompleted: false
        )
        withAnimation(EmojiAnimations.popup) {
            items.append(newItem)
        }
    }

    private func toggleCompletion(for item: ListItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            withAnimation(EmojiAnimations.selection) {
                items[index].isCompleted.toggle()
            }
        }
    }

    private func editItem(_ item: ListItem) {
        // Handle edit action
        print("Edit item: \(item.title)")
    }

    private func deleteItem(_ item: ListItem) {
        withAnimation(EmojiAnimations.fade) {
            items.removeAll { $0.id == item.id }
        }
    }
}

// MARK: - Supporting Models
struct ListItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    var isCompleted: Bool
}

// MARK: - Theme Showcase
struct ThemeShowcase: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.large) {
                // Theme selector
                ThemeSettingsView(themeManager: themeManager)

                Divider()
                    .background(theme.colors.border.secondary)

                // Color palette
                colorPalette

                Divider()
                    .background(theme.colors.border.secondary)

                // Typography showcase
                typographyShowcase

                Divider()
                    .background(theme.colors.border.secondary)

                // Component examples
                ThemedComponentExample()

                Divider()
                    .background(theme.colors.border.secondary)

                ThemedListExample()
            }
        }
        .themedSpacing(.medium)
        .background(theme.colors.background)
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("Color Palette")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.text.primary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: theme.spacing.small
            ) {
                colorSwatch("Background", theme.colors.background)
                colorSwatch("Surface", theme.colors.surface)
                colorSwatch("Primary", theme.colors.primary)
                colorSwatch("Accent", theme.colors.accent)
                colorSwatch("Success", theme.colors.semantic.success)
                colorSwatch("Warning", theme.colors.semantic.warning)
                colorSwatch("Error", theme.colors.semantic.error)
                colorSwatch("Info", theme.colors.semantic.info)
            }
        }
        .themedCard(.low)
    }

    private func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: theme.spacing.xs) {
            RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .stroke(theme.colors.border.secondary, lineWidth: 1)
                )

            Text(name)
                .font(theme.typography.caption2)
                .foregroundColor(theme.colors.text.secondary)
        }
    }

    private var typographyShowcase: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            Text("Typography")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.text.primary)

            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Text("Large Title")
                    .font(theme.typography.largeTitle)
                    .foregroundColor(theme.colors.text.primary)

                Text("Title")
                    .font(theme.typography.title)
                    .foregroundColor(theme.colors.text.primary)

                Text("Headline")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.text.primary)

                Text("Subheadline")
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.colors.text.secondary)

                Text(
                    "Body text with multiple lines to demonstrate how the typography looks in longer content sections."
                )
                .font(theme.typography.body)
                .foregroundColor(theme.colors.text.primary)

                Text("Caption text")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }
        }
        .themedCard(.low)
    }
}

// MARK: - Preview
#Preview {
    ThemeShowcase(themeManager: ThemeManager.shared)
        .themedEnvironment(ThemeManager.shared)
}
