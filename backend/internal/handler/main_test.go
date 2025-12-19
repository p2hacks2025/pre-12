package handler

import (
	"log"
	"os"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)

	if err := godotenv.Load("../../.env"); err != nil {
		log.Println(".env not found, relying on environment variables")
	}

	db.Init()

	os.Exit(m.Run())
}
