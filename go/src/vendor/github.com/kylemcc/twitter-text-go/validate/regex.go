package validate

import "regexp"

//
//    # These URL validation pattern strings are based on the ABNF from RFC 3986
const (
	validateUrlUnreserved = `[a-z0-9\-._~]`
	validateUrlPctEncoded = `(?:%[0-9-a-fA-F]{2})`
	validateUrlSubDelims  = `[!$&'()*+,;=]`
	validateUrlPchar      = `(?:` +
		validateUrlUnreserved + `|` +
		validateUrlPctEncoded + `|` +
		validateUrlSubDelims + `|` +
		`[:\|@])`

	validateUrlUserinfo = `(?:` +
		validateUrlUnreserved + `|` +
		validateUrlPctEncoded + `|` +
		validateUrlSubDelims + `|` +
		`:)*`

	validateUrlDecOctet = `(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9]{2})|(?:2[0-4][0-9])|(?:25[0-5]))`

	validateUrlIpv4 = `(?:` +
		validateUrlDecOctet +
		`(?:\.` + validateUrlDecOctet + `){3}` +
		`)`

	// Punting on real IPv6 validation for now
	validateUrlIpv6 = `(?:\[[a-fA-F0-9:\.]+\])`

	// Also punting on IPvFuture for now
	validateUrlIp = `(?:` +
		validateUrlIpv4 + `|` + validateUrlIpv6 +
		`)`

	// This is more strict than the rfc specifies
	validateUrlSubdomainSegment = `(?:[a-z0-9](?:[a-z0-9_\-]*[a-z0-9])?)`
	validateUrlDomainSegment    = `(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)`
	validateUrlDomainTld        = `(?:[a-z](?:[a-z0-9\-]*[a-z0-9])?)`
	validateUrlDomain           = `(?:(?:` +
		validateUrlSubdomainSegment + `\.)*` +
		`(?:` + validateUrlDomainSegment + `\.)` +
		validateUrlDomainTld + `)`

	validateUrlHost = `(?:` + validateUrlIp + `|` + validateUrlDomain + `)`

	// Unencoded internationalized domains - this doesn't check for invalid UTF-8 sequences
	validateUrlUnicodeSubdomainSegment = `(?:` +
		`(?:[a-z0-9]|[^\x00-\x7f])(?:(?:[a-z0-9_\-]` +
		`|[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)`

	validateUrlUnicodeDomainSegment = `(?:` +
		`(?:[a-z0-9]|[^\x00-\x7f])(?:(?:[a-z0-9\-]|` +
		`[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)`

	validateurlUnicodeDomainSegment = `(?:` +
		`(?:[a-z0-9]|[^\x00-\x7f])(?:(?:[a-z0-9\-]|` +
		`[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)`

	validateUrlUnicodeDomainTld = `(?:` +
		`(?:[a-z]|[^\x00-\x7f])(?:(?:[a-z0-9\-]|` +
		`[^\x00-\x7f])*(?:[a-z0-9]|[^\x00-\x7f]))?)`

	validateUrlUnicodeDomain = `(?:` +
		`(?:` + validateUrlUnicodeSubdomainSegment + `\.)*` +
		`(?:` + validateUrlUnicodeDomainSegment + `\.)` +
		validateUrlUnicodeDomainTld + `)`

	validateUrlUnicodeHost = `(?:` +
		validateUrlIp + `|` +
		validateUrlUnicodeDomain +
		`)`

	validateUrlPort = `[0-9]{1,5}`

	validateUrlUnicodeAuthority = `\A(?:` +
		`(` + validateUrlUserinfo + `)@)?` + // $1 userinfo
		`(` + validateUrlUnicodeHost + `)` + // $2 host
		`(?::(` + validateUrlPort + `))?\z` // $3 port

	validateUrlAuthority = `\"(?:` +
		`(` + validateUrlUserinfo + `)@)?` + // $1 userinfo
		`(` + validateUrlHost + `)` + // $2 host
		`(?::(` + validateUrlPort + `))?\z` // $3 port

	validateUrlScheme   = `\A(?:[a-z][a-z0-9+\-.]*)\z`
	validateUrlPath     = `\A(/` + validateUrlPchar + `*)*\z`
	validateUrlQuery    = `\A(` + validateUrlPchar + `|/|\?)*\z`
	validateUrlFragment = `\A(` + validateUrlPchar + `|/|\?)*\z`

	// Modified version of RFC 3986 Appendix B
	validateUrlUnencoded = `\A` + // Full URL
		`(?:` +
		`([^:/?#]+)://` + // $1 Scheme
		`)?` +
		`([^/?#]*)` + // $2 Authority
		`([^?#]*)` + // $3 Path
		`(?:` +
		`\?([^#]*)` + // $4 Query
		`)?` +
		`(?:` +
		`\#(.*)` + // $5 Fragment
		`)?\z`

	validateUrlUnencodedGroupScheme    = 1
	validateUrlUnencodedGroupAuthority = 2
	validateUrlUnencodedGroupPath      = 3
	validateUrlUnencodedGroupQuery     = 4
	validateUrlUnencodedGroupFragment  = 5
)

var (
	validateUrlUnencodedRe        = regexp.MustCompile(`(?i)` + validateUrlUnencoded)
	validateUrlSchemeRe           = regexp.MustCompile(`(?i)` + validateUrlScheme)
	validateUrlPathRe             = regexp.MustCompile(`(?i)` + validateUrlPath)
	validateUrlQueryRe            = regexp.MustCompile(`(?i)` + validateUrlQuery)
	validateUrlFragmentRe         = regexp.MustCompile(`(?i)` + validateUrlFragment)
	validateUrlAuthorityRe        = regexp.MustCompile(`(?i)` + validateUrlAuthority)
	validateUrlUnicodeAuthorityRe = regexp.MustCompile(`(?i)` + validateUrlUnicodeAuthority)
	protocolRe                    = regexp.MustCompile(`(?i)\Ahttps?\z`)
)
