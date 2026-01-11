import SwiftUI
import Combine

struct MFAView: View {
    @Environment(\.selectedTab) var selectedTab
    
    // Core state for the single authenticator
    @State private var timeRemaining: Double = 60.0
    @State private var currentCode: String = "000 000"
    
    // Timer for smooth updates
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Animated Lava Lamp
                LavaLampBackground()
                
                VStack(spacing: 0) {
                    VStack {
                        // Header
                        HStack {
                            Text("Authenticator")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                        
                        Spacer()
                        
                        // Main Clock UI
                        VStack(spacing: 40) {
                            ZStack {
                                // Circular Clock Track
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 15)
                                    .frame(width: 280, height: 280)
                                
                                // Glowing Background for the code
                                Circle()
                                    .fill(timeRemaining < 10 ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .frame(width: 240, height: 240)
                                    .blur(radius: 20)
                                
                                // Dynamic Countdown Ring
                                Circle()
                                    .trim(from: 0, to: timeRemaining / 60.0)
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: timeRemaining < 10 ? [.red, .orange] : [.blue, .cyan]),
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                                    )
                                    .frame(width: 280, height: 280)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.1), value: timeRemaining)
                                    .shadow(color: (timeRemaining < 10 ? Color.red : Color.blue).opacity(0.5), radius: 10)
                                
                                // The 6-Digit Code
                                VStack(spacing: 12) {
                                    Text(currentCode)
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(timeRemaining < 10 ? .red : .white)
                                        .contentTransition(.numericText())
                                    
                                    Text("VALID FOR \(Int(ceil(timeRemaining)))s")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                        .tracking(2)
                                }
                            }
                            
                            // Secondary Info Card
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("Universal General MFA Key")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                            }
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 100) // Space for Dock
                
                // Dock
                VStack {
                    Spacer()
                    DockView(selectedTab: selectedTab)
                }
            }
            .toolbar(.hidden)
            .onAppear {
                generateNewCode()
            }
            .onReceive(timer) { _ in
                handleTimerUpdate()
            }
        }
    }
    
    private func handleTimerUpdate() {
        if timeRemaining > 0 {
            withAnimation(.linear(duration: 0.1)) {
                timeRemaining -= 0.1
            }
        } else {
            timeRemaining = 60.0
            generateNewCode()
        }
    }
    
    private func generateNewCode() {
        let n1 = Int.random(in: 100...999)
        let n2 = Int.random(in: 100...999)
        withAnimation {
            currentCode = "\(n1) \(n2)"
        }
    }
}

struct MFAView_Previews: PreviewProvider {
    static var previews: some View {
        MFAView()
    }
}
