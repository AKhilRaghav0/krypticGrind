//
//  ThemePreviewView.swift
//  KrypticGrind
//
//  Created by akhil on 14/07/25.
//

import SwiftUI

struct ThemePreviewView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedThemeIndex = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose Your Theme")
                            .font(.largeTitle.bold())
                            .foregroundStyle(colorThemeManager.current.text)
                        
                        Text("Pick the perfect theme for your coding journey")
                            .font(.body)
                            .foregroundStyle(colorThemeManager.current.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Theme Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 20) {
                        ForEach(Array(colorThemeManager.themes.enumerated()), id: \.offset) { index, theme in
                            ThemeCard(
                                themeName: theme.name,
                                theme: theme,
                                isSelected: index == selectedThemeIndex,
                                action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        selectedThemeIndex = index
                                        colorThemeManager.setTheme(index: index)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Apply Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            
                            Text("Apply Theme")
                                .font(.headline.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(colorThemeManager.current.accent)
                                .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 10, y: 5)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.bottom, 30)
            }
            .background(colorThemeManager.current.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(colorThemeManager.current.accent)
                    .font(.headline)
                }
            }
        }
        .onAppear {
            selectedThemeIndex = colorThemeManager.currentThemeIndex
        }
    }
}

struct ThemeCard: View {
    let themeName: String
    let theme: ColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme Preview
                VStack(spacing: 8) {
                    // Background + TabBar preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.background)
                            .frame(height: 80)
                        
                        VStack {
                            Spacer()
                            
                            // Tab bar preview
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(theme.tabBar)
                                .frame(height: 20)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                        }
                        
                        // Accent dot
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 8)
                                    .padding(.trailing, 8)
                            }
                            Spacer()
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 3)
                    )
                }
                
                // Theme Info
                VStack(spacing: 4) {
                    Text(themeName)
                        .font(.headline.bold())
                        .foregroundStyle(theme.text)
                    
                    // Color Palette
                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.background)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill(theme.tabBar)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill(theme.text)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.tabBar.opacity(0.9))
                    .shadow(
                        color: isSelected ? theme.accent.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        y: isSelected ? 6 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePreviewView()
        .environmentObject(ColorThemeManager())
}
