package rows

import (
	"database/sql"

	"github.com/cihangir/gene/example/tinder/models"
)

func ProfileRowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*models.Profile
	for rows.Next() {
		m := models.NewProfile()
		err := rows.Scan(
			&m.ID,
			&m.ScreenName,
			&m.Location,
			&m.Description,
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

	*(dest.(*[]*models.Profile)) = records

	return nil
}
