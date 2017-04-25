package proxy

import (
    "bytes"
    "encoding/json"
)

type ProxyType int

const (
    Local ProxyType = iota
    Docker
    Kubernetes
)

var ProxyType2String = map[ProxyType]string{
    Local:      "local",
    Docker:     "docker",
    Kubernetes: "kubernetes",
}

var String2ProxyType = map[string]ProxyType{
    "local":        Local,
    "docker":       Docker,
    "kubernetes":   Kubernetes,
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
