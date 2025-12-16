package lib

import (
	"fmt"
	"os"
)

func BuildPublicURL(path string) string {
	return fmt.Sprintf("%s/storage/v1/object/public/%s", os.Getenv("SUPABASE_URL"), path)
}
