package batch

import (
	"context"
	"log"
	"math/rand"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// InsertDummyReviewsSkipEven は matches からデータを取得し、
// 偶数番目の match では user2 -> user1 をスキップしてダミーレビューを挿入する
func InsertDummyReviewsSkipEven() {
	ctx := context.Background()

	rows, err := db.Pool.Query(ctx, `
		SELECT
			id,
			user1_id,
			user2_id,
			work1_id,
			work2_id
		FROM public.matches
	`)
	if err != nil {
		log.Println("failed to fetch matches:", err)
		return
	}
	defer rows.Close()

	comments := []string{
		"とても素敵なイラストだと思いました。",
		"全体の雰囲気がとても良いですね。",
		"丁寧に描かれているのが伝わってきます。",
		"見ていて心地よいイラストです。",
		"完成度が高いと感じました。",
		"とても印象に残る作品ですね。",
		"全体のバランスが良いと思います。",
		"細かいところまでしっかり描かれていますね。",
		"統一感があって見やすいです。",
		"全体的にとてもきれいな仕上がりです。",

		"作品の雰囲気がよく伝わってきます。",
		"丁寧な作りが感じられるイラストです。",
		"見ていて飽きない作品だと思いました。",
		"安心感のある仕上がりですね。",
		"全体としてとても完成度が高いです。",
		"とても魅力的な作品だと感じました。",
		"じっくり見たくなるイラストです。",
		"落ち着いた印象でとても良いです。",
		"全体のまとまりがあって好印象です。",
		"丁寧さが伝わる作品ですね。",

		"見ていて気持ちが明るくなりました。",
		"とても見やすく、分かりやすいです。",
		"全体的に安心して見られるイラストです。",
		"完成までしっかり仕上げているのが伝わります。",
		"全体の雰囲気が心地よいです。",
		"とても好感の持てる作品ですね。",
		"丁寧な仕上がりが印象的です。",
		"全体としてまとまりが良いと感じました。",
		"見ていて楽しい気持ちになります。",
		"安定感のあるイラストだと思いました。",

		"作品としての完成度が高いですね。",
		"細部まで気を配っているのが伝わります。",
		"とても見やすく仕上がっています。",
		"全体的にバランスの取れた作品です。",
		"安心して楽しめるイラストですね。",
		"丁寧な作業が感じられます。",
		"見ていて心地よい仕上がりです。",
		"全体の雰囲気が整っています。",
		"とてもきれいにまとまっていると思います。",
		"完成度の高さが伝わってきます。",

		"全体としてとても良い印象を受けました。",
		"作品のまとまりがあって素敵です。",
		"丁寧に仕上げられているのが分かります。",
		"落ち着いた雰囲気で好印象です。",
		"全体的にとても安定した作品ですね。",
		"見ていて安心感があります。",
		"完成までしっかり作られていると感じました。",
		"全体の仕上がりがとても良いです。",
		"丁寧さが伝わるイラストだと思います。",
		"とても好印象な作品ですね。",
	}

	i := 0
	for rows.Next() {
		var (
			matchID string
			user1ID string
			user2ID string
			work1ID string
			work2ID string
		)

		if err := rows.Scan(&matchID, &user1ID, &user2ID, &work1ID, &work2ID); err != nil {
			log.Println("scan error:", err)
			continue
		}

		// ランダムコメント取得
		comment1 := comments[rand.Intn(len(comments))]
		comment2 := comments[rand.Intn(len(comments))]

		// user1 -> user2（常に作る）
		insertReview(ctx,
			matchID,
			user1ID,
			user2ID,
			work2ID,
			comment1,
		)

		// 偶数番目はスキップ
		if i%2 == 1 {
			insertReview(ctx,
				matchID,
				user2ID,
				user1ID,
				work1ID,
				comment2,
			)
		}

		log.Println("dummy reviews inserted for match:", matchID)
		i++
	}

	if err := rows.Err(); err != nil {
		log.Println("rows error:", err)
	}
}
