package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/p2hacks2025/pre-12/backend/internal/db"
	"github.com/p2hacks2025/pre-12/backend/internal/handler"
)

func main() {
	godotenv.Load() // これで .env の内容が環境変数として読み込まれる
	// DB 初期化
	db.Init()

	r := gin.Default()

	// Flutter 用 CORS 設定
	r.Use(cors.New(cors.Config{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders: []string{"Origin", "Content-Type", "Authorization"},
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	r.GET("/supabase-health", func(c *gin.Context) {
		c.JSON(200, gin.H{"supabase": "ok"})
	})

	r.GET("/debug/works", handler.DebugGetWorks)

	r.POST("/login", handler.Login)

	r.GET("/works", handler.GetWorks)

	r.POST("/swipe", handler.PostSwipe)

	r.Run(":8080")
}
