import SwiftUI

struct FontTestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Font showcase
                Group {
                    Text("Fabrizio Font Test")
                        .font(.fabrizioLargeTitle)
                        .foregroundColor(.primary)
                    
                    Text("Large Title")
                        .font(.fabrizioTitle)
                        .foregroundColor(.secondary)
                    
                    Text("Title 2")
                        .font(.fabrizioTitle2)
                        .foregroundColor(.primary)
                    
                    Text("Headline")
                        .font(.fabrizioHeadline)
                        .foregroundColor(.primary)
                    
                    Text("Body text with Fabrizio font. This is how your problem descriptions will look.")
                        .font(.fabrizioBody)
                        .foregroundColor(.primary)
                    
                    Text("Callout text")
                        .font(.fabrizioCallout)
                        .foregroundColor(.secondary)
                    
                    Text("Caption text")
                        .font(.fabrizioCaption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Icon showcase
                Group {
                    Text("Icon System")
                        .font(.fabrizioTitle2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        AppIcon(.search, size: 24)
                        AppIcon(.brain, size: 24)
                        AppIcon(.trophy, size: 24)
                        AppIcon(.star, size: 24)
                        AppIcon(.bookmark, size: 24)
                    }
                    
                    HStack(spacing: 20) {
                        AppIcon(.video, size: 24)
                        AppIcon(.gear, size: 24)
                        AppIcon(.speaker, size: 24)
                        AppIcon(.house, size: 24)
                        AppIcon(.chart, size: 24)
                    }
                    
                    HStack(spacing: 20) {
                        AppIcon(.target, size: 24)
                        AppIcon(.note, size: 24)
                        AppIcon(.play, size: 24)
                        AppIcon(.pause, size: 24)
                        AppIcon(.stop, size: 24)
                    }
                }
                
                Divider()
                
                // Button showcase
                Group {
                    Text("Icon Buttons")
                        .font(.fabrizioTitle2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 15) {
                        IconButton(.play, size: 24) {
                            print("Play tapped")
                        }
                        
                        IconButton(.pause, size: 24) {
                            print("Pause tapped")
                        }
                        
                        IconButton(.stop, size: 24) {
                            print("Stop tapped")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Divider()
                
                // Sample CP problem card
                Group {
                    Text("Sample Problem Card")
                        .font(.fabrizioTitle2)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("1512C - A-B Palindrome")
                                .font(.fabrizioHeadline)
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 4) {
                                AppIcon(.star, size: 16, color: .yellow)
                                Text("1200")
                                    .font(.fabrizioCaption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("DP, Greedy")
                            .font(.fabrizioCaption)
                            .foregroundColor(.blue)
                        
                        HStack {
                            IconButton(.brain, size: 20) {
                                print("AI Explain tapped")
                            }
                            
                            IconButton(.speaker, size: 20) {
                                print("Voice Explain tapped")
                            }
                            
                            IconButton(.video, size: 20) {
                                print("Generate Video tapped")
                            }
                            
                            Spacer()
                            
                            IconButton(.bookmark, size: 20) {
                                print("Save tapped")
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Font & Icon Test")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        FontTestView()
    }
} 