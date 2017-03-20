package sockjs

import "encoding/json"

func quote(in string) string {
	quoted, _ := json.Marshal(in)
	return string(quoted)
}
