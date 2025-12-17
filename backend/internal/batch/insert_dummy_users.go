package batch

import (
	"context"
	"log"
	"strings"

	"github.com/p2hacks2025/pre-12/backend/internal/db"
)

// InsertDummyUsers は users テーブルにダミーデータを挿入する関数
func InsertDummyUsers() {
	users := []struct {
		Username string
		Email    string
		Password string
		IconFile string // ファイル名だけ
		Bio      string
	}{
		{"sakura_illust", "user_001@example.com", "ChangeMe-CommonPassword-2025!", "user_001.png", "ある日、人物の美しさに心が奪われたことがきっかけで 都市と自然の共存をテーマに掲げ 細部にこだわりながら全体の調和を大切にし色と光が重なり合い、人物の姿が抽象的に浮かび上がっている。"},
		{"ゆきのん", "user_002@example.com", "ChangeMe-CommonPassword-2025!", "user_002.png", "森の中で光が揺らぐ瞬間を見て 忘れかけていた感覚を形として残したいと思い 筆致や色の重なりを何度も調整し透き通るような色合いで表現された風景が、きらきらとしたハイライトに包まれている。"},
		{"aoi_canvas", "user_003@example.com", "ChangeMe-CommonPassword-2025!", "user_003.png", "森の中で光が揺らぐ瞬間を見て 都市と自然の共存をテーマに掲げ 色彩のグラデーションで奥行きを生み出し中心の抽象を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"みずいろ絵師", "user_004@example.com", "ChangeMe-CommonPassword-2025!", "user_004.png", "森の中で光が揺らぐ瞬間を見て 見る人に物語を感じてもらいたくて 光の反射を表現するためにメディウムを工夫し色と光が重なり合い、静物の姿が抽象的に浮かび上がっている。"},
		{"hana_draw", "user_005@example.com", "ChangeMe-CommonPassword-2025!", "user_005.png", "遠い記憶の断片を呼び覚ますように この作品で都市夜景に潜む美しさを伝えたいと考え 色彩のグラデーションで奥行きを生み出し遠くに都市夜景が霞み、手前には輝く反射が踊っている。"},
		{"ねこまる。", "user_006@example.com", "ChangeMe-CommonPassword-2025!", "user_006.png", "都会の喧騒の中でふと感じた静寂から 自分の内なる感情をキャンバスに映し出そうと決意し 粒子のような表現で輝きを散りばめ絵全体に散りばめられた光の点が海を引き立て、奥行きを感じさせる。"},
		{"kitsune_art", "user_007@example.com", "ChangeMe-CommonPassword-2025!", "user_007.png", "夕暮れの海を眺めていたときに感じた切なさから 抽象的な概念を色で表そうと試み 構図を変えながら最も心に響く形を模索し色と光が重なり合い、森の姿が抽象的に浮かび上がっている。"},
		{"そらのパレット", "user_008@example.com", "ChangeMe-CommonPassword-2025!", "user_008.png", "光と影のコントラストに心を寄せて 抽象的な概念を色で表そうと試み 透明感を出すために淡い色彩を選び絵全体に散りばめられた光の点が雨を引き立て、奥行きを感じさせる。"},
		{"mochi_creator", "user_009@example.com", "ChangeMe-CommonPassword-2025!", "user_009.png", "雨上がりの空気にインスパイアされて 移り行く時間の流れを捉えたいという思いから 構図を変えながら最も心に響く形を模索し透き通るような色合いで表現された光が、きらきらとしたハイライトに包まれている。"},
		{"つきよみ", "user_010@example.com", "ChangeMe-CommonPassword-2025!", "user_010.png", "季節の移ろいに心が動かされて 忘れかけていた感覚を形として残したいと思い 色彩のグラデーションで奥行きを生み出し淡い色彩の中に光が滲み、季節の輪郭が柔らかく溶け込んでいる。"},
		{"kumo_sketch", "user_011@example.com", "ChangeMe-CommonPassword-2025!", "user_011.png", "都会の喧騒の中でふと感じた静寂から この作品で人物に潜む美しさを伝えたいと考え 色彩のグラデーションで奥行きを生み出し遠くに人物が霞み、手前には輝く反射が踊っている。"},
		{"りんご飴", "user_012@example.com", "ChangeMe-CommonPassword-2025!", "user_012.png", "ある日、風景の美しさに心が奪われたことがきっかけで 自然の持つ力強さと儚さを表したいと願い 細部にこだわりながら全体の調和を大切にし絵全体に散りばめられた光の点が風景を引き立て、奥行きを感じさせる。"},
		{"tsubaki_design", "user_013@example.com", "ChangeMe-CommonPassword-2025!", "user_013.png", "都会の喧騒の中でふと感じた静寂から 見る人に物語を感じてもらいたくて 光の反射を表現するためにメディウムを工夫し淡い色彩の中に光が滲み、抽象の輪郭が柔らかく溶け込んでいる。"},
		{"ふわもこ絵描き", "user_014@example.com", "ChangeMe-CommonPassword-2025!", "user_014.png", "抽象的な感情を形にしたくて 静と動のバランスを探求し 粒子のような表現で輝きを散りばめ柔らかな陰影の中に静物が佇み、光のきらめきが寄り添っている。"},
		{"natsumi_works", "user_015@example.com", "ChangeMe-CommonPassword-2025!", "user_015.png", "季節の移ろいに心が動かされて 忘れかけていた感覚を形として残したいと思い 筆致や色の重なりを何度も調整し透き通るような色合いで表現された都市夜景が、きらきらとしたハイライトに包まれている。"},
		{"こはる", "user_016@example.com", "ChangeMe-CommonPassword-2025!", "user_016.png", "森の中で光が揺らぐ瞬間を見て この作品で海に潜む美しさを伝えたいと考え 筆致や色の重なりを何度も調整し柔らかな陰影の中に海が佇み、光のきらめきが寄り添っている。"},
		{"yume_palette", "user_017@example.com", "ChangeMe-CommonPassword-2025!", "user_017.png", "夕暮れの海を眺めていたときに感じた切なさから 自然の持つ力強さと儚さを表したいと願い 構図を変えながら最も心に響く形を模索し中心の森を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"あおぞら工房", "user_018@example.com", "ChangeMe-CommonPassword-2025!", "user_018.png", "森の中で光が揺らぐ瞬間を見て 見る人に物語を感じてもらいたくて 粒子のような表現で輝きを散りばめ淡い色彩の中に光が滲み、雨の輪郭が柔らかく溶け込んでいる。"},
		{"hoshi_maker", "user_019@example.com", "ChangeMe-CommonPassword-2025!", "user_019.png", "都会の喧騒の中でふと感じた静寂から 光のきらめきを表現することで希望を描こうと思い 筆致や色の重なりを何度も調整し淡い色彩の中に光が滲み、光の輪郭が柔らかく溶け込んでいる。"},
		{"ぴよぴよ画伯", "user_020@example.com", "ChangeMe-CommonPassword-2025!", "user_020.png", "森の中で光が揺らぐ瞬間を見て 見る人に物語を感じてもらいたくて 粒子のような表現で輝きを散りばめキャンバスには季節とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"umi_illustration", "user_021@example.com", "ChangeMe-CommonPassword-2025!", "user_021.png", "光と影のコントラストに心を寄せて 自分の内なる感情をキャンバスに映し出そうと決意し 光の反射を表現するためにメディウムを工夫し柔らかな陰影の中に人物が佇み、光のきらめきが寄り添っている。"},
		{"まるまる屋", "user_022@example.com", "ChangeMe-CommonPassword-2025!", "user_022.png", "季節の移ろいに心が動かされて 忘れかけていた感覚を形として残したいと思い 細部にこだわりながら全体の調和を大切にし遠くに風景が霞み、手前には輝く反射が踊っている。"},
		{"kaze_studio", "user_023@example.com", "ChangeMe-CommonPassword-2025!", "user_023.png", "遠い記憶の断片を呼び覚ますように 抽象的な概念を色で表そうと試み 色彩のグラデーションで奥行きを生み出し静かな背景に輝く粒子が舞い、抽象の存在感を際立たせている。"},
		{"ひなたぼっこ", "user_024@example.com", "ChangeMe-CommonPassword-2025!", "user_024.png", "遠い記憶の断片を呼び覚ますように 静と動のバランスを探求し 何層にも絵の具を重ねて質感を出し透き通るような色合いで表現された静物が、きらきらとしたハイライトに包まれている。"},
		{"aki_artworks", "user_025@example.com", "ChangeMe-CommonPassword-2025!", "user_025.png", "季節の移ろいに心が動かされて 光のきらめきを表現することで希望を描こうと思い 透明感を出すために淡い色彩を選びキャンバスには都市夜景とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"もふもふ絵師", "user_026@example.com", "ChangeMe-CommonPassword-2025!", "user_026.png", "雨上がりの空気にインスパイアされて 移り行く時間の流れを捉えたいという思いから 細部にこだわりながら全体の調和を大切にし遠くに海が霞み、手前には輝く反射が踊っている。"},
		{"midori_draws", "user_027@example.com", "ChangeMe-CommonPassword-2025!", "user_027.png", "ある日、森の美しさに心が奪われたことがきっかけで 都市と自然の共存をテーマに掲げ 透明感を出すために淡い色彩を選び中心の森を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"しずく", "user_028@example.com", "ChangeMe-CommonPassword-2025!", "user_028.png", "雨上がりの空気にインスパイアされて 忘れかけていた感覚を形として残したいと思い 筆致や色の重なりを何度も調整し中心の雨を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"usagi_creator", "user_029@example.com", "ChangeMe-CommonPassword-2025!", "user_029.png", "光と影のコントラストに心を寄せて 移り行く時間の流れを捉えたいという思いから 細部にこだわりながら全体の調和を大切にしキャンバスには光とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"からあげ先生", "user_030@example.com", "ChangeMe-CommonPassword-2025!", "user_030.png", "ある日、季節の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 光の反射を表現するためにメディウムを工夫しゆらめく光の中に季節が浮かび上がり、幻想的な雰囲気を醸し出している。"},
		{"shiori_art", "user_031@example.com", "ChangeMe-CommonPassword-2025!", "user_031.png", "ある日、人物の美しさに心が奪われたことがきっかけで 抽象的な概念を色で表そうと試み 細部にこだわりながら全体の調和を大切にし色と光が重なり合い、人物の姿が抽象的に浮かび上がっている。"},
		{"ぽんず", "user_032@example.com", "ChangeMe-CommonPassword-2025!", "user_032.png", "季節の移ろいに心が動かされて 移り行く時間の流れを捉えたいという思いから 粒子のような表現で輝きを散りばめ透き通るような色合いで表現された風景が、きらきらとしたハイライトに包まれている。"},
		{"tanuki_studio", "user_033@example.com", "ChangeMe-CommonPassword-2025!", "user_033.png", "光と影のコントラストに心を寄せて 自分の内なる感情をキャンバスに映し出そうと決意し 繊細なタッチで空気感を表現しゆらめく光の中に抽象が浮かび上がり、幻想的な雰囲気を醸し出している。"},
		{"きなこもち", "user_034@example.com", "ChangeMe-CommonPassword-2025!", "user_034.png", "森の中で光が揺らぐ瞬間を見て 自分の内なる感情をキャンバスに映し出そうと決意し 筆致や色の重なりを何度も調整し色と光が重なり合い、静物の姿が抽象的に浮かび上がっている。"},
		{"sora_illustration", "user_035@example.com", "ChangeMe-CommonPassword-2025!", "user_035.png", "光と影のコントラストに心を寄せて 自分の内なる感情をキャンバスに映し出そうと決意し 筆致や色の重なりを何度も調整し遠くに都市夜景が霞み、手前には輝く反射が踊っている。"},
		{"にゃんこ画伯", "user_036@example.com", "ChangeMe-CommonPassword-2025!", "user_036.png", "光と影のコントラストに心を寄せて 光のきらめきを表現することで希望を描こうと思い 細部にこだわりながら全体の調和を大切にし透き通るような色合いで表現された海が、きらきらとしたハイライトに包まれている。"},
		{"hikari_design", "user_037@example.com", "ChangeMe-CommonPassword-2025!", "user_037.png", "抽象的な感情を形にしたくて 忘れかけていた感覚を形として残したいと思い 細部にこだわりながら全体の調和を大切にし絵全体に散りばめられた光の点が森を引き立て、奥行きを感じさせる。"},
		{"まったり絵描き", "user_038@example.com", "ChangeMe-CommonPassword-2025!", "user_038.png", "ある日、雨の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 粒子のような表現で輝きを散りばめキャンバスには雨とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"neko_creator", "user_039@example.com", "ChangeMe-CommonPassword-2025!", "user_039.png", "森の中で光が揺らぐ瞬間を見て 移り行く時間の流れを捉えたいという思いから 光の反射を表現するためにメディウムを工夫しキャンバスには光とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"あんみつ", "user_040@example.com", "ChangeMe-CommonPassword-2025!", "user_040.png", "ある日、季節の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 何層にも絵の具を重ねて質感を出し色と光が重なり合い、季節の姿が抽象的に浮かび上がっている。"},
		{"fuji_artworks", "user_041@example.com", "ChangeMe-CommonPassword-2025!", "user_041.png", "抽象的な感情を形にしたくて 自分の内なる感情をキャンバスに映し出そうと決意し 透明感を出すために淡い色彩を選び透き通るような色合いで表現された人物が、きらきらとしたハイライトに包まれている。"},
		{"ころもち", "user_042@example.com", "ChangeMe-CommonPassword-2025!", "user_042.png", "夕暮れの海を眺めていたときに感じた切なさから 自分の内なる感情をキャンバスに映し出そうと決意し 構図を変えながら最も心に響く形を模索し遠くに風景が霞み、手前には輝く反射が踊っている。"},
		{"yuki_canvas", "user_043@example.com", "ChangeMe-CommonPassword-2025!", "user_043.png", "夕暮れの海を眺めていたときに感じた切なさから 忘れかけていた感覚を形として残したいと思い 何層にも絵の具を重ねて質感を出し中心の抽象を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"おだんご屋", "user_044@example.com", "ChangeMe-CommonPassword-2025!", "user_044.png", "都会の喧騒の中でふと感じた静寂から 見る人に物語を感じてもらいたくて 筆致や色の重なりを何度も調整し静かな背景に輝く粒子が舞い、静物の存在感を際立たせている。"},
		{"tori_illustration", "user_045@example.com", "ChangeMe-CommonPassword-2025!", "user_045.png", "雨上がりの空気にインスパイアされて この作品で都市夜景に潜む美しさを伝えたいと考え 粒子のような表現で輝きを散りばめ絵全体に散りばめられた光の点が都市夜景を引き立て、奥行きを感じさせる。"},
		{"みたらし", "user_046@example.com", "ChangeMe-CommonPassword-2025!", "user_046.png", "森の中で光が揺らぐ瞬間を見て 都市と自然の共存をテーマに掲げ 筆致や色の重なりを何度も調整し遠くに海が霞み、手前には輝く反射が踊っている。"},
		{"haru_studio", "user_047@example.com", "ChangeMe-CommonPassword-2025!", "user_047.png", "雨上がりの空気にインスパイアされて 忘れかけていた感覚を形として残したいと思い 筆致や色の重なりを何度も調整し中心の森を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"ぽかぽか絵師", "user_048@example.com", "ChangeMe-CommonPassword-2025!", "user_048.png", "ある日、雨の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 何層にも絵の具を重ねて質感を出し絵全体に散りばめられた光の点が雨を引き立て、奥行きを感じさせる。"},
		{"sakana_art", "user_049@example.com", "ChangeMe-CommonPassword-2025!", "user_049.png", "森の中で光が揺らぐ瞬間を見て 移り行く時間の流れを捉えたいという思いから 何層にも絵の具を重ねて質感を出し淡い色彩の中に光が滲み、光の輪郭が柔らかく溶け込んでいる。"},
		{"わたあめ", "user_050@example.com", "ChangeMe-CommonPassword-2025!", "user_050.png", "季節の移ろいに心が動かされて 忘れかけていた感覚を形として残したいと思い 筆致や色の重なりを何度も調整しキャンバスには季節とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"mizu_creator", "user_051@example.com", "ChangeMe-CommonPassword-2025!", "user_051.png", "都会の喧騒の中でふと感じた静寂から 見る人に物語を感じてもらいたくて 粒子のような表現で輝きを散りばめ静かな背景に輝く粒子が舞い、人物の存在感を際立たせている。"},
		{"たいやき工房", "user_052@example.com", "ChangeMe-CommonPassword-2025!", "user_052.png", "森の中で光が揺らぐ瞬間を見て 光のきらめきを表現することで希望を描こうと思い 色彩のグラデーションで奥行きを生み出し淡い色彩の中に光が滲み、風景の輪郭が柔らかく溶け込んでいる。"},
		{"yoru_design", "user_053@example.com", "ChangeMe-CommonPassword-2025!", "user_053.png", "雨上がりの空気にインスパイアされて 自分の内なる感情をキャンバスに映し出そうと決意し 何層にも絵の具を重ねて質感を出し中心の抽象を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"くるみ", "user_054@example.com", "ChangeMe-CommonPassword-2025!", "user_054.png", "都会の喧騒の中でふと感じた静寂から 忘れかけていた感覚を形として残したいと思い 構図を変えながら最も心に響く形を模索し柔らかな陰影の中に静物が佇み、光のきらめきが寄り添っている。"},
		{"take_illustration", "user_055@example.com", "ChangeMe-CommonPassword-2025!", "user_055.png", "季節の移ろいに心が動かされて 光のきらめきを表現することで希望を描こうと思い 色彩のグラデーションで奥行きを生み出し静かな背景に輝く粒子が舞い、都市夜景の存在感を際立たせている。"},
		{"ゆめかわ絵描き", "user_056@example.com", "ChangeMe-CommonPassword-2025!", "user_056.png", "森の中で光が揺らぐ瞬間を見て 都市と自然の共存をテーマに掲げ 試行錯誤しながら光と影のバランスを探り中心の海を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"inu_artworks", "user_057@example.com", "ChangeMe-CommonPassword-2025!", "user_057.png", "夜空の光に魅せられて この作品で森に潜む美しさを伝えたいと考え 色彩のグラデーションで奥行きを生み出しキャンバスには森とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"あずき", "user_058@example.com", "ChangeMe-CommonPassword-2025!", "user_058.png", "ある日、雨の美しさに心が奪われたことがきっかけで 光のきらめきを表現することで希望を描こうと思い 試行錯誤しながら光と影のバランスを探り透き通るような色合いで表現された雨が、きらきらとしたハイライトに包まれている。"},
		{"natsu_canvas", "user_059@example.com", "ChangeMe-CommonPassword-2025!", "user_059.png", "季節の移ろいに心が動かされて この作品で光に潜む美しさを伝えたいと考え 粒子のような表現で輝きを散りばめ中心の光を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"ほのぼの屋", "user_060@example.com", "ChangeMe-CommonPassword-2025!", "user_060.png", "抽象的な感情を形にしたくて 見る人に物語を感じてもらいたくて 筆致や色の重なりを何度も調整し遠くに季節が霞み、手前には輝く反射が踊っている。"},
		{"kuma_studio", "user_061@example.com", "ChangeMe-CommonPassword-2025!", "user_061.png", "夜空の光に魅せられて 自然の持つ力強さと儚さを表したいと願い 粒子のような表現で輝きを散りばめ静かな背景に輝く粒子が舞い、人物の存在感を際立たせている。"},
		{"すみれ", "user_062@example.com", "ChangeMe-CommonPassword-2025!", "user_062.png", "抽象的な感情を形にしたくて 自然の持つ力強さと儚さを表したいと願い 粒子のような表現で輝きを散りばめ静かな背景に輝く粒子が舞い、風景の存在感を際立たせている。"},
		{"tsuki_creator", "user_063@example.com", "ChangeMe-CommonPassword-2025!", "user_063.png", "抽象的な感情を形にしたくて 忘れかけていた感覚を形として残したいと思い 光の反射を表現するためにメディウムを工夫し淡い色彩の中に光が滲み、抽象の輪郭が柔らかく溶け込んでいる。"},
		{"ふんわり絵師", "user_064@example.com", "ChangeMe-CommonPassword-2025!", "user_064.png", "遠い記憶の断片を呼び覚ますように 見る人に物語を感じてもらいたくて 透明感を出すために淡い色彩を選び柔らかな陰影の中に静物が佇み、光のきらめきが寄り添っている。"},
		{"suzume_art", "user_065@example.com", "ChangeMe-CommonPassword-2025!", "user_065.png", "光と影のコントラストに心を寄せて 抽象的な概念を色で表そうと試み 構図を変えながら最も心に響く形を模索し透き通るような色合いで表現された都市夜景が、きらきらとしたハイライトに包まれている。"},
		{"もみじ", "user_066@example.com", "ChangeMe-CommonPassword-2025!", "user_066.png", "雨上がりの空気にインスパイアされて 忘れかけていた感覚を形として残したいと思い 細部にこだわりながら全体の調和を大切にし色と光が重なり合い、海の姿が抽象的に浮かび上がっている。"},
		{"ame_design", "user_067@example.com", "ChangeMe-CommonPassword-2025!", "user_067.png", "遠い記憶の断片を呼び覚ますように 自分の内なる感情をキャンバスに映し出そうと決意し 粒子のような表現で輝きを散りばめ柔らかな陰影の中に森が佇み、光のきらめきが寄り添っている。"},
		{"さくらんぼ", "user_068@example.com", "ChangeMe-CommonPassword-2025!", "user_068.png", "雨上がりの空気にインスパイアされて 移り行く時間の流れを捉えたいという思いから 透明感を出すために淡い色彩を選び柔らかな陰影の中に雨が佇み、光のきらめきが寄り添っている。"},
		{"kawa_illustration", "user_069@example.com", "ChangeMe-CommonPassword-2025!", "user_069.png", "抽象的な感情を形にしたくて 光のきらめきを表現することで希望を描こうと思い 細部にこだわりながら全体の調和を大切にし静かな背景に輝く粒子が舞い、光の存在感を際立たせている。"},
		{"とろろ画伯", "user_070@example.com", "ChangeMe-CommonPassword-2025!", "user_070.png", "ある日、季節の美しさに心が奪われたことがきっかけで 忘れかけていた感覚を形として残したいと思い 何層にも絵の具を重ねて質感を出し静かな背景に輝く粒子が舞い、季節の存在感を際立たせている。"},
		{"hato_works", "user_071@example.com", "ChangeMe-CommonPassword-2025!", "user_071.png", "ある日、人物の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 筆致や色の重なりを何度も調整し静かな背景に輝く粒子が舞い、人物の存在感を際立たせている。"},
		{"いちご", "user_072@example.com", "ChangeMe-CommonPassword-2025!", "user_072.png", "ある日、風景の美しさに心が奪われたことがきっかけで この作品で風景に潜む美しさを伝えたいと考え 構図を変えながら最も心に響く形を模索し柔らかな陰影の中に風景が佇み、光のきらめきが寄り添っている。"},
		{"niwa_artworks", "user_073@example.com", "ChangeMe-CommonPassword-2025!", "user_073.png", "遠い記憶の断片を呼び覚ますように 静と動のバランスを探求し 筆致や色の重なりを何度も調整し絵全体に散りばめられた光の点が抽象を引き立て、奥行きを感じさせる。"},
		{"ほっこり絵描き", "user_074@example.com", "ChangeMe-CommonPassword-2025!", "user_074.png", "森の中で光が揺らぐ瞬間を見て 光のきらめきを表現することで希望を描こうと思い 繊細なタッチで空気感を表現し透き通るような色合いで表現された静物が、きらきらとしたハイライトに包まれている。"},
		{"karasu_studio", "user_075@example.com", "ChangeMe-CommonPassword-2025!", "user_075.png", "雨上がりの空気にインスパイアされて 静と動のバランスを探求し 細部にこだわりながら全体の調和を大切にし絵全体に散りばめられた光の点が都市夜景を引き立て、奥行きを感じさせる。"},
		{"かりん", "user_076@example.com", "ChangeMe-CommonPassword-2025!", "user_076.png", "遠い記憶の断片を呼び覚ますように 移り行く時間の流れを捉えたいという思いから 粒子のような表現で輝きを散りばめ遠くに海が霞み、手前には輝く反射が踊っている。"},
		{"shiro_creator", "user_077@example.com", "ChangeMe-CommonPassword-2025!", "user_077.png", "夕暮れの海を眺めていたときに感じた切なさから この作品で森に潜む美しさを伝えたいと考え 試行錯誤しながら光と影のバランスを探り静かな背景に輝く粒子が舞い、森の存在感を際立たせている。"},
		{"ぬくぬく工房", "user_078@example.com", "ChangeMe-CommonPassword-2025!", "user_078.png", "遠い記憶の断片を呼び覚ますように 忘れかけていた感覚を形として残したいと思い 粒子のような表現で輝きを散りばめ柔らかな陰影の中に雨が佇み、光のきらめきが寄り添っている。"},
		{"koi_illustration", "user_079@example.com", "ChangeMe-CommonPassword-2025!", "user_079.png", "光と影のコントラストに心を寄せて この作品で光に潜む美しさを伝えたいと考え 透明感を出すために淡い色彩を選び淡い色彩の中に光が滲み、光の輪郭が柔らかく溶け込んでいる。"},
		{"あんこ", "user_080@example.com", "ChangeMe-CommonPassword-2025!", "user_080.png", "森の中で光が揺らぐ瞬間を見て 光のきらめきを表現することで希望を描こうと思い 筆致や色の重なりを何度も調整しゆらめく光の中に季節が浮かび上がり、幻想的な雰囲気を醸し出している。"},
		{"yama_design", "user_081@example.com", "ChangeMe-CommonPassword-2025!", "user_081.png", "季節の移ろいに心が動かされて 見る人に物語を感じてもらいたくて 繊細なタッチで空気感を表現し柔らかな陰影の中に人物が佇み、光のきらめきが寄り添っている。"},
		{"のんびり屋", "user_082@example.com", "ChangeMe-CommonPassword-2025!", "user_082.png", "季節の移ろいに心が動かされて 静と動のバランスを探求し 粒子のような表現で輝きを散りばめ透き通るような色合いで表現された風景が、きらきらとしたハイライトに包まれている。"},
		{"tsuyu_art", "user_083@example.com", "ChangeMe-CommonPassword-2025!", "user_083.png", "抽象的な感情を形にしたくて 移り行く時間の流れを捉えたいという思いから 構図を変えながら最も心に響く形を模索し柔らかな陰影の中に抽象が佇み、光のきらめきが寄り添っている。"},
		{"まめ", "user_084@example.com", "ChangeMe-CommonPassword-2025!", "user_084.png", "ある日、静物の美しさに心が奪われたことがきっかけで 光のきらめきを表現することで希望を描こうと思い 試行錯誤しながら光と影のバランスを探り淡い色彩の中に光が滲み、静物の輪郭が柔らかく溶け込んでいる。"},
		{"kiri_canvas", "user_085@example.com", "ChangeMe-CommonPassword-2025!", "user_085.png", "ある日、都市夜景の美しさに心が奪われたことがきっかけで 自分の内なる感情をキャンバスに映し出そうと決意し 繊細なタッチで空気感を表現し中心の都市夜景を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"ころころ絵師", "user_086@example.com", "ChangeMe-CommonPassword-2025!", "user_086.png", "遠い記憶の断片を呼び覚ますように 抽象的な概念を色で表そうと試み 構図を変えながら最も心に響く形を模索し中心の海を囲むように光が渦巻き、エネルギーが溢れているようだ。"},
		{"kaede_studio", "user_087@example.com", "ChangeMe-CommonPassword-2025!", "user_087.png", "夕暮れの海を眺めていたときに感じた切なさから 光のきらめきを表現することで希望を描こうと思い 色彩のグラデーションで奥行きを生み出し透き通るような色合いで表現された森が、きらきらとしたハイライトに包まれている。"},
		{"ゆず", "user_088@example.com", "ChangeMe-CommonPassword-2025!", "user_088.png", "光と影のコントラストに心を寄せて 移り行く時間の流れを捉えたいという思いから 何層にも絵の具を重ねて質感を出しキャンバスには雨とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"hoshi_artworks", "user_089@example.com", "ChangeMe-CommonPassword-2025!", "user_089.png", "光と影のコントラストに心を寄せて 見る人に物語を感じてもらいたくて 繊細なタッチで空気感を表現し絵全体に散りばめられた光の点が光を引き立て、奥行きを感じさせる。"},
		{"もちもち画伯", "user_090@example.com", "ChangeMe-CommonPassword-2025!", "user_090.png", "季節の移ろいに心が動かされて 移り行く時間の流れを捉えたいという思いから 透明感を出すために淡い色彩を選び透き通るような色合いで表現された季節が、きらきらとしたハイライトに包まれている。"},
		{"sagi_creator", "user_091@example.com", "ChangeMe-CommonPassword-2025!", "user_091.png", "夜空の光に魅せられて 都市と自然の共存をテーマに掲げ 光の反射を表現するためにメディウムを工夫し透き通るような色合いで表現された人物が、きらきらとしたハイライトに包まれている。"},
		{"ひまわり", "user_092@example.com", "ChangeMe-CommonPassword-2025!", "user_092.png", "ある日、風景の美しさに心が奪われたことがきっかけで 静と動のバランスを探求し 光の反射を表現するためにメディウムを工夫しゆらめく光の中に風景が浮かび上がり、幻想的な雰囲気を醸し出している。"},
		{"nami_illustration", "user_093@example.com", "ChangeMe-CommonPassword-2025!", "user_093.png", "ある日、抽象の美しさに心が奪われたことがきっかけで この作品で抽象に潜む美しさを伝えたいと考え 繊細なタッチで空気感を表現し色と光が重なり合い、抽象の姿が抽象的に浮かび上がっている。"},
		{"ふわふわ絵描き", "user_094@example.com", "ChangeMe-CommonPassword-2025!", "user_094.png", "都会の喧騒の中でふと感じた静寂から 都市と自然の共存をテーマに掲げ 色彩のグラデーションで奥行きを生み出しキャンバスには静物とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"chidori_design", "user_095@example.com", "ChangeMe-CommonPassword-2025!", "user_095.png", "光と影のコントラストに心を寄せて 移り行く時間の流れを捉えたいという思いから 粒子のような表現で輝きを散りばめ柔らかな陰影の中に都市夜景が佇み、光のきらめきが寄り添っている。"},
		{"しろくま", "user_096@example.com", "ChangeMe-CommonPassword-2025!", "user_096.png", "夕暮れの海を眺めていたときに感じた切なさから 抽象的な概念を色で表そうと試み 細部にこだわりながら全体の調和を大切にしキャンバスには海とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"mori_works", "user_097@example.com", "ChangeMe-CommonPassword-2025!", "user_097.png", "光と影のコントラストに心を寄せて 抽象的な概念を色で表そうと試み 粒子のような表現で輝きを散りばめゆらめく光の中に森が浮かび上がり、幻想的な雰囲気を醸し出している。"},
		{"にこにこ工房", "user_098@example.com", "ChangeMe-CommonPassword-2025!", "user_098.png", "都会の喧騒の中でふと感じた静寂から 移り行く時間の流れを捉えたいという思いから 繊細なタッチで空気感を表現し絵全体に散りばめられた光の点が雨を引き立て、奥行きを感じさせる。"},
		{"hotaru_art", "user_099@example.com", "ChangeMe-CommonPassword-2025!", "user_099.png", "夜空の光に魅せられて 静と動のバランスを探求し 何層にも絵の具を重ねて質感を出しキャンバスには光とともにきらめく粒子が描かれ、静かな空気が漂っている。"},
		{"まんまる屋", "user_100@example.com", "ChangeMe-CommonPassword-2025!", "user_100.png", "都会の喧騒の中でふと感じた静寂から 抽象的な概念を色で表そうと試み 細部にこだわりながら全体の調和を大切にしゆらめく光の中に季節が浮かび上がり、幻想的な雰囲気を醸し出している。"},
	}

	ctx := context.Background()
	for _, u := range users {
		// まずユーザーを挿入して id を取得
		var userID string
		err := db.Pool.QueryRow(
			ctx,
			`INSERT INTO public.users (username, email, password, bio)
			 VALUES ($1, $2, $3, $4)
			 ON CONFLICT (email) DO NOTHING
			 RETURNING id`,
			u.Username, u.Email, u.Password, u.Bio,
		).Scan(&userID)

		// ON CONFLICT の場合はすでに存在する id を取得
		if err != nil {
			err = db.Pool.QueryRow(ctx, "SELECT id FROM public.users WHERE email = $1", u.Email).Scan(&userID)
			if err != nil {
				log.Printf("failed to get user id for %s: %v", u.Email, err)
				continue
			}
		}

		// icon_path を icons/{userID}/{filename} にする
		iconPath := strings.Join([]string{"icons", userID, u.IconFile}, "/")

		// icon_path を更新
		_, err = db.Pool.Exec(ctx, "UPDATE public.users SET icon_path=$1 WHERE id=$2", iconPath, userID)
		if err != nil {
			log.Printf("failed to update icon_path for %s: %v", u.Email, err)
			continue
		}

		log.Printf("inserted user: %s with icon_path: %s", u.Email, iconPath)
	}
}
