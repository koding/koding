package token

import (
	"crypto/sha256"
	"encoding/hex"
)

var Secret = "0Z/V3rlxm4xULMnSrPPxLMq~Li/J2mNXkeHRIWWCY2GB5QKIBnlXd8j!8TNcN9T0uiESXfMynR0sxfnXUlLQmS9JrLd6LGkw2VYM"

func StringToken(username, vm string) string {
	hasher := sha256.New()
	hasher.Write([]byte(Secret + username + vm))
	cs := hex.EncodeToString(hasher.Sum(nil))
	return cs
}
