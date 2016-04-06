package rows

import (
	"database/sql"

	"github.com/cihangir/gene/example/tinder/models"
)

func AccountRowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*models.Account
	for rows.Next() {
		m := models.NewAccount()
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

	*(dest.(*[]*models.Account)) = records

	return nil
}
