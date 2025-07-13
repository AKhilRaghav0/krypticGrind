//
//  ThemeSelectorSheet.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct ThemeSelectorSheet: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    
    private let themeNames = ["Ocean", "Sunset", "Forest", "Cosmic", "Minimal"]
    
    var body: some View {
        NavigationView {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Choose Theme")
                        .font(.title2.bold())
                        .foregroundColor(colorThemeManager.current.text)
                        .padding(.top)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(themeNames.enumerated()), id: \.offset) { index, name in
                            ThemeCard(
                                themeName: name,
                                isSelected: index == colorThemeManager.currentThemeIndex,
                                action: {
                                    withAnimation(.spring()) {
                                        colorThemeManager.setTheme(index: index)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                }
            }
        }
    }
}

struct ThemeCard: View {
    let themeName: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme preview
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorThemeManager.current.background)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .fill(colorThemeManager.current.accent)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .fill(colorThemeManager.current.tabBar)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .fill(colorThemeManager.current.text)
                        .frame(width: 16, height: 16)
                }
                
                Text(themeName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(colorThemeManager.current.text)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorThemeManager.current.tabBar)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? colorThemeManager.current.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    ThemeSelectorSheet()
        .environmentObject(ColorThemeManager())
}
