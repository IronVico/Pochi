import SwiftUI

/// Pixel-art versions of the habit emojis. Habits still store the emoji itself,
/// so nothing changes in the data: we just draw the matching sprite when there is one.
enum PixelEmoji {
    /// Icons offered when creating a habit.
    static let habitIcons = ["💧", "🏃", "📚", "🧘", "💪", "🍎", "😴", "✍️",
                             "🎸", "🧹", "💊", "📵", "🦷", "🌱", "💰", "🎯"]

    static func sprite(for emoji: String) -> [String]? { sprites[emoji] }

    // 12 × 12, colours from PixelIcon.palette.
    private static let sprites: [String: [String]] = [
        "💧": [
            ".....BB.....",
            ".....BB.....",
            "....BBBB....",
            "....BBBB....",
            "...BBBBBB...",
            "..BBBBBBBB..",
            "..BbBBBBBB..",
            ".BBbBBBBBBB.",
            ".BBbbBBBBBB.",
            ".BBBBBBBBBB.",
            "..BBBBBBBB..",
            "....BBBB....",
        ],
        "🏃": [
            "........SS..",
            "........SS..",
            "......OOO...",
            "....OOOOOS..",
            "...S.OOO..S.",
            ".....OOO....",
            ".....BBB....",
            "....BB.BB...",
            "...BB...BB..",
            "..SS.....S..",
            ".........SS.",
            "............",
        ],
        "📚": [
            "............",
            "..RRRRRRRR..",
            "..RWWWWWWR..",
            "..RRRRRRRR..",
            "...BBBBBBBB.",
            "...BWWWWWWB.",
            "...BBBBBBBB.",
            ".NNNNNNNN...",
            ".NWWWWWWN...",
            ".NNNNNNNN...",
            "............",
            "............",
        ],
        "🧘": [
            ".....SS.....",
            ".....SS.....",
            "............",
            "....VVVV....",
            "...VVVVVV...",
            "..S.VVVV.S..",
            "..S.VVVV.S..",
            "...SVVVVS...",
            "..VVVVVVVV..",
            ".VVVVVVVVVV.",
            ".SS......SS.",
            "............",
        ],
        "💪": [
            "............",
            "............",
            ".GG......GG.",
            "GLLG....GLLG",
            "GLLG....GLLG",
            "GLLGWWWWGLLG",
            "GLLGWWWWGLLG",
            "GLLG....GLLG",
            "GLLG....GLLG",
            ".GG......GG.",
            "............",
            "............",
        ],
        "🍎": [
            "......M.....",
            ".....MNN....",
            "......NN....",
            "..RRR..RRR..",
            ".RRRRRRRRRR.",
            ".RWRRRRRRRR.",
            ".RWRRRRRRRR.",
            ".RRRRRRRRRR.",
            ".RRRRRRRRRr.",
            "..RRRRRRRr..",
            "...RRrRRr...",
            "............",
        ],
        "😴": [
            "........LLLL",
            "..........L.",
            ".........L..",
            "...YYY..LLLL",
            "..YYYY......",
            ".YYYY.......",
            ".YYY........",
            ".YYY........",
            ".YYYY....Y..",
            "..YYYYYYYY..",
            "...YYYYYY...",
            "............",
        ],
        "✍️": [
            "..........PP",
            ".........PPP",
            "........YYP.",
            ".......YYY..",
            "......YYY...",
            ".....YYY....",
            "....YYY.....",
            "...YYY......",
            "..mYY.......",
            "..mm........",
            ".G..........",
            "............",
        ],
        "🎸": [
            "..........MM",
            ".........MM.",
            "........MM..",
            ".......MM...",
            "......MM....",
            "..OOOMM.....",
            ".OOOOOO.....",
            ".OOKKOO.....",
            "OOOKKOOO....",
            "OOOOOOOO....",
            ".OOOOOO.....",
            "..OOOO......",
        ],
        "🧹": [
            "..........M.",
            ".........M..",
            "........M...",
            ".......M....",
            "......M.....",
            ".....M......",
            "...YYYY.....",
            "..YYYYYY....",
            "..YYYYYY....",
            ".YYYYYYYY...",
            ".Y.Y.Y.Y....",
            "............",
        ],
        "💊": [
            "............",
            ".......WWW..",
            "......WWWWW.",
            ".....WWWWWW.",
            "....RWWWWW..",
            "...RRRWWW...",
            "..RRRRRW....",
            ".RRRRRR.....",
            ".RRRRR......",
            "..RRR.......",
            "............",
            "............",
        ],
        "📵": [
            "............",
            "R..GGGGGG...",
            ".R.GLLLLG...",
            "..RGLLLLG...",
            "...RLLLLG...",
            "...GRLLLG...",
            "...GLRLLG...",
            "...GLLRLG...",
            "...GLLLRG...",
            "...GGGGGR...",
            "...GGKGGGR..",
            "..........R.",
        ],
        "🦷": [
            "............",
            "..WWW..WWW..",
            ".WWWWWWWWWW.",
            ".WWWWWWWWWL.",
            ".WWWWWWWWWL.",
            ".WWWWWWWWWL.",
            "..WWWWWWWL..",
            "..WWWWWWWL..",
            "..WWW..WWL..",
            "..WW....WL..",
            "..WW....WL..",
            "...W....L...",
        ],
        "🌱": [
            "............",
            "..NN....NN..",
            ".NNNN..NNNN.",
            ".NNNNN.NNNN.",
            "..NNNnnNNN..",
            "....NnnN....",
            ".....nn.....",
            ".....nn.....",
            ".....nn.....",
            "..MMMMMMMM..",
            ".MMMMMMMMMM.",
            "............",
        ],
        "💰": [
            "....MMMM....",
            ".....MM.....",
            "....mmmm....",
            "...mmmmmm...",
            "..mmmYYmmm..",
            ".mmmYmmmmmm.",
            ".mmmmYYmmmm.",
            ".mmmmmmYmmm.",
            ".mmmmYYmmmm.",
            ".mmmmmmmmmm.",
            "..mmmmmmmm..",
            "............",
        ],
        "🎯": [
            "...RRRRRR...",
            "..RWWWWWWR..",
            ".RWRRRRRRWR.",
            ".RWRWWWWRWR.",
            ".RWRWRRWRWR.",
            ".RWRWRRWRWR.",
            ".RWRWWWWRWR.",
            ".RWRRRRRRWR.",
            "..RWWWWWWR..",
            "...RRRRRR...",
            "............",
            "............",
        ],

    ]
}

/// An emoji drawn as its pixel-art version when there is one, as the emoji otherwise.
struct EmojiIcon: View {
    let emoji: String
    var size: CGFloat = 28

    var body: some View {
        if let sprite = PixelEmoji.sprite(for: emoji) {
            PixelSprite(grid: sprite, pixel: size / 12)
        } else {
            Text(emoji).font(.system(size: size * 0.85))
        }
    }
}

#if DEBUG
/// Every pixel emoji. Launch with `-iconGallery` to see it.
struct PixelEmojiGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: "HABITUDES")
                grid(PixelEmoji.habitIcons)
            }
            .padding(24)
            .padding(.top, 40)
        }
        .background(Color.black)
    }

    private func grid(_ emojis: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(emojis, id: \.self) { emoji in
                VStack(spacing: 6) {
                    EmojiIcon(emoji: emoji, size: 48)
                    Text(emoji).font(.caption)
                }
            }
        }
    }
}
#endif
