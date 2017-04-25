package proxy

import (
    "github.com/boltdb/bolt"
)

type Options struct {
    DB      *bolt.DB    `json:"-"`
    Type    ProxyType   `json:"type"`
}
