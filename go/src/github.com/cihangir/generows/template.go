package generows

// RowScannerTemplate provides the template for rowscanner of models
var RowScannerTemplate = `
{{$schema := .Schema}}
{{$title := $schema.Title}}
package models

func ({{Pointerize $title}} *{{$title}}) RowsScan(rows *sql.Rows, dest interface{}) error {
    if rows == nil {
        return nil
    }

    var records []*{{ToUpperFirst $title}}
    for rows.Next() {
        m := New{{ToUpperFirst $title}}()
        err := rows.Scan(
        {{range $n, $p := SortedSchema $schema.Properties}} &m.{{DepunctWithInitialUpper $p.Title}},
        {{end}} )
        if err != nil {
            return err
        }
        records = append(records, m)
    }

    if err := rows.Err(); err != nil {
        return err
    }

    *(dest.(*[]*{{ToUpperFirst $title}})) = records

    return nil
}
`
