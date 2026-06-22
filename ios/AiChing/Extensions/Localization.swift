import Foundation
import SwiftUI

enum L {
    enum App {
        static let name = ("AiChing", "AiChing – Kinh Dịch")
        static let tagline = ("The Book of Changes", "Kinh Dịch – Sách của những biến đổi")
        static let footer = ("Ancient wisdom, modern revelation", "Cổ nhân chi tuệ, khải thị hôm nay")
    }

    enum Step {
        static let idle = ("Prepare", "Chuẩn bị")
        static let stillness = ("Stillness", "Tĩnh tâm")
        static let inquiry = ("Inquiry", "Vấn đáp")
        static let splits = ("Splitting the Stalks", "Phân thi")
        static let computation = ("Computation", "Diễn quái")
        static let override = ("Intuition", "Cảm ứng")
        static let oracle = ("The Oracle", "Khai thị")
    }

    enum Idle {
        static let begin = ("Begin Reading", "Bắt đầu xem quẻ")
        static let history = ("Reading History", "Lịch sử")
        static let subtitle = ("A sacred divination ritual", "Một nghi thức xem bói cổ xưa")
        static let desc = ("Based on the I Ching — the 3000-year-old Chinese classic.\nEach reading is uniquely shaped by your breath, your touch,\nyour presence in this moment.",
            "Dựa trên Kinh Dịch – tuyệt tác 3000 năm tuổi.\nMỗi quẻ được tạo nên từ hơi thở, từng chạm nhẹ,\nsự hiện diện của bạn trong giây phút này.")
    }

    enum Stillness {
        static let title = ("Still Your Mind", "Tĩnh tâm")
        static let instruction = ("Press and hold the circle. Let your breath settle.\nEach hold is 4–7 seconds — random, like life.",
            "Nhấn và giữ vòng tròn. Để hơi thở an nhiên.\nMỗi lần giữ kéo dài 4–7 giây — ngẫu nhiên, như cuộc sống.")
        static let hint = ("Hold until the ink pool fills completely.", "Giữ cho đến khi vùng mực đầy hoàn toàn.")
        static let tooSoon = ("Too soon. Breathe deeper.", "Vội quá. Hít thở sâu hơn.")
        static let complete = ("Stillness achieved.", "Tĩnh tâm hoàn tất.")
    }

    enum Inquiry {
        static let title = ("What Do You Seek?", "Bạn muốn hỏi gì?")
        static let instruction = ("Write your question with sincerity.\n5–200 characters. The words shape the reading.",
            "Viết câu hỏi của bạn với lòng thành kính.\n5–200 ký tự. Lời văn sẽ định hình quẻ.")
        static let placeholder = ("Type your question here...", "Nhập câu hỏi của bạn ở đây...")
        static let minChars = ("Minimum 5 characters", "Tối thiểu 5 ký tự")
        static let next = ("Continue", "Tiếp tục")
        static let examples = ("Example questions:", "Câu hỏi mẫu:")
        static let ex1 = ("What guidance do I need right now?", "Tôi cần lời khuyên gì lúc này?")
        static let ex2 = ("How can I find clarity in my work?", "Làm sao để tìm sự sáng suốt trong công việc?")
        static let ex3 = ("What energy surrounds my relationship?", "Năng lượng nào đang bao quanh mối quan hệ của tôi?")
    }

    enum Splits {
        static let title = ("The Six Splits", "Sáu lần phân thây")
        static let instruction = ("Drag the golden handle to split the 50 yarrow stalks.\nWhere it feels right — trust your intuition.",
            "Kéo thanh vàng để phân 50 cọng cỏ thi.\nNơi nào cảm thấy đúng — hãy tin trực giác.")
        static let line = ("Line", "Hào")
        static let of = ("of", "trên")
        static let complete = ("All 6 lines cast.", "Cả 6 hào đã định.")
        static let hint = ("Each split determines one line of the hexagram.", "Mỗi lần phân xác định một hào của quẻ.")
    }

    enum Computation {
        static let title = ("The Hexagram Forms", "Quái tượng hình thành")
        static let instruction = ("Your entropy is being woven into a hexagram.\nSHA-256 hashing of 10+ entropy sources.",
            "Entropy của bạn đang được dệt thành quẻ.\nBăm SHA-256 từ 10+ nguồn entropy.")
        static let speaking = ("The stalks are speaking...", "Cỏ thi đang nói...")
        static let complete = ("Hexagram complete", "Quái tượng hoàn tất")
        static let detail = ("Your unique moment has been sealed into this pattern.", "Khoảnh khắc độc nhất của bạn đã được niêm phong trong quẻ này.")
    }

