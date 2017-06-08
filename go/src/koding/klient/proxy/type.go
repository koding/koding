package proxy

import (
    "bytes"
    "encoding/json"
)

type ProxyType int

const (
    Kubernetes ProxyType = iota
    Docker
)

var ProxyType2String = map[ProxyType]string{
    Kubernetes: "kubernetes",
    Docker:     "docker",
}

var String2ProxyType = map[string]ProxyType{
    "kubernetes":   Kubernetes,
    "docker":       Docker,
}

// fmt.Stringer
func (t ProxyType) String() string {
    return ProxyType2String[t]
}

// json.Marshaler
func (t *ProxyType) MarshalJSON() ([]byte, error) {
    b := bytes.NewBufferString(`"`)
	b.WriteString(ProxyType2String[*t])
	b.WriteString(`"`)

	return b.Bytes(), nil
}

// json.Unmarshaler
func (t *ProxyType) UnmarshalJSON(b []byte) error {
    var s string

	err := json.Unmarshal(b, &s)
	if err != nil {
		return err
	}

    *t = String2ProxyType[s]
    return nil
}
