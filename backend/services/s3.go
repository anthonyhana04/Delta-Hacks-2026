package services

import (
	"bytes"
	"fmt"
	"io/ioutil"
    "time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

type S3Service struct {
	S3Client *s3.S3
	Bucket   string
}

func NewS3Service(region, bucket string) (*S3Service, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		return nil, err
	}

	return &S3Service{
		S3Client: s3.New(sess),
		Bucket:   bucket,
	}, nil
}

func (s *S3Service) DownloadImage(key string) ([]byte, error) {
	res, err := s.S3Client.GetObject(&s3.GetObjectInput{
		Bucket: aws.String(s.Bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	return ioutil.ReadAll(res.Body)
}

func (s *S3Service) UploadImage(key string, data []byte) (string, error) {
	_, err := s.S3Client.PutObject(&s3.PutObjectInput{
		Bucket:      aws.String(s.Bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String("image/jpeg"),
	})
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("https://%s.s3.amazonaws.com/%s", s.Bucket, key), nil
}

func (s *S3Service) GetLatestLavaLampImage() (string, error) {
    res, err := s.S3Client.ListObjectsV2(&s3.ListObjectsV2Input{
        Bucket: aws.String(s.Bucket),
        Prefix: aws.String("lava_"), 
    })
    if err != nil {
        return "", err
    }
    
    var latestKey string
    var latestTime int64
    
    for _, obj := range res.Contents {
        if obj.LastModified.Unix() > latestTime {
            latestTime = obj.LastModified.Unix()
            latestKey = *obj.Key
        }
    }
    
    if latestKey == "" {
        return "", fmt.Errorf("no images found")
    }
    
    return latestKey, nil
}

// GeneratePresignedGETURL returns a temporary URL to view a private object
func (s *S3Service) GeneratePresignedGETURL(key string) (string, error) {
    req, _ := s.S3Client.GetObjectRequest(&s3.GetObjectInput{
        Bucket: aws.String(s.Bucket),
        Key:    aws.String(key),
    })
    return req.Presign(15 * time.Minute)
}
