import SwiftUI

struct AccessibilityPermissionDialog: View {
    @Environment(\.theme) private var theme
    let onGrantPermission: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header with icon
            HStack(spacing: 16) {
                Text("🥷")
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ninja Powers Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.text.primary)

                    Text("Enable stealth emoji insertion")
                        .font(.subheadline)
                        .foregroundColor(theme.colors.text.secondary)
                }

                Spacer()
            }

            // Explanation text
            VStack(spacing: 12) {
                Text(
                    "Grant accessibility permission to unleash the full power of Emoji Ninja. This allows instant emoji insertion into any app without the tedious copy-paste dance."
                )
                .font(.body)
                .foregroundColor(theme.colors.text.primary)
                .multilineTextAlignment(.leading)

                Text(
                    "Your ninja will remain silent and focused - this permission is only used for emoji insertion, nothing more."
                )
                .font(.caption)
                .foregroundColor(theme.colors.text.secondary)
                .multilineTextAlignment(.leading)
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 8) {
                PermissionBenefitRow(
                    icon: "bolt.fill",
                    title: "Lightning Fast",
                    description: "Emojis appear instantly in any app"
                )

                PermissionBenefitRow(
                    icon: "command",
                    title: "Ninja Shortcuts",
                    description: "Strike with ⌘⌃Space"
                )

                PermissionBenefitRow(
                    icon: "eye.slash.fill",
                    title: "Stealth Mode",
                    description: "Silent operation, maximum privacy"
                )
            }
            .padding(.vertical, 8)

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onGrantPermission) {
                    HStack {
                        Text("⚙️")
                        Text("Grant Ninja Powers")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.colors.accent)
                    .foregroundColor(theme.colors.text.inverse)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button("Keep Using Clipboard", action: onDismiss)
                    .foregroundColor(theme.colors.text.secondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(theme.colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

struct PermissionBenefitRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.colors.accent)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.text.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    AccessibilityPermissionDialog(
        onGrantPermission: { print("Grant permission") },
        onDismiss: { print("Dismiss") }
    )
    .themedEnvironment(ThemeManager.shared)
}
