package main

import (
	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/batch"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func main() {
	godotenv.Load()
	db.Init()

	batch.InsertDummyUsers()
	batch.InsertDummyWorks()
	batch.UploadIconsFromLocal()
	batch.UploadWorksFromLocal()
}
