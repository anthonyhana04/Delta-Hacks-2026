import SwiftUI

struct VaultCard: View {
    let item: VaultItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(item.type.color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: item.type.icon)
                        .foregroundColor(item.type.color)
                        .font(.system(size: 20))
                )
            
            // Text
            Text(item.type.rawValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Count
            Text("\(item.itemCount)")
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

struct VaultCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack {
                VaultCard(item: VaultItem(type: .personal, itemCount: 42))
                VaultCard(item: VaultItem(type: .work, itemCount: 12))
            }
            .padding()
        }
    }
}
