package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"google.golang.org/genai"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found")
	}

	// create gen ai client
	ctx := context.Background()
	// Load API key from environment variable
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		log.Fatal("GEMINI_API_KEY environment variable not set")
	}

	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey: apiKey,
	})
	if err != nil {
		log.Fatal(err)
	}

	// load image - pull from postgress server
	imagePath := "/path/to/your/lava_lamp.jpg"
	imgData, _ := os.ReadFile(imagePath)

	// create prompt - split into parts
	parts := []*genai.Part{
		genai.NewPartFromText("Using the provided image of the lava lamp, please change the background to anything while keeping the lamp. Ensure that all details of the lamp is still visible and unchanged, with only the background being adjusted."),
		&genai.Part{
			InlineData: &genai.Blob{
				MIMEType: "image/jpg",
				Data:     imgData,
			},
		},
	}

	// generate contents
	contents := []*genai.Content{
		genai.NewContentFromParts(parts, genai.RoleUser),
	}

	// model used
	result, _ := client.Models.GenerateContent(
		ctx,
		"gemini-3-pro-image-preview",
		contents,
	)

	// save image back into the DB
	for _, part := range result.Candidates[0].Content.Parts {
		if part.Text != "" {
			fmt.Println(part.Text)
		} else if part.InlineData != nil {
			imageBytes := part.InlineData.Data
			outputFilename := "lava_lamp.jpg"
			_ = os.WriteFile(outputFilename, imageBytes, 0644)
		}
	}
}
