package extract

import "regexp"

const (
	punctuationChars = `!"#\$%&'\(\)\*\+,-\./:;<=>\?@\[\]\^_` + "`" + `\{\|\}~`

	unicodeSpaces = "\u0009-\u000d" + //  # White_Space # Cc   [5] <control-0009>..<control-000D>
		"\u0020" + // White_Space # Zs       SPACE
		"\u0085" + // White_Space # Cc       <control-0085>
		"\u00a0" + // White_Space # Zs       NO-BREAK SPACE
		"\u1680" + // White_Space # Zs       OGHAM SPACE MARK
		"\u180E" + // White_Space # Zs       MONGOLIAN VOWEL SEPARATOR
		"\u2000-\u200a" + // # White_Space # Zs  [11] EN QUAD..HAIR SPACE
		"\u2028" + // White_Space # Zl       LINE SEPARATOR
		"\u2029" + // White_Space # Zp       PARAGRAPH SEPARATOR
		"\u202F" + // White_Space # Zs       NARROW NO-BREAK SPACE
		"\u205F" + // White_Space # Zs       MEDIUM MATHEMATICAL SPACE
		"\u3000" // White_Space # Zs       IDEOGRAPHIC SPACE

	unicodeSpacesSet = `[` + unicodeSpaces + `]`

	controlChars = "\x00-\x1F\x7F"

	invalidChars = "\uFFFE\uFEFF\uFFFF\u202A\u202B\u202C\u202D\u202E"

	latinAccentChars = "\u00c0-\u00d6\u00d8-\u00f6\u00f8-\u00ff" + // Latin-1
		"\u0100-\u024f" + // Latin Extended A and B
		"\u0253\u0254\u0256\u0257\u0259\u025b\u0263\u0268\u026f\u0272\u0289\u028b" + // IPA Extensions
		"\u02bb" + // Hawaiian
		"\u0300-\u036f" + // Combining diacritics
		"\u1e00-\u1eff" // Latin Extended Additional (mostly for Vietnamese)

	hashtagAlphaChars = `a-z` + latinAccentChars +
		"\u0400-\u04ff\u0500-\u0527" + // Cyrillic
		"\u2de0-\u2dff\ua640-\ua69f" + // Cyrillic Extended A/B
		"\u0591-\u05bf\u05c1-\u05c2\u05c4-\u05c5\u05c7" +
		"\u05d0-\u05ea\u05f0-\u05f4" + // Hebrew
		"\ufb1d-\ufb28\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e\ufb40-\ufb41" +
		"\ufb43-\ufb44\ufb46-\ufb4f" + // Hebrew Pres. Forms
		"\u0610-\u061a\u0620-\u065f\u066e-\u06d3\u06d5-\u06dc" +
		"\u06de-\u06e8\u06ea-\u06ef\u06fa-\u06fc\u06ff" + // Arabic
		"\u0750-\u077f\u08a0\u08a2-\u08ac\u08e4-\u08fe" + // Arabic Supplement and Extended A
		"\ufb50-\ufbb1\ufbd3-\ufd3d\ufd50-\ufd8f\ufd92-\ufdc7\ufdf0-\ufdfb" + // Pres. Forms A
		"\ufe70-\ufe74\ufe76-\ufefc" + // Pres. Forms B
		"\u200c" + // Zero-Width Non-Joiner
		"\u0e01-\u0e3a\u0e40-\u0e4e" + // Thai
		"\u1100-\u11ff\u3130-\u3185\uA960-\uA97F\uAC00-\uD7AF\uD7B0-\uD7FF" + // Hangul (Korean)
		`\p{Hiragana}` + // Japanese Hiragana
		"\u30a1-\u30fa\u30fc-\u30fe" + // Katakana (full-width)
		"\uff66-\uff9f" + // Katakana (half-width)
		"\uff10-\uff19\uff21-\uff3a\uff41-\uff5a" + // Latin (full-width)
		"\u3400-\u4dbf" + // Kanji (CJK Extension A)
		"\u4E00-\u9FFF" + // Kanji (Unified)
		"\U00020000-\U0002A6DF" + // Kanji (CJK Extension B)
		"\U0002A700-\U0002B73F" + // Kanji (CJK Extension C)
		"\U0002B740-\U0002B81F" + // Kanji (CJK Extension D)
		"\U0002F800-\U0002FA1F" + // Kanji (CJK supplement)
		"\u3003\u3005\u303b" + // Kanji/Han iteration marks
		"\uff21-\uff3a\uff41-\uff5a" + // full width Alphabet
		"\uff66-\uff9f" + // half width Katakana
		"\uffa1-\uffdc" // half width Hangul (Korean)

	hashtagAlphaNumericChars = "0-9_\uff10-\uff19" + hashtagAlphaChars

	hashtagAlphaSet        = `[` + hashtagAlphaChars + `]`
	hashtagAlphaNumericSet = `[` + hashtagAlphaNumericChars + `]`

	urlValidPrecedingChars = `(?:[^[:alnum:]@＠$#＃` + "\u202A-\u202E]|^)"
	urlValidChars          = `[^` + punctuationChars + `[:space:][:cntrl:]` + invalidChars + unicodeSpaces + `]`
	urlValidSubDomain      = `(?:(?:` + urlValidChars + `(?:[_-]|` + urlValidChars + `*)*)?` + urlValidChars + `\.)`
	urlValidDomainName     = `(?:(?:` + urlValidChars + `(?:[-]|` + urlValidChars + `*)*)?` + urlValidChars + `\.)`

	urlValidGTLD = `(?:academy|actor|aero|agency|arpa|asia|bar|bargains|berlin|best|bid|bike|biz|blue|boutique|build|builders|`+
		`buzz|cab|camera|camp|cards|careers|cat|catering|center|ceo|cheap|christmas|cleaning|clothing|club|codes|` +
		`coffee|com|community|company|computer|construction|contractors|cool|coop|cruises|dance|dating|democrat|` +
		`diamonds|directory|domains|edu|education|email|enterprises|equipment|estate|events|expert|exposed|farm|fish|` +
		`flights|florist|foundation|futbol|gallery|gift|glass|gov|graphics|guitars|guru|holdings|holiday|house|` +
		`immobilien|industries|info|institute|int|international|jobs|kaufen|kim|kitchen|kiwi|koeln|kred|land|lighting|` +
		`limo|link|luxury|management|mango|marketing|menu|mil|mobi|moda|monash|museum|nagoya|name|net|neustar|ninja|` +
		`okinawa|onl|org|partners|parts|photo|photography|photos|pics|pink|plumbing|post|pro|productions|properties|` +
		`pub|qpon|recipes|red|rentals|repair|report|reviews|rich|ruhr|sexy|shiksha|shoes|singles|social|solar|` +
		`solutions|supplies|supply|support|systems|tattoo|technology|tel|tienda|tips|today|tokyo|tools|training|` +
		`travel|uno|vacations|ventures|viajes|villas|vision|vote|voting|voto|voyage|wang|watch|wed|wien|wiki|works|` +
		`xxx|xyz|zone|дети|онлайн|орг|сайт|بازار|شبكة|みんな|中信|中文网|公司|公益|在线|我爱你|政务|游戏|移动|网络|集团|삼성)`

	urlValidCCTLD = `(?:ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|` +
		`bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|` +
		`er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|` +
		`hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|` +
		`lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|` +
		`nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|` +
		`sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|` +
		`uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|мон|рф|срб|укр|қаз|الاردن|الجزائر|السعودية|المغرب|امارات|` +
		`ایران|بھارت|تونس|سودان|سورية|عمان|فلسطين|قطر|مصر|مليسيا|پاکستان|भारत|বাংলা|ভারত|ਭਾਰਤ|ભારત|இந்தியா|இலங்கை|சிங்கப்பூர்|` +
		`భారత్|ලංකා|ไทย|გე|中国|中國|台湾|台灣|新加坡|)`

	urlPunyCode = `(?:xn--[0-9a-z]+)`

	urlValidDomain = `(?:` +
		urlValidSubDomain + `*` + urlValidDomainName +
		`(?:` + urlValidGTLD + `|` + urlValidCCTLD + `|` + urlPunyCode + `)` +
		`)`

	urlValidAsciiDomain = `(?:` +
		`(?:(?:[[:alnum:]_\-])|[` + latinAccentChars + `])+\.)+` +
		`(?:` + urlValidGTLD + `|` + urlValidCCTLD + `|` + urlPunyCode + `)`

	urlValidPortNumber = `[0-9]+`

	urlValidGeneralPathChars = `[a-z0-9!\*';:=\+,\.\$/%#\[\]\-_~\|&@` + latinAccentChars + `]`

	urlBalancedParens = `\(` + urlValidGeneralPathChars + `+\)`

	urlValidPathEndingChars = `[a-z0-9=_#/\-\+` + latinAccentChars + `]|(?:` + urlBalancedParens + `)`

	urlValidPath = `(?:` +
		`(?:` +
		urlValidGeneralPathChars + `*` +
		`(?:` + urlBalancedParens + urlValidGeneralPathChars + `*)*` +
		urlValidPathEndingChars +
		`)|(?:@` + urlValidGeneralPathChars + `+/)` +
		`)`

	urlValidUrlQueryChars       = `[a-z0-9!\?\*'\(\);:&=\+\$/%#\[\]\-_\.,~\|@]`
	urlValidUrlQueryEndingChars = `[a-z0-9_&=#/]`

	validUrlPattern = `(` + //  $1 total match
		`(` + urlValidPrecedingChars + `)` + //  $2 Preceeding chracter
		`(` + //  $3 URL
		`(https?://)?` + //  $4 Protocol (optional)
		`(` + urlValidDomain + `)` + //  $5 Domain(s)
		`(?::(` + urlValidPortNumber + `))?` + //  $6 Port number (optional)
		`(/` +
		urlValidPath + `*` +
		`)?` + //  $7 URL Path and anchor
		`(\?` + urlValidUrlQueryChars + `*` + //  $8 Query String
		urlValidUrlQueryEndingChars + `)?` +
		`)(?:[^[:alnum:]@]|$)` +
		`)`

	atSignChars    = "@\uFF20"
	dollarSignChar = `\$`
	cashTag        = `[a-z]{1,6}(?:[\._][a-z]{1,2})?`

	// Capturing groups
	validHashtagGroupBefore = 1
	validHashtagGroupHash   = 2
	validHashtagGroupTag    = 3

	validMentionOrListGroupBefore   = 1
	validMentionOrListGroupAt       = 2
	validMentionOrListGroupUsername = 3
	validMentionOrListGroupList     = 4

	validReplyGroupAt       = 1
	validReplyGroupUsername = 2

	validUrlGroupAll         = 1
	validUrlGroupBefore      = 2
	validUrlGroupUrl         = 3
	validUrlGroupProtocol    = 4
	validUrlGroupDomain      = 5
	validUrlGroupPort        = 6
	validUrlGroupPath        = 7
	validUrlGroupQueryString = 8

	validCashtagGroupBefore  = 1
	validCashtagGroupDollar  = 2
	validCashtagGroupCashtag = 3
)

