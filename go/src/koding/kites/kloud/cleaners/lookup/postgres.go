package lookup

import (
	"database/sql"
	"fmt"

	sq "github.com/lann/squirrel"
	_ "github.com/lib/pq"
)

type PostgresConfig struct {
	Host     string `default:"localhost"`
	Port     int    `default:"5432"`
	Username string `required:"true"`
	Password string `required:"true"`
	DBName   string `required:"true" `
}

type Postgres struct {
	DB *sql.DB
}

func NewPostgres(conf *PostgresConfig) *Postgres {
	connString := fmt.Sprintf(
		"host=%s port=%d dbname=%s user=%s password=%s sslmode=disable",
		conf.Host, conf.Port, conf.DBName, conf.Username, conf.Password,
	)

	db, err := sql.Open("postgres", connString)
	if err != nil {
		panic(err)
	}

	return &Postgres{
		DB: db,
	}
}

// PayingCustomers returns the list of MongoDB account ids of all active paying
// customers
func (p *Postgres) PayingCustomers() ([]string, error) {
	// The SQL query below returns us a list of all 'active' paying custormers
	// account ids:
	// select payment.customer.old_id from payment.subscription, payment.customer
	// where payment.subscription.customer_id = payment.customer.id and
	// payment.subscription.state = 'active';
	psql := sq.StatementBuilder.PlaceholderFormat(sq.Dollar)

	customers := psql.Select("payment.customer.old_id").From("payment.subscription, payment.customer")
	active := customers.Where("payment.subscription.customer_id = payment.customer.id").
		Where("payment.subscription.state = 'active'")

	sql, args, err := active.ToSql()
	if err != nil {
		return nil, err
	}

	rows, err := p.DB.Query(sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	oids := make([]string, 0)

	for rows.Next() {
		var oid string
		if err := rows.Scan(&oid); err != nil {
			return nil, err
		}

		oids = append(oids, oid)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return oids, nil
}
