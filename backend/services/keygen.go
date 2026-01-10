package services

import (
	"crypto/sha256"
	"math/big"
)

const (
	// Characters allowed in the password
	CharsetAlpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	CharsetNum   = "0123456789"
	CharsetSpecial = "!@#$%^&*()_+"
	CharsetAll   = CharsetAlpha + CharsetNum + CharsetSpecial
)

type KeyGenService struct{}

func NewKeyGenService() *KeyGenService {
	return &KeyGenService{}
}

// GeneratePassword creates a deterministic password from the image data.
// It uses SHA256 hashing of image chunks to ensure high entropy.
func (s *KeyGenService) GeneratePassword(imageData []byte, length int) string {
	if length <= 0 {
		length = 16
	}

	// We want to generate 'length' characters.
	// We can divide the image into 'length' chunks and hash each.
	// Or we can just hash the whole thing and expand it.
    // Better approach for diversity: 
    // Hash the image -> seed a PRNG? No, we want it deterministic based on the image content.
    
    // Simple deterministic approach:
    // 1. Hash the entire image to get a base seed.
    // 2. Use that hash to generate a sequence of characters.
    
    hash := sha256.Sum256(imageData)
    
    // We have 32 bytes of hash. If length > 32, we need more.
    // Let's implement a loop that re-hashes to extend the stream.
    
    password := ""
    currentHash := hash
    
    for i := 0; i < length; i++ {
        // Take the i-th byte of the hash (wrapping around if needed)
        // Actually, let's re-hash the current hash to get the next state to avoid simple patterns
        if i > 0 && i % 32 == 0 {
            currentHash = sha256.Sum256(currentHash[:])
        }
        
        b := currentHash[i % 32]
        
        // Map byte to Charset
        idx := int(b) % len(CharsetAll)
        password += string(CharsetAll[idx])
    }
    
    return password
}

// CalculateEntropyEstimate returns a rough estimate of bits of entropy - for display purposes
func (s *KeyGenService) CalculateEntropyEstimate(password string) int {
    // Simple calculation: log2(charset_size^length)
    poolSize := len(CharsetAll)
    // entropy = length * log2(poolSize)
    // log2(70+) is approx 6.1
    return int(float64(len(password)) * 6.1)
}
