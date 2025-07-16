import SwiftUI

struct FontTestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Font showcase
                Group {
                    Text("TT Phobos Font Test")
                        .font(.ttphobosLargeTitle)
                        .foregroundColor(.primary)
                    
                    Text("Large Title")
                        .font(.ttphobosTitle)
                        .foregroundColor(.secondary)
                    
                    Text("Title 2")
                        .font(.ttphobosTitle2)
                        .foregroundColor(.primary)
                    
                    Text("Headline")
                        .font(.ttphobosHeadline)
                        .foregroundColor(.primary)
                    
                    Text("Body text with TT Phobos font. This is how your problem descriptions will look.")
                        .font(.ttphobosBody)
                        .foregroundColor(.primary)
                    
                    Text("Callout text")
                        .font(.ttphobosCallout)
                        .foregroundColor(.secondary)
                    
                    Text("Caption text")
                        .font(.ttphobosCaption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Icon showcase
                Group {
                    Text("Icon System")
                        .font(.ttphobosTitle2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        AppIcon("magnifyingglass")
                        AppIcon("brain")
                        AppIcon("trophy")
                        AppIcon("star.fill", color: .yellow)
                        AppIcon("bookmark")
                    }
                    
                    HStack(spacing: 20) {
                        AppIcon("video")
                        AppIcon("gearshape")
                        AppIcon("speaker.wave.2")
                        AppIcon("house")
                        AppIcon("chart.line.uptrend.xyaxis")
                    }
                    
                    HStack(spacing: 20) {
                        AppIcon("target")
                        AppIcon("note.text")
                        AppIcon("play.fill")
                        AppIcon("pause.fill")
                        AppIcon("stop.fill")
                    }
                }
                
                Divider()
                
                // Button showcase
                Group {
                    Text("Icon Buttons")
                        .font(.ttphobosTitle2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 15) {
                        IconButton("play.fill") {
                            print("Play tapped")
                        }
                        IconButton("pause.fill") {
                            print("Pause tapped")
                        }
                        IconButton("stop.fill") {
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
                        .font(.ttphobosTitle2)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("1512C - A-B Palindrome")
                                .font(.ttphobosHeadline)
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 4) {
                                AppIcon("star.fill", size: 16, color: .yellow)
                                Text("1200")
                                    .font(.ttphobosCaption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("DP, Greedy")
                            .font(.ttphobosCaption)
                            .foregroundColor(.blue)
                        
                        HStack {
                            IconButton("brain", size: 20) {
                                print("AI Explain tapped")
                            }
                            IconButton("speaker.wave.2", size: 20) {
                                print("Voice Explain tapped")
                            }
                            IconButton("video", size: 20) {
                                print("Generate Video tapped")
                            }
                            Spacer()
                            IconButton("bookmark", size: 20) {
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
