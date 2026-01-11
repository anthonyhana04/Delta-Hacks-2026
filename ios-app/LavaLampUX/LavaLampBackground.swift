import SwiftUI

struct LavaLampBackground: View {
    // Configuration for the chaos
    let blobCount = 15
    let colors: [Color] = [
        Color(red: 1.0, green: 0.9, blue: 1.0), // Very Pale Pink
        Color(red: 0.9, green: 1.0, blue: 1.0), // Very Pale Cyan
        Color(red: 0.9, green: 1.0, blue: 0.9), // Very Pale Green
        Color(red: 1.0, green: 1.0, blue: 0.8), // Very Pale Yellow
        Color(red: 0.95, green: 0.9, blue: 1.0) // Very Pale Purple
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // Fill background: Dark Deep Blue/Purple
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.05, green: 0.05, blue: 0.15)))
                
                // Add a "Gooey" blur filter to the entire layer of blobs to make them merge
                // Note: SwiftUI Canvas doesn't support layer filters easily in the same way as CSS.
                // We will render each blob with a blur to simulate softness.
                
                for i in 0..<blobCount {
                    let seed = Double(i) * 13.0
                    
                    // Very slow speed for hypnotic feel
                    // Base speed is extremely low.
                    let speed = 0.008 + (sin(seed * 0.45) + 1.0) * 0.004
                    
                    let sizeBase = size.width * 0.35
                    // Randomize size more
                    let sizeVariation = (cos(seed * 1.2) * 0.3) + 0.9 
                    let blobBaseSize = sizeBase * sizeVariation
                    
                    // Smooth vertical motion
                    let yOffset = (now * speed * size.height) + (seed * 100.0)
                    let yPos = size.height - (yOffset.truncatingRemainder(dividingBy: size.height + blobBaseSize * 2) - blobBaseSize)
                    
                    // Horizontal drift (Sine wave) - Much slower
                    let xFreq = 0.15 + (sin(seed * 0.8) + 1.0) * 0.1
                    let xAmp = size.width * 0.25
                    let xOffset = sin(now * xFreq + seed) * xAmp
                    let xPos = (size.width / 2) + xOffset
                    
                    // Shape morphing: "Squash and Stretch" - Slower breathing
                    let stretch = 1.0 + sin(now * 0.5 + seed) * 0.15 // Height factor
                    let widthFactor = 1.0 + cos(now * 0.4 + seed) * 0.15 // Width factor
                    
                    let currentWidth = blobBaseSize * widthFactor
                    let currentHeight = blobBaseSize * stretch
                    
                    // Color selection
                    let colorIndex = Int(abs(seed).truncatingRemainder(dividingBy: Double(colors.count)))
                    let color = colors[colorIndex]
                    
                    context.drawLayer { ctx in
                        // Blur for the "gooey" connection visual
                        ctx.addFilter(.blur(radius: 50))
                        
                        ctx.translateBy(x: xPos, y: yPos)
                        // Very slow rotation
                        ctx.rotate(by: Angle(degrees: sin(now * 0.2 + seed) * 20))
                        
                        let rect = CGRect(
                            x: -currentWidth / 2,
                            y: -currentHeight / 2,
                            width: currentWidth,
                            height: currentHeight
                        )
                        ctx.fill(Ellipse().path(in: rect), with: .color(color.opacity(0.85)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        // Overlay a refined glass gradients or noise if needed, but keeping it clean for now.
    }
}

struct LavaLampBackground_Previews: PreviewProvider {
    static var previews: some View {
        LavaLampBackground()
    }
}
