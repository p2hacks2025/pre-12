package handler

import "github.com/gin-gonic/gin"

func setupTestRouter(handlers ...func(*gin.Engine)) *gin.Engine {
	r := gin.Default()
	for _, h := range handlers {
		h(r)
	}
	return r
}

func withSignup(r *gin.Engine) {
	r.POST("/sign-up", Signup)
}

func withLogin(r *gin.Engine) {
	r.POST("/login", Login)
}

func withMe(r *gin.Engine) {
	r.GET("/me", GetMyProfile)
}

func withSwipe(r *gin.Engine) {
	r.POST("/swipe", PostSwipe)
}
