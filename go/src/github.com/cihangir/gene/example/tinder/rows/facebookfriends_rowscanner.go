package rows

import (
	"database/sql"

	"github.com/cihangir/gene/example/tinder/models"
)

func FacebookFriendsRowsScan(rows *sql.Rows, dest interface{}) error {
	if rows == nil {
		return nil
	}

	var records []*models.FacebookFriends
	for rows.Next() {
		m := models.NewFacebookFriends()
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

	*(dest.(*[]*models.FacebookFriends)) = records

	return nil
}
