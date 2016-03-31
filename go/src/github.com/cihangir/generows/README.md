[![GoDoc](https://godoc.org/github.com/cihangir/generows?status.svg)](https://godoc.org/github.com/cihangir/generows)
[![Build Status](https://travis-ci.org/cihangir/generows.svg)](https://travis-ci.org/cihangir/generows)

# generows

Json-schema based database rows to arbitrary struct scanner generation with Go (golang).
It is based on database/sql so it works with all database drivers

## Why Code Generation?

Whenever a bootstrap is required for a project we are hustling with creating the
required folder, files, databases, roles/users schemas, sequences, tables,
constraints, extensions types etc...

This package aims to ease that pain

## What is JSON-Schema?

JSON Schema specifies a JSON-based format to define the structure of your data
for various cases, like validation, documentation, and interaction control.  A
JSON Schema provides a contract for the JSON data required by a given
application, and how that data can be modified.

TLDR: here is an example [twitter.json](https://github.com/cihangir/gene/blob/master/example/twitter.json#L198)

## Where is sample output?

Right here [twitter/models/account_rowscanner](https://github.com/cihangir/gene/blob/master/example/twitter/models/account_rowscanner.go)

```go
package models

import "database/sql"

func (a *Account) RowsScan(rows *sql.Rows, dest interface{}) error {
    if rows == nil {
        return nil
    }

    var records []*Account
    for rows.Next() {
        m := NewAccount()
        err := rows.Scan(
            &m.ID,
            &m.ProfileID,
            &m.Password,
            &m.URL,
            &m.PasswordStatusConstant,
            &m.Salt,
            &m.EmailAddress,
            &m.EmailStatusConstant,
            &m.StatusConstant,
            &m.CreatedAt,
        )
        if err != nil {
            return err
        }
        records = append(records, m)
    }

    if err := rows.Err(); err != nil {
        return err
    }

    *(dest.(*[]*Account)) = records

    return nil
}
```
