package logrotate_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"koding/klient/storage"
	"koding/logrotate"
)

const n = logrotate.DefaultChecksumSize

var (
	content = strings.Repeat("a", n/2) +
		strings.Repeat("b", n/2) +
		strings.Repeat("C", n) +
		strings.Repeat("D", n)

	parts = []*logrotate.MetadataPart{{
		Offset:       0,
		Size:         n / 2,
		Checksum:     sum(content[:n/2]),
		ChecksumSize: n / 2,
	}, {
		Offset:       n / 2,
		Size:         n,
		Checksum:     sum(content[:n]),
		ChecksumSize: n,
	}, {
		Offset:       n,
		Size:         2 * n,
		Checksum:     sum(content[n : 2*n]),
		ChecksumSize: n,
	}, {
		Offset:       2 * n,
		Size:         3 * n,
		Checksum:     sum(content[2*n : 3*n]),
		ChecksumSize: n,
	}}
)

func TestLogrotate_Rotate(t *testing.T) {
	meta := &logrotate.Metadata{
		Key: "test",
	}

	// Ensure logrotate.Rotate finds correct
	// size and offset of the parts.
	for i, part := range parts {
		c := reader(0, part.Size)
		want := reader(part.Offset, part.Size)

		p, err := logrotate.Rotate(c, meta)
		if err != nil {
			t.Fatalf("%d: Rotate()=%s", i, err)
		}

		if p.Size != part.Size {
			t.Fatalf("%d: got p.Size=%d; want %d", i, p.Size, part.Size)
		}

		if p.Offset != part.Offset {
			t.Fatalf("%d: got p.Offset=%d; want %d", i, p.Offset, part.Offset)
		}

		if err := equal(c, want); err != nil {
			t.Fatalf("%d: %s", i, err)
		}

		meta.Parts = append(meta.Parts, part)
	}

	// If the same content is passed, Rotate should be a nop.
	c := reader(0, int64(len(content)))

	_, err := logrotate.Rotate(c, meta)
	e, ok := err.(*logrotate.NopError)
	if !ok {
		t.Fatalf("err expected to be %T, was %T", (*logrotate.NopError)(nil), err)
	}

	if e.Key != meta.Key {
		t.Fatalf("got %q, want %q", e.Key, meta.Key)
	}

	if n := len(parts); e.N != n {
		t.Fatalf("got %d, want %d", e.N, n)
	}

	// If new content is passed, checksum check should fail and
	// new part returned (no rotation).
	c = reader(1, 2*n+1)

	p, err := logrotate.Rotate(c, meta)
	if err != nil {
		t.Fatalf("Rotate()=%s", err)
	}

	if p.Offset != 0 {
		t.Fatalf("got p.Offset=%d, want 0", p.Offset)
	}

	if p.Size != 2*n {
		t.Fatalf("got p.Size=%d, want %d", p.Size, 2*n)
	}
}

func TestLogrotate_Upload(t *testing.T) {
	ub := make(UserBucket)
	m := storage.NewMemoryStorage()

	l := &logrotate.Uploader{
		UserBucket: ub,
		MetaStore: &storage.EncodingStorage{
			Interface: m,
		},
	}

	for i, part := range parts {
		c := reader(0, part.Size)

		if _, err := l.Upload("content", c); err != nil {
			t.Fatalf("%d: Put()=%s", i, err)
		}

		key := fmt.Sprintf("content.gz.%d", i)

		p, ok := ub[key]
		if !ok {
			t.Fatalf("%d: %q does not exist", i, key)
		}

		got := bytes.NewReader(p)
		want := reader(part.Offset, part.Size)

		if err := equal(got, want); err != nil {
			t.Fatalf("%d: %s", i, err)
		}
	}

	if len(ub) != len(parts) {
		t.Fatalf("got %d, want %d", len(ub), len(parts))
	}

	for name, s := range m.M {
		var meta logrotate.Metadata

		if err := json.Unmarshal([]byte(s), &meta); err != nil {
			t.Errorf("%s: Unmarshal()=%s", name, err)
			continue
		}

		for i, p := range meta.Parts {
			if p.Size == 0 {
				t.Errorf("%s: %d: want p.Size != 0", name, i)
				continue
			}

			if p.CompressedSize == 0 {
				t.Errorf("%s: %d: want p.CompressedSize != 0", name, i)
				continue
			}

			if p.Checksum == "" {
				t.Errorf(`%s: %d: want p.Checksum != ""`, name, i)
				continue
			}

			if p.Size <= p.CompressedSize {
				t.Errorf("%s: %d: want p.Size=%d > p.CompressedSize=%d", name, i, p.Size, p.CompressedSize)
				continue
			}
		}
	}
}
