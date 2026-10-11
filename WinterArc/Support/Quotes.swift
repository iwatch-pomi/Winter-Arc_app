import Foundation

struct Quote: Hashable {
    let text: String
    let author: String
}

enum Quotes {
    static let all: [Quote] = [
        Quote(text: "規律とは、目標と達成をつなぐ架け橋である。", author: "ジム・ローン"),
        Quote(text: "やる気は始めるきっかけにすぎない。続けさせてくれるのは習慣だ。", author: "ジム・ライアン"),
        Quote(text: "小さなことを積み重ねることが、とんでもないところへ行くただひとつの道。", author: "イチロー"),
        Quote(text: "千里の道も一歩から。", author: "老子"),
        Quote(text: "為せば成る、為さねば成らぬ何事も。", author: "上杉鷹山"),
        Quote(text: "始めるのに偉大である必要はない。だが、偉大になるには始める必要がある。", author: "ジグ・ジグラー"),
        Quote(text: "成功とは、日々繰り返される小さな努力の積み重ねである。", author: "ロバート・コリアー"),
        Quote(text: "今日できることを、明日に延ばすな。", author: "ベンジャミン・フランクリン"),
        Quote(text: "明日死ぬかのように生きよ。永遠に生きるかのように学べ。", author: "マハトマ・ガンジー"),
        Quote(text: "継続は力なり。", author: "ことわざ"),
        Quote(text: "Discipline today, Freedom tomorrow.", author: "Winter Arc"),
        Quote(text: "今日の積み重ねが、未来の自分をつくる。", author: "Winter Arc"),
    ]

    static func of(day date: Date = Date()) -> Quote {
        let day = Calendar.app.ordinality(of: .day, in: .era, for: date) ?? 0
        return all[day % all.count]
    }

    /// ホーム画面のヒーローに出す短いフレーズ
    static let taglines = [
        "今日の積み重ねが、\n未来を変える。",
        "冬の努力が、\n最高の自分をつくる。",
        "Discipline today,\nFreedom tomorrow.",
        "小さな一歩を、\n今日も確実に。",
    ]

    static func tagline(for date: Date = Date()) -> String {
        let day = Calendar.app.ordinality(of: .day, in: .era, for: date) ?? 0
        return taglines[day % taglines.count]
    }
}
