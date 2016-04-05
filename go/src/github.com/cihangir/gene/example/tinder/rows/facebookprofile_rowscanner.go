package rows

import (
	"database/sql"

	"github.com/cihangir/gene/example/tinder/models"
)

func FacebookProfileRowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*models.FacebookProfile
	for rows.Next() {
		m := models.NewFacebookProfile()
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

	*(dest.(*[]*models.FacebookProfile)) = records

	return nil
}
