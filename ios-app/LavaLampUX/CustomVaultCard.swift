import SwiftUI

struct CustomVaultCard: View {
    let vault: CustomVaultCategory
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(vault.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: vault.icon)
                        .foregroundColor(vault.color)
                        .font(.system(size: 20))
                )
            
            // Text
            Text(vault.name)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Count
            Text("\(vault.itemCount)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