var (

	// Hash tag
	validHashtag           = regexp.MustCompile(`(?i)(^|[^&` + hashtagAlphaNumericChars + "])(#|\uFF03)(" + hashtagAlphaNumericSet + `*` + hashtagAlphaSet + hashtagAlphaNumericSet + `*)`)
	invalidHashtagMatchEnd = regexp.MustCompile(`\A(?:[#＃]|://)`)
	rtlCharacters          = regexp.MustCompile("[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\uFE70-\uFEFF]")

	// Mentions
	atSigns            = regexp.MustCompile(`[` + atSignChars + `]`)
	validMentionOrList = regexp.MustCompile(`(?i)([^a-z0-9_!#$%&*` + atSignChars + `]|^|RT:?)([` + atSignChars + `]+)([a-z0-9_]{1,20})(/[a-z][a-z0-9_-]{0,24})?`)

	validReply = regexp.MustCompile(`^(?:` + unicodeSpacesSet + `)*([` + atSignChars + `])([a-zA-Z0-9_]{1,20})`)

	invalidMentionMatchEnd = regexp.MustCompile(`\A(?:[` + atSignChars + latinAccentChars + `]|://)`)

	// URLs
	validUrl                            = regexp.MustCompile(`(?i)` + validUrlPattern)
	validTcoUrl                         = regexp.MustCompile(`(?i)^https?://t\.co\/[a-z0-9]+`)
	validAsciiDomain                    = regexp.MustCompile(urlValidAsciiDomain)
	invalidShortDomain                  = regexp.MustCompile(`\A` + urlValidDomainName + urlValidCCTLD + `\z`)
	invalidUrlWithoutProtocolMatchBegin = regexp.MustCompile(`[\-_\./]$`)

	// CashTags
	validCashtag = regexp.MustCompile(`(?i)(^|` + unicodeSpacesSet + `)(` + dollarSignChar + `)(` + cashTag + `)($|\s|[` + punctuationChars + `])`)
)
