package metrics

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"errors"
	"io"
)

// GzippedPayload holds metric payload in a gzipped format.
type GzippedPayload [][]byte

// MarshalJSON implements json.Marshaler interface.
func (m GzippedPayload) MarshalJSON() ([]byte, error) {
	if m == nil {
		return []byte("null"), nil
	}

	data := [][]byte(m)

	gz, err := writeGzip(data)
	if err != nil {
		return nil, err
	}

	// Marshal here to escape non-json chars
	return json.Marshal(gz)
}

// UnmarshalJSON implements json.Unmarshaler interface.
func (m *GzippedPayload) UnmarshalJSON(data []byte) error {
	if m == nil {
		return errors.New("GzippedPayload: UnmarshalJSON on nil pointer")
	}

	// get our gzipped byte slice back.
	var v []byte
	if err := json.Unmarshal(data, &v); err != nil {
		return err
	}

	if v == nil {
		return nil
	}

	d, err := readGzip(v)
	if err != nil {
		return err
	}

	*m = GzippedPayload(d)
	return nil
}

func writeGzip(data [][]byte) ([]byte, error) {
	var buf bytes.Buffer
	zw := gzip.NewWriter(&buf)

	// store length of the messages, we will need them while Unmarshaling
	lens := make([]int, len(data))
	for i, d := range data {
		lens[i] = len(d)
	}

	mlens, err := json.Marshal(lens)
	if err != nil {
		return nil, err
	}
	zw.Header.Extra = mlens

	for _, d := range data {
		if _, err := zw.Write(d); err != nil {
			return nil, err
		}
	}

	if err := zw.Close(); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func readGzip(data []byte) ([][]byte, error) {
	zr, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	if _, err := io.Copy(&buf, zr); err != nil {
		return nil, err
	}

	if err := zr.Close(); err != nil {
		return nil, err
	}

	var lens []int
	if err := json.Unmarshal(zr.Header.Extra, &lens); err != nil {
		return nil, err
	}

	byt := buf.Bytes()

	res := make([][]byte, len(lens))
	offset := 0
	for i, l := range lens {
		b := make([]byte, l)
		copy(b, byt[offset:offset+l])
		res[i] = b
		offset += l
	}

	return res, nil
}