    enum Override {
        static let title = ("Listen to Your Intuition", "Lắng nghe trực giác")
        static let instruction = ("AiChing computed these lines from the entropy of your ritual.\nBut your conscious mind may sense something the algorithm missed.\nTap any line to flip its moving/static nature.",
            "AiChing tính các hào này từ entropy của nghi thức bạn.\nNhưng tâm thức bạn có thể cảm nhận điều thuật toán bỏ sót.\nChạm vào hào để thay đổi tính động/tĩnh.")
        static let accept = ("Accept & Receive Oracle", "Chấp nhận & Nhận quẻ")
        static let forming = ("Secondary hexagram will form:", "Quẻ biến sẽ là:")
        static let bottom = ("Bottom", "Sơ")
        static let second = ("Second", "Nhị")
        static let third = ("Third", "Tam")
        static let fourth = ("Fourth", "Tứ")
        static let fifth = ("Fifth", "Ngũ")
        static let top = ("Top", "Thượng")
    }

    enum Oracle {
        static let title = ("The Oracle Speaks", "Khai thị")
        static let yourQuestion = ("Your Question", "Câu hỏi của bạn")
        static let primary = ("Primary Hexagram", "Quẻ chủ")
        static let changingTo = ("Changing to", "Biến thành")
        static let changingLines = ("Changing Lines", "Hào động")
        static let judgment = ("Judgment", "Thoán từ")
        static let image = ("Image", "Tượng truyện")
        static let lineAnalysis = ("Line Analysis", "Phân tích hào")
        static let seed = ("Seed", "Căn nguyên")
        static let interpretation = ("Interpretation", "Luận giải")
        static let save = ("Save Reading", "Lưu quẻ")
        static let saved = ("Saved", "Đã lưu")
        static let share = ("Share", "Chia sẻ")
        static let newReading = ("New Reading", "Quẻ mới")
        static let noReading = ("No reading yet.", "Chưa có quẻ nào.")
        static let noReadingDesc = ("Complete the ritual to receive your oracle.", "Hãy hoàn tất nghi thức để nhận quẻ.")
    }

    enum Journal {
        static let title = ("Reading History", "Lịch sử")
        static let search = ("Search readings...", "Tìm kiếm quẻ...")
        static let noReadings = ("No readings yet", "Chưa có quẻ nào")
        static let noReadingsDesc = ("Complete a divination ritual\nto see your history here.", "Hoàn tất nghi thức xem quẻ\nđể xem lịch sử tại đây.")
        static let delete = ("Delete Reading", "Xóa quẻ")
        static let deleteConfirm = ("This reading will be permanently deleted.", "Quẻ này sẽ bị xóa vĩnh viễn.")
        static let refresh = ("Refresh", "Làm mới")
        static let close = ("Close", "Đóng")
        static let detail = ("Reading Detail", "Chi tiết quẻ")
        static let done = ("Done", "Xong")
    }

    enum Error {
        static let noMotion = ("Motion sensors unavailable", "Cảm biến chuyển động không khả dụng")
        static let noMotionDesc = ("This ritual requires an accelerometer.", "Nghi thức này cần cảm biến gia tốc.")
        static let saveFailed = ("Failed to save reading.", "Không thể lưu quẻ.")
        static let generic = ("Something went wrong.", "Có lỗi xảy ra.")
    }
}

/// Helper for bilingual string display.
func t(_ pair: (String, String), _ vi: Bool) -> String { vi ? pair.1 : pair.0 }

struct Localized {
    let en: String
    let vi: String
    init(_ en: String, _ vi: String) { self.en = en; self.vi = vi }
    func text(_ isVietnamese: Bool) -> String { isVietnamese ? vi : en }
}

extension Localized { static func + (lhs: Localized, rhs: Localized) -> Localized { Localized(lhs.en + rhs.en, lhs.vi + rhs.vi) } }

struct LocalePreferenceKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var localePreference: Bool {
        get { self[LocalePreferenceKey.self] }
        set { self[LocalePreferenceKey.self] = newValue }
    }
}
