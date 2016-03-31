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
			&m.FacebookID,
			&m.FacebookAccessToken,
			&m.FacebookSecretToken,
			&m.EmailAddress,
			&m.EmailStatusConstant,
			&m.StatusConstant,
			&m.CreatedAt,
			&m.UpdatedAt,
			&m.DeletedAt,
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
