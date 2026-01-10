package services

import (
	"crypto/sha256"
)

const (
	CharsetAlpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	CharsetNum   = "0123456789"
	CharsetSpecial = "!@#$%^&*()_+"
	CharsetAll   = CharsetAlpha + CharsetNum + CharsetSpecial
)

type KeyGenService struct{}

func NewKeyGenService() *KeyGenService {
	return &KeyGenService{}
}

func (s *KeyGenService) GeneratePassword(imageData []byte, length int) string {
	if length <= 0 {
		length = 16
	}

    hash := sha256.Sum256(imageData)
    password := ""
    currentHash := hash
    
    for i := 0; i < length; i++ {
        if i > 0 && i % 32 == 0 {
            currentHash = sha256.Sum256(currentHash[:])
        }
        b := currentHash[i % 32]
        idx := int(b) % len(CharsetAll)
        password += string(CharsetAll[idx])
    }
    
    return password
}

func (s *KeyGenService) CalculateEntropyEstimate(password string) int {
    return int(float64(len(password)) * 6.1)
}
