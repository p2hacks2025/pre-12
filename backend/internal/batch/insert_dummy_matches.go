package batch

import (
	"context"
	"log"

	"github.com/p2hacks2025/pre-12/backend/internal/service"
)

func InsertDummySwipesAndMatches() {
	ctx := context.Background()

	// マッチさせたいユーザーペア
	pairs := [][]string{
		{"user_001@example.com", "user_002@example.com"},
		{"user_001@example.com", "user_003@example.com"},

		{"user_002@example.com", "user_003@example.com"},
		{"user_002@example.com", "user_004@example.com"},

		{"user_003@example.com", "user_004@example.com"},
		{"user_003@example.com", "user_005@example.com"},

		{"user_004@example.com", "user_005@example.com"},
		{"user_004@example.com", "user_006@example.com"},

		{"user_005@example.com", "user_006@example.com"},
		{"user_005@example.com", "user_007@example.com"},

		{"user_006@example.com", "user_007@example.com"},
		{"user_006@example.com", "user_008@example.com"},

		{"user_007@example.com", "user_008@example.com"},
		{"user_007@example.com", "user_009@example.com"},

		{"user_008@example.com", "user_009@example.com"},
		{"user_008@example.com", "user_010@example.com"},

		{"user_009@example.com", "user_010@example.com"},
		{"user_009@example.com", "user_011@example.com"},

		{"user_010@example.com", "user_011@example.com"},
		{"user_010@example.com", "user_012@example.com"},

		{"user_011@example.com", "user_012@example.com"},
		{"user_011@example.com", "user_013@example.com"},

		{"user_012@example.com", "user_013@example.com"},
		{"user_012@example.com", "user_014@example.com"},

		{"user_013@example.com", "user_014@example.com"},
		{"user_013@example.com", "user_015@example.com"},

		{"user_014@example.com", "user_015@example.com"},
		{"user_014@example.com", "user_016@example.com"},

		{"user_015@example.com", "user_016@example.com"},
		{"user_015@example.com", "user_017@example.com"},

		{"user_016@example.com", "user_017@example.com"},
		{"user_016@example.com", "user_018@example.com"},

		{"user_017@example.com", "user_018@example.com"},
		{"user_017@example.com", "user_019@example.com"},

		{"user_018@example.com", "user_019@example.com"},
		{"user_018@example.com", "user_020@example.com"},

		{"user_019@example.com", "user_020@example.com"},
		{"user_019@example.com", "user_021@example.com"},

		{"user_020@example.com", "user_021@example.com"},
		{"user_020@example.com", "user_022@example.com"},

		{"user_021@example.com", "user_022@example.com"},
		{"user_021@example.com", "user_023@example.com"},

		{"user_022@example.com", "user_023@example.com"},
		{"user_022@example.com", "user_024@example.com"},

		{"user_023@example.com", "user_024@example.com"},
		{"user_023@example.com", "user_025@example.com"},

		{"user_024@example.com", "user_025@example.com"},
		{"user_024@example.com", "user_026@example.com"},

		{"user_025@example.com", "user_026@example.com"},
		{"user_025@example.com", "user_027@example.com"},

		{"user_026@example.com", "user_027@example.com"},
		{"user_026@example.com", "user_028@example.com"},

		{"user_027@example.com", "user_028@example.com"},
		{"user_027@example.com", "user_029@example.com"},

		{"user_028@example.com", "user_029@example.com"},
		{"user_028@example.com", "user_030@example.com"},

		{"user_029@example.com", "user_030@example.com"},
		{"user_029@example.com", "user_031@example.com"},

		{"user_030@example.com", "user_031@example.com"},
		{"user_030@example.com", "user_032@example.com"},

		{"user_031@example.com", "user_032@example.com"},
		{"user_031@example.com", "user_033@example.com"},

		{"user_032@example.com", "user_033@example.com"},
		{"user_032@example.com", "user_034@example.com"},

		{"user_033@example.com", "user_034@example.com"},
		{"user_033@example.com", "user_035@example.com"},

		{"user_034@example.com", "user_035@example.com"},
		{"user_034@example.com", "user_036@example.com"},

		{"user_035@example.com", "user_036@example.com"},
		{"user_035@example.com", "user_037@example.com"},

		{"user_036@example.com", "user_037@example.com"},
		{"user_036@example.com", "user_038@example.com"},

		{"user_037@example.com", "user_038@example.com"},
		{"user_037@example.com", "user_039@example.com"},

		{"user_038@example.com", "user_039@example.com"},
		{"user_038@example.com", "user_040@example.com"},

		{"user_039@example.com", "user_040@example.com"},
		{"user_039@example.com", "user_041@example.com"},

		{"user_040@example.com", "user_041@example.com"},
		{"user_040@example.com", "user_042@example.com"},

		{"user_041@example.com", "user_042@example.com"},
		{"user_041@example.com", "user_043@example.com"},

		{"user_042@example.com", "user_043@example.com"},
		{"user_042@example.com", "user_044@example.com"},

		{"user_043@example.com", "user_044@example.com"},
		{"user_043@example.com", "user_045@example.com"},

		{"user_044@example.com", "user_045@example.com"},
		{"user_044@example.com", "user_046@example.com"},

		{"user_045@example.com", "user_046@example.com"},
		{"user_045@example.com", "user_047@example.com"},

		{"user_046@example.com", "user_047@example.com"},
		{"user_046@example.com", "user_048@example.com"},

		{"user_047@example.com", "user_048@example.com"},
		{"user_047@example.com", "user_049@example.com"},

		{"user_048@example.com", "user_049@example.com"},
		{"user_048@example.com", "user_050@example.com"},

		{"user_049@example.com", "user_050@example.com"},
		{"user_049@example.com", "user_051@example.com"},

		{"user_050@example.com", "user_051@example.com"},
		{"user_050@example.com", "user_052@example.com"},

		{"user_051@example.com", "user_052@example.com"},
		{"user_051@example.com", "user_053@example.com"},

		{"user_052@example.com", "user_053@example.com"},
		{"user_052@example.com", "user_054@example.com"},

		{"user_053@example.com", "user_054@example.com"},
		{"user_053@example.com", "user_055@example.com"},

		{"user_054@example.com", "user_055@example.com"},
		{"user_054@example.com", "user_056@example.com"},

		{"user_055@example.com", "user_056@example.com"},
		{"user_055@example.com", "user_057@example.com"},

		{"user_056@example.com", "user_057@example.com"},
		{"user_056@example.com", "user_058@example.com"},

		{"user_057@example.com", "user_058@example.com"},
		{"user_057@example.com", "user_059@example.com"},

		{"user_058@example.com", "user_059@example.com"},
		{"user_058@example.com", "user_060@example.com"},

		{"user_059@example.com", "user_060@example.com"},
		{"user_059@example.com", "user_061@example.com"},

		{"user_060@example.com", "user_061@example.com"},
		{"user_060@example.com", "user_062@example.com"},

		{"user_061@example.com", "user_062@example.com"},
		{"user_061@example.com", "user_063@example.com"},

		{"user_062@example.com", "user_063@example.com"},
		{"user_062@example.com", "user_064@example.com"},

		{"user_063@example.com", "user_064@example.com"},
		{"user_063@example.com", "user_065@example.com"},

		{"user_064@example.com", "user_065@example.com"},
		{"user_064@example.com", "user_066@example.com"},

		{"user_065@example.com", "user_066@example.com"},
		{"user_065@example.com", "user_067@example.com"},

		{"user_066@example.com", "user_067@example.com"},
		{"user_066@example.com", "user_068@example.com"},

		{"user_067@example.com", "user_068@example.com"},
		{"user_067@example.com", "user_069@example.com"},

		{"user_068@example.com", "user_069@example.com"},
		{"user_068@example.com", "user_070@example.com"},

		{"user_069@example.com", "user_070@example.com"},
		{"user_069@example.com", "user_071@example.com"},

		{"user_070@example.com", "user_071@example.com"},
		{"user_070@example.com", "user_072@example.com"},

		{"user_071@example.com", "user_072@example.com"},
		{"user_071@example.com", "user_073@example.com"},

		{"user_072@example.com", "user_073@example.com"},
		{"user_072@example.com", "user_074@example.com"},

		{"user_073@example.com", "user_074@example.com"},
		{"user_073@example.com", "user_075@example.com"},

		{"user_074@example.com", "user_075@example.com"},
		{"user_074@example.com", "user_076@example.com"},

		{"user_075@example.com", "user_076@example.com"},
		{"user_075@example.com", "user_077@example.com"},

		{"user_076@example.com", "user_077@example.com"},
		{"user_076@example.com", "user_078@example.com"},

		{"user_077@example.com", "user_078@example.com"},
		{"user_077@example.com", "user_079@example.com"},

		{"user_078@example.com", "user_079@example.com"},
		{"user_078@example.com", "user_080@example.com"},

		{"user_079@example.com", "user_080@example.com"},
		{"user_079@example.com", "user_081@example.com"},

		{"user_080@example.com", "user_081@example.com"},
		{"user_080@example.com", "user_082@example.com"},

		{"user_081@example.com", "user_082@example.com"},
		{"user_081@example.com", "user_083@example.com"},

		{"user_082@example.com", "user_083@example.com"},
		{"user_082@example.com", "user_084@example.com"},

		{"user_083@example.com", "user_084@example.com"},
		{"user_083@example.com", "user_085@example.com"},

		{"user_084@example.com", "user_085@example.com"},
		{"user_084@example.com", "user_086@example.com"},

		{"user_085@example.com", "user_086@example.com"},
		{"user_085@example.com", "user_087@example.com"},

		{"user_086@example.com", "user_087@example.com"},
		{"user_086@example.com", "user_088@example.com"},

		{"user_087@example.com", "user_088@example.com"},
		{"user_087@example.com", "user_089@example.com"},

		{"user_088@example.com", "user_089@example.com"},
		{"user_088@example.com", "user_090@example.com"},

		{"user_089@example.com", "user_090@example.com"},
		{"user_089@example.com", "user_091@example.com"},

		{"user_090@example.com", "user_091@example.com"},
		{"user_090@example.com", "user_092@example.com"},

		{"user_091@example.com", "user_092@example.com"},
		{"user_091@example.com", "user_093@example.com"},

		{"user_092@example.com", "user_093@example.com"},
		{"user_092@example.com", "user_094@example.com"},

		{"user_093@example.com", "user_094@example.com"},
		{"user_093@example.com", "user_095@example.com"},

		{"user_094@example.com", "user_095@example.com"},
		{"user_094@example.com", "user_096@example.com"},

		{"user_095@example.com", "user_096@example.com"},
		{"user_095@example.com", "user_097@example.com"},

		{"user_096@example.com", "user_097@example.com"},
		{"user_096@example.com", "user_098@example.com"},

		{"user_097@example.com", "user_098@example.com"},
		{"user_097@example.com", "user_099@example.com"},

		{"user_098@example.com", "user_099@example.com"},
		{"user_098@example.com", "user_100@example.com"},

		{"user_099@example.com", "user_100@example.com"},
		{"user_099@example.com", "user_001@example.com"},

		{"user_100@example.com", "user_001@example.com"},
		{"user_100@example.com", "user_002@example.com"},
	}

	for _, p := range pairs {
		u1 := getUserIDByEmail(ctx, p[0])
		u2 := getUserIDByEmail(ctx, p[1])

		if u1 == "" || u2 == "" {
			log.Println("user not found:", p)
			continue
		}

		w1 := getOneWorkID(ctx, u1)
		w2 := getOneWorkID(ctx, u2)

		if w1 == "" || w2 == "" {
			log.Println("work not found:", p)
			continue
		}

		// u1 -> u2 like
		insertLike(ctx, u1, w2)
		service.CheckAndCreateMatch(u1, w2)

		// u2 -> u1 like（ここでマッチ成立）
		insertLike(ctx, u2, w1)
		service.CheckAndCreateMatch(u2, w1)

		log.Printf("dummy match created: %s <-> %s\n", p[0], p[1])
	}
}
