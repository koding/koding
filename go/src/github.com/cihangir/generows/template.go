package generows

// RowScannerTemplate provides the template for rowscanner of models
var RowScannerTemplate = `
{{$schema := .Schema}}
{{$title := $schema.Title}}
package rows

func {{$title}}RowsScan(rows *sql.Rows, dest interface{}) error {
    if rows == nil {
        return nil
    }

    var records []*models.{{ToUpperFirst $title}}
    for rows.Next() {
        m := models.New{{ToUpperFirst $title}}()
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

    *(dest.(*[]*models.{{ToUpperFirst $title}})) = records

    return nil
}
`
