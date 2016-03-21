package models

import "database/sql"

func (f *FacebookFriends) RowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*FacebookFriends
	for rows.Next() {
		m := NewFacebookFriends()
		err := rows.Scan(
			&m.SourceID,
			&m.TargetID,
		)
		if err != nil {
			return err
		}
		records = append(records, m)
	}

	if err := rows.Err(); err != nil {
		return err
	}

	*(dest.(*[]*FacebookFriends)) = records

	return nil
}
