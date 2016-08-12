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

	//
	// Hashtag
	//

	hashtagAlphaChars   = `\p{L}\p{M}`
	hashtagAlphaSet     = `[` + hashtagAlphaChars + `]`
	hashtagNumericChars = `\p{Nd}`
	hashtagSpecialChars = `_` +
		"\u200c" + // ZERO WIDTH NON-JOINER (ZWNJ)
		"\u200d" + // ZERO WIDTH JOINER (ZWJ)
		"\ua67e" + // CYRILLIC KAVYKA
		"\u05be" + // HEBREW PUNCTUATION MAQAF
		"\u05f3" + // HEBREW PUNCTUATION GERESH
		"\u05f4" + // HEBREW PUNCTUATION GERSHAYIM
		"\u309b" + // KATAKANA-HIRAGANA VOICED SOUND MARK
		"\u309c" + // KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
		"\u30a0" + // KATAKANA-HIRAGANA DOUBLE HYPHEN
		"\u30fb" + // KATAKANA MIDDLE DOT
		"\u3003" + // DITTO MARK
		"\u0f0b" + // TIBETAN MARK INTERSYLLABIC TSHEG
		"\u0f0c" + // TIBETAN MARK DELIMITER TSHEG BSTAR
		"\u00b7" // MIDDLE DOT

	hashtagAlphaNumericSet      = `[` + hashtagAlphaChars + hashtagNumericChars + hashtagSpecialChars + `]`
	hashtagBoundaryInvalidChars = `&` + hashtagAlphaChars + hashtagNumericChars + hashtagSpecialChars
	hashtagBoundary             = `^|$|[^` + hashtagBoundaryInvalidChars + `]`

	//
	// URL
	//

	urlValidPrecedingChars = `(?:[^[:alnum:]@＠$#＃` + "\u202A-\u202E]|^)"
	urlValidChars          = `[^` + punctuationChars + `[:space:][:cntrl:]` + invalidChars + unicodeSpaces + `]`
	urlValidSubDomain      = `(?:(?:` + urlValidChars + `(?:[_-]|` + urlValidChars + `*)*)?` + urlValidChars + `\.)`
	urlValidDomainName     = `(?:(?:` + urlValidChars + `(?:[-]|` + urlValidChars + `*)*)?` + urlValidChars + `\.)`

	urlValidGTLD = `(?:` +
		`abb|abbott|abogado|academy|accenture|accountant|accountants|aco|active|actor|ads|adult|aeg|aero|afl|` +
		`agency|aig|airforce|airtel|allfinanz|alsace|amsterdam|android|apartments|app|aquarelle|archi|army|` +
		`arpa|asia|associates|attorney|auction|audio|auto|autos|axa|azure|band|bank|bar|barcelona|barclaycard|` +
		`barclays|bargains|bauhaus|bayern|bbc|bbva|bcn|beer|bentley|berlin|best|bet|bharti|bible|bid|bike|` +
		`bing|bingo|bio|biz|black|blackfriday|bloomberg|blue|bmw|bnl|bnpparibas|boats|bond|boo|boots|boutique|` +
		`bradesco|bridgestone|broker|brother|brussels|budapest|build|builders|business|buzz|bzh|cab|cafe|cal|` +
		`camera|camp|cancerresearch|canon|capetown|capital|caravan|cards|care|career|careers|cars|cartier|` +
		`casa|cash|casino|cat|catering|cba|cbn|ceb|center|ceo|cern|cfa|cfd|chanel|channel|chat|cheap|chloe|` +
		`christmas|chrome|church|cisco|citic|city|claims|cleaning|click|clinic|clothing|cloud|club|coach|` +
		`codes|coffee|college|cologne|com|commbank|community|company|computer|condos|construction|consulting|` +
		`contractors|cooking|cool|coop|corsica|country|coupons|courses|credit|creditcard|cricket|crown|crs|` +
		`cruises|cuisinella|cymru|cyou|dabur|dad|dance|date|dating|datsun|day|dclk|deals|degree|delivery|` +
		`delta|democrat|dental|dentist|desi|design|dev|diamonds|diet|digital|direct|directory|discount|dnp|` +
		`docs|dog|doha|domains|doosan|download|drive|durban|dvag|earth|eat|edu|education|email|emerck|energy|` +
		`engineer|engineering|enterprises|epson|equipment|erni|esq|estate|eurovision|eus|events|everbank|` +
		`exchange|expert|exposed|express|fage|fail|faith|family|fan|fans|farm|fashion|feedback|film|finance|` +
		`financial|firmdale|fish|fishing|fit|fitness|flights|florist|flowers|flsmidth|fly|foo|football|forex|` +
		`forsale|forum|foundation|frl|frogans|fund|furniture|futbol|fyi|gal|gallery|game|garden|gbiz|gdn|gent|` +
		`genting|ggee|gift|gifts|gives|giving|glass|gle|global|globo|gmail|gmo|gmx|gold|goldpoint|golf|goo|` +
		`goog|google|gop|gov|graphics|gratis|green|gripe|group|guge|guide|guitars|guru|hamburg|hangout|haus|` +
		`healthcare|help|here|hermes|hiphop|hitachi|hiv|hockey|holdings|holiday|homedepot|homes|honda|horse|` +
		`host|hosting|hoteles|hotmail|house|how|hsbc|ibm|icbc|ice|icu|ifm|iinet|immo|immobilien|industries|` +
		`infiniti|info|ing|ink|institute|insure|int|international|investments|ipiranga|irish|ist|istanbul|` +
		`itau|iwc|java|jcb|jetzt|jewelry|jlc|jll|jobs|joburg|jprs|juegos|kaufen|kddi|kim|kitchen|kiwi|koeln|` +
		`komatsu|krd|kred|kyoto|lacaixa|lancaster|land|lasalle|lat|latrobe|law|lawyer|lds|lease|leclerc|legal|` +
		`lexus|lgbt|liaison|lidl|life|lighting|limited|limo|link|live|lixil|loan|loans|lol|london|lotte|lotto|` +
		`love|ltda|lupin|luxe|luxury|madrid|maif|maison|man|management|mango|market|marketing|markets|` +
		`marriott|mba|media|meet|melbourne|meme|memorial|men|menu|miami|microsoft|mil|mini|mma|mobi|moda|moe|` +
		`mom|monash|money|montblanc|mormon|mortgage|moscow|motorcycles|mov|movie|movistar|mtn|mtpc|museum|` +
		`nadex|nagoya|name|navy|nec|net|netbank|network|neustar|new|news|nexus|ngo|nhk|nico|ninja|nissan|` +
		`nokia|nra|nrw|ntt|nyc|office|okinawa|omega|one|ong|onl|online|ooo|oracle|orange|org|organic|osaka|` +
		`otsuka|ovh|page|panerai|paris|partners|parts|party|pet|pharmacy|philips|photo|photography|photos|` +
		`physio|piaget|pics|pictet|pictures|pink|pizza|place|play|plumbing|plus|pohl|poker|porn|post|praxi|` +
		`press|pro|prod|productions|prof|properties|property|pub|qpon|quebec|racing|realtor|realty|recipes|` +
		`red|redstone|rehab|reise|reisen|reit|ren|rent|rentals|repair|report|republican|rest|restaurant|` +
		`review|reviews|rich|ricoh|rio|rip|rocks|rodeo|rsvp|ruhr|run|ryukyu|saarland|sakura|sale|samsung|` +
		`sandvik|sandvikcoromant|sanofi|sap|sarl|saxo|sca|scb|schmidt|scholarships|school|schule|schwarz|` +
		`science|scor|scot|seat|seek|sener|services|sew|sex|sexy|shiksha|shoes|show|shriram|singles|site|ski|` +
		`sky|skype|sncf|soccer|social|software|sohu|solar|solutions|sony|soy|space|spiegel|spreadbetting|srl|` +
		`starhub|statoil|studio|study|style|sucks|supplies|supply|support|surf|surgery|suzuki|swatch|swiss|` +
		`sydney|systems|taipei|tatamotors|tatar|tattoo|tax|taxi|team|tech|technology|tel|telefonica|temasek|` +
		`tennis|thd|theater|tickets|tienda|tips|tires|tirol|today|tokyo|tools|top|toray|toshiba|tours|town|` +
		`toyota|toys|trade|trading|training|travel|trust|tui|ubs|university|uno|uol|vacations|vegas|ventures|` +
		`vermögensberater|vermögensberatung|versicherung|vet|viajes|video|villas|vin|vision|vista|vistaprint|` +
		`vlaanderen|vodka|vote|voting|voto|voyage|wales|walter|wang|watch|webcam|website|wed|wedding|weir|` +
		`whoswho|wien|wiki|williamhill|win|windows|wine|wme|work|works|world|wtc|wtf|xbox|xerox|xin|xperia|` +
		`xxx|xyz|yachts|yandex|yodobashi|yoga|yokohama|youtube|zip|zone|zuerich|дети|ком|москва|онлайн|орг|` +
		`рус|сайт|קום|بازار|شبكة|كوم|موقع|कॉम|नेट|संगठन|คอม|みんな|グーグル|コム|世界|中信|中文网|企业|佛山|信息|健康|八卦|公司|公益|商城|商店|` +
		`商标|在线|大拿|娱乐|工行|广东|慈善|我爱你|手机|政务|政府|新闻|时尚|机构|淡马锡|游戏|点看|移动|组织机构|网址|网店|网络|谷歌|集团|飞利浦|餐厅|닷넷|닷컴|삼성|onion` +
		`)`

	urlValidCCTLD = `(?:` +
		`ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bl|bm|bn|bo|bq|br|` +
		`bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|` +
		`eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|` +
		`hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|` +
		`lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|` +
		`nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|` +
		`sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|` +
		`tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|ελ|бел|мкд|мон|рф|срб|укр|` +
		`қаз|հայ|الاردن|الجزائر|السعودية|المغرب|امارات|ایران|بھارت|تونس|سودان|سورية|عراق|عمان|فلسطين|قطر|مصر|` +
		`مليسيا|پاکستان|भारत|বাংলা|ভারত|ਭਾਰਤ|ભારત|இந்தியா|இலங்கை|சிங்கப்பூர்|భారత్|ලංකා|ไทย|გე|中国|中國|台湾|台灣|` +
		`新加坡|澳門|香港|한국` +
		`)`

	urlPunyCode = `(?:xn--[0-9a-z]+)`

	urlValidSpecialCCTLD = `(?:co|tv)`

	urlValidDomain = `(?:` +
		urlValidSubDomain + `*` + urlValidDomainName +
		`(?:` + urlValidGTLD + `|` + urlValidCCTLD + `|` + urlPunyCode + `)` +
		`)`

	urlValidAsciiDomain = `(?:` +
		`(?:[[:alnum:]][[:alnum:]_\-` + latinAccentChars + `]*)+\.)+` +
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
		`(` + urlValidPrecedingChars + `)` + //  $2 Preceding character
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
	validHashtagGroupHash = 1
	validHashtagGroupTag  = 2

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
	validHashtag           = regexp.MustCompile(`(?i)(?:` + hashtagBoundary + `)` + `([#＃])(` + hashtagAlphaNumericSet + `*` + hashtagAlphaSet + hashtagAlphaNumericSet + `*)`)
	invalidHashtagMatchEnd = regexp.MustCompile(`\A(?:[#＃]|://)`)
	rtlCharacters          = regexp.MustCompile("[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\uFE70-\uFEFF]")

	// Mentions
	atSigns            = regexp.MustCompile(`[` + atSignChars + `]`)
	validMentionOrList = regexp.MustCompile(`(?i)([^a-zA-Z0-9_!#$%&*` + atSignChars + `]|^|^\s*RT:?)([` + atSignChars + `]+)([a-z0-9_]{1,20})(/[a-z][a-z0-9_-]{0,24})?`)

	validReply = regexp.MustCompile(`^(?:` + unicodeSpacesSet + `)*([` + atSignChars + `])([a-zA-Z0-9_]{1,20})`)

	invalidMentionMatchEnd = regexp.MustCompile(`\A(?:[` + atSignChars + latinAccentChars + `]|://)`)

	// URLs
	validUrl                            = regexp.MustCompile(`(?i)` + validUrlPattern)
	validTcoUrl                         = regexp.MustCompile(`(?i)^https?://t\.co\/[a-z0-9]+`)
	validAsciiDomain                    = regexp.MustCompile(urlValidAsciiDomain)
	invalidShortDomain                  = regexp.MustCompile(`\A` + urlValidDomainName + urlValidCCTLD + `\z`)
	validSpecialShortDomain             = regexp.MustCompile(`\A` + urlValidDomainName + urlValidSpecialCCTLD + `\z`)
	invalidUrlWithoutProtocolMatchBegin = regexp.MustCompile(`[\-_\./]$`)

	// CashTags
	validCashtag = regexp.MustCompile(`(?i)(^|` + unicodeSpacesSet + `)(` + dollarSignChar + `)(` + cashTag + `)($|\s|[` + punctuationChars + `])`)
)
