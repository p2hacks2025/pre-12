package main

import (
	"log"

	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/batch"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func main() {
	godotenv.Load()
	db.Init()

	log.Println("Creating buckets...")

	// バケットを作成（public: true でアイコンを公開アクセス可能にする）
	if err := batch.CreateBucketIfNotExists("icons", true); err != nil {
		log.Fatal("failed to create icons bucket:", err)
	}

	if err := batch.CreateBucketIfNotExists("works", true); err != nil {
		log.Fatal("failed to create works bucket:", err)
	}

	log.Println("Buckets created, starting batch processes...")

	batch.InsertDummyUsers()
	batch.InsertDummyWorks()
	batch.UploadDefaultIcon()
	batch.UploadIconsFromLocal()
	batch.UploadWorksFromLocal()
	batch.InsertDummySwipesAndMatches()
	//batch.InsertDummyReviews()
	batch.InsertDummyReviewsSkipEven()
}
