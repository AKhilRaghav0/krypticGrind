//
//  ThemeSelectorSheet.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct ThemeSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedAppearance: ColorScheme?
    
    init() {
        _selectedAppearance = State(initialValue: ThemeManager.shared.colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Large, bold title
                HStack {
                    Text("Appearance")
                        .font(.largeTitle.bold())
                        .padding(.top, 24)
                    Spacer()
                    Button("Done") { 
                        themeManager.colorScheme = selectedAppearance
                        dismiss() 
                    }
                    .fontWeight(.semibold)
                    .padding(.top, 24)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Appearance Mode Selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(.headline)
                                .padding(.horizontal, 8)
                            HStack(spacing: 16) {
                                AppearanceButton(
                                    title: "System",
                                    icon: "circle.lefthalf.filled",
                                    isSelected: selectedAppearance == nil
                                ) {
                                    withAnimation {
                                        selectedAppearance = nil
                                        themeManager.colorScheme = nil
                                    }
                                }
                                AppearanceButton(
                                    title: "Light",
                                    icon: "sun.max.fill",
                                    isSelected: selectedAppearance == .light
                                ) {
                                    withAnimation {
                                        selectedAppearance = .light
                                        themeManager.colorScheme = .light
                                    }
                                }
                                AppearanceButton(
                                    title: "Dark",
                                    icon: "moon.fill",
                                    isSelected: selectedAppearance == .dark
                                ) {
                                    withAnimation {
                                        selectedAppearance = .dark
                                        themeManager.colorScheme = .dark
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct AppearanceButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .blue : .primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Theme Color Preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.colors.accent)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(theme.colors.highlight)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(theme.colors.success)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(theme.colors.warning)
                        .frame(width: 12, height: 12)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                
                // Theme Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(theme.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .onTapGesture {
            // Add haptic feedback manually if needed
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        }
    }
}

#Preview {
    ThemeSelectorSheet()
}
