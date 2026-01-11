package services

import (
	"context"
	"fmt"

	"google.golang.org/genai"
)

type AIService struct {
	Client *genai.Client
}

func NewAIService(apiKey string) (*AIService, error) {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey: apiKey,
	})
	if err != nil {
		return nil, err
	}
	return &AIService{Client: client}, nil
}

// GenerateWallpaper extends the lava lamp image using Gemini
func (s *AIService) GenerateWallpaper(originalImage []byte) ([]byte, error) {
	if s.Client == nil {
		return nil, fmt.Errorf("AI client not initialized")
	}

	ctx := context.Background()

	parts := []*genai.Part{
		genai.NewPartFromText(`Using the provided image of the lava lamp, please change the photo's background, 
        could be anything, using a variation of colors. Make it look like it's photoshopped in the photo, 
        the photo should look the same in terms of style and angle as the original`),

		&genai.Part{
			InlineData: &genai.Blob{
				MIMEType: "image/jpeg",
				Data:     originalImage,
			},
		},
	}

	contents := []*genai.Content{
		genai.NewContentFromParts(parts, genai.RoleUser),
	}

	// Call Gemini
	// Using gemini-2.5-flash as requested
	temp := float32(0.4)
	config := &genai.GenerateContentConfig{
		MaxOutputTokens: int32(500), // Error said *int32 cannot be used as int32 -> So value.
		Temperature:     &temp,      // Error said float32 canont be used as *float32 -> So pointer.
	}

	result, err := s.Client.Models.GenerateContent(
		ctx,
		"gemini-2.5-flash-image",
		contents,
		config,
	)
	if err != nil {
		return nil, fmt.Errorf("AI generation failed: %w", err)
	}

	// Extract Image
	if len(result.Candidates) > 0 {
		for _, part := range result.Candidates[0].Content.Parts {
			if part.InlineData != nil {
				return part.InlineData.Data, nil
			}
		}
	}

	return nil, fmt.Errorf("no image data in response")
}
