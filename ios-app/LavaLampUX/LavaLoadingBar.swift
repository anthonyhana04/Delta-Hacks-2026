import SwiftUI

struct LavaLoadingBar: View {
    let height: CGFloat = 56
    let color = Color(red: 0, green: 0, blue: 1) // #0000ff
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // 1. Draw Background Pill
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(roundedRect: rect, cornerRadius: height/2), with: .color(Color.black.opacity(0.3)))
                
                // Clip strictly to the pill shape to prevent bleeding at corners
                context.clip(to: Path(roundedRect: rect, cornerRadius: height/2))
                
                // 2. Draw Moving Blobs
                let blobCount = 5
                
                context.drawLayer { ctx in
                    // Soft blur to "connect" the balls together (Metaball-ish)
                    ctx.addFilter(.blur(radius: 12)) 
                    
                    for i in 0..<blobCount {
                        let seed = Double(i) * 13.0
                        
                        // Very slow, viscous movement
                        let speed = 0.15
                        
                        // Large beads to ensure they touch and merge
                        let sizeBase = size.height * 0.9
                        let sizeVariation = (cos(seed * 1.2) * 0.2) + 0.9 
                        let blobBaseSize = sizeBase * sizeVariation
                        
                        // Continuous horizontal flow
                        let xOffset = (now * speed * size.width) + (seed * 50.0)
                        let xPos = (xOffset.truncatingRemainder(dividingBy: size.width + blobBaseSize * 2) - blobBaseSize)
                        
                        // Vertical drift
                        let yFreq = 0.8 + (sin(seed * 0.4) + 1.0) * 0.2
                        let yAmp = size.height * 0.1
                        let yOffset = sin(now * yFreq + seed) * yAmp
                        let yPos = size.height/2 + yOffset
                        
                        // Squash and Stretch
                        let stretch = 1.0 + sin(now * 2.0 + seed) * 0.1
                        let widthFactor = 1.0 + cos(now * 1.8 + seed) * 0.1
                        
                        let currentWidth = blobBaseSize * widthFactor
                        let currentHeight = blobBaseSize * stretch
                        
                        let blobRect = CGRect(
                            x: xPos - currentWidth/2,
                            y: yPos - currentHeight/2,
                            width: currentWidth,
                            height: currentHeight
                        )
                        
                        ctx.fill(Ellipse().path(in: blobRect), with: .color(color))
                    }
                }
            }
        }
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: height/2)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            Text("Generating Entropy...")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 2)
        )
    }
}
