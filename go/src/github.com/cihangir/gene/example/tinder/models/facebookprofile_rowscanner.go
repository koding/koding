package models

import "database/sql"

func (f *FacebookProfile) RowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*FacebookProfile
	for rows.Next() {
		m := NewFacebookProfile()
		err := rows.Scan(
			&m.ID,
			&m.FirstName,
			&m.MiddleName,
			&m.LastName,
			&m.PictureURL,
		)
		if err != nil {
			return err
		}
		records = append(records, m)
	}

	if err := rows.Err(); err != nil {
		return err
	}

	*(dest.(*[]*FacebookProfile)) = records

	return nil
}
