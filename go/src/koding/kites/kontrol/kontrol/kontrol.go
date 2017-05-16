package kontrol

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	konfig "koding/kites/config"
	"koding/kites/metrics"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"gopkg.in/throttled/throttled.v2"
	"gopkg.in/throttled/throttled.v2/store/memstore"
)

const Name = "kontrol"
const Version = "0.0.6"

func New(c *Config) *kontrol.Kontrol {
	modelhelper.Initialize(c.MongoURL)

	publicKey, err := ioutil.ReadFile(FindPath(c.PublicKey))
	if err != nil {
		log.Fatalln(err.Error())
	}

	privateKey, err := ioutil.ReadFile(FindPath(c.PrivateKey))
	if err != nil {
		log.Fatalln(err.Error())
	}

	kiteConf, err := konfig.ReadKiteConfig(c.Debug)
	if err != nil {
		panic(err)
	}

	if c.Environment != "" {
		kiteConf.Environment = c.Environment
	}

	if c.Region != "" {
		kiteConf.Region = c.Region
	}

	if c.Port != 0 {
		kiteConf.Port = c.Port
	}

	// TODO: Move the metrics instance somewhere meaningful
	met := common.MustInitMetrics(Name)

	kon := kontrol.NewWithoutHandlers(kiteConf, Version)
	kon.TokenNoNBF = true

	kon.Kite.HandleFunc("register",
		metrics.WrapKiteHandler(met, "HandleRegister", kon.HandleRegister),
	)

	kon.Kite.HandleFunc("registerMachine",
		metrics.WrapKiteHandler(met, "HandleMachine", kon.HandleMachine),
	).DisableAuthentication()

	kon.Kite.HandleFunc("getKodingKites",
		metrics.WrapKiteHandler(
			met, "HandleGetKodingKites", HandleGetKodingKites(kon.HandleGetKites, kiteConf.Environment),
		),
	)

	kon.Kite.HandleFunc("getKites",
		metrics.WrapKiteHandler(met, "HandleGetKites", kon.HandleGetKites),
	)
	kon.Kite.HandleFunc("getToken",
		metrics.WrapKiteHandler(met, "HandleGetToken", kon.HandleGetToken),
	)
	kon.Kite.HandleFunc("getKey",
		metrics.WrapKiteHandler(met, "HandleGetKey", kon.HandleGetKey),
	)

	kon.Kite.HandleHTTPFunc("/heartbeat",
		metrics.WrapHTTPHandler(met, "HandleHeartbeat", kon.HandleHeartbeat),
	)

	kon.Kite.HandleHTTP("/register", throttledHandler(
		metrics.WrapHTTPHandler(met, "HandleRegisterHTTP", kon.HandleRegisterHTTP),
	))

	kon.AddAuthenticator("sessionID", authenticateFromSessionID)
	kon.MachineAuthenticate = authenticateMachine

	switch c.Storage {
	case "etcd":
		kon.SetStorage(kontrol.NewEtcd(c.Machines, kon.Kite.Log))
	case "postgres":
		postgresConf := &kontrol.PostgresConfig{
			Host:     c.Postgres.Host,
			Port:     c.Postgres.Port,
			Username: c.Postgres.Username,
			Password: c.Postgres.Password,
			DBName:   c.Postgres.DBName,
		}
		p := kontrol.NewPostgres(postgresConf, kon.Kite.Log)
		p.DB.SetMaxOpenConns(20)
		kon.SetStorage(p)

		s := kontrol.NewCachedStorage(
			p,
			kontrol.NewMemKeyPairStorageTTL(time.Minute*5),
		)
		kon.SetKeyPairStorage(s)
		// kon.MachineKeyPicker = newMachineKeyPicker(p)
	default:
		panic(fmt.Sprintf("storage is not found: %q", c.Storage))
	}

	kon.AddKeyPair("", string(publicKey), string(privateKey))

	if c.TLSKeyFile != "" && c.TLSCertFile != "" {
		kon.Kite.UseTLSFile(c.TLSCertFile, c.TLSKeyFile)
	}

	return kon
}

func throttledHandler(h http.HandlerFunc) http.Handler {
	// for now just use an inmemory storage, so per server. In the future we
	// can change to store the state on a remote DB if we want to distribute
	// the counts
	store, err := memstore.New(65536)
	if err != nil {
		// panics only if memstore.New() receives an integer number, so this is
		// OK, this means it's a human error and needs to be fixed
		log.Fatal(err)
	}

	// Based on datadog metrics, kloud.info is called on average 200
	// req/minute.
	quota := throttled.RateQuota{
		MaxRate:  throttled.PerMin(200),
		MaxBurst: 300,
	}

	rateLimiter, err := throttled.NewGCRARateLimiter(store, quota)
	if err != nil {
		// we exit because this is code error and must be handled
		log.Fatalln(err)
	}

	httpRateLimiter := throttled.HTTPRateLimiter{
		RateLimiter: rateLimiter,
	}

	return httpRateLimiter.RateLimit(http.HandlerFunc(h))
}

// func newMachineKeyPicker(pg *kontrol.Postgres) func(*kite.Request) (*kontrol.KeyPair, error) {
// 	return func(r *kite.Request) (*kontrol.KeyPair, error) {
// 		psql := sq.StatementBuilder.PlaceholderFormat(sq.Dollar)
// 		sqlQuery, args, err := psql.
// 			Select("id", "public", "private").
// 			From("kite.key").
// 			Where(map[string]interface{}{"deleted_at": nil}).
// 			OrderBy("created_at desc").
// 			ToSql()
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		fmt.Printf("sqlQuery = %+v\n", sqlQuery)
// 		fmt.Printf("args = %+v\n", args)
//
// 		keyPair := &kontrol.KeyPair{}
// 		err = pg.DB.QueryRow(sqlQuery, args...).Scan(&keyPair.ID, &keyPair.Public, &keyPair.Private)
// 		if err != nil {
// 			if err == sql.ErrNoRows {
// 				return nil, kontrol.ErrNoKeyFound
// 			}
// 			return nil, err
// 		}
//
// 		return keyPair, nil
// 	}
// }

func authenticateFromSessionID(r *kite.Request) error {
	username, err := findUsernameFromSessionID(r.Auth.Key)
	if err != nil {
		return err
	}

	r.Username = username

	return nil
}

func findUsernameFromSessionID(sessionID string) (string, error) {
	session, err := modelhelper.GetSession(sessionID)
	if err != nil {
		return "", err
	}

	return session.Username, nil
}

func authenticateMachine(authType string, r *kite.Request) error {
	switch authType {
	case "password":
		password, err := r.Client.TellWithTimeout(
			"kite.getPass",
			10*time.Minute,
			"Enter password: ",
		)

		if err != nil {
			return err
		}

		_, err = modelhelper.CheckAndGetUser(r.Client.Kite.Username, password.MustString())
		if err != nil {
			return err
		}
	case "token":
		var args struct {
			Token string
		}

		if err := r.Args.One().Unmarshal(&args); err != nil {
			return err
		}

		if args.Token == "" {
			return errors.New("token is empty")
		}

		// Try to fetch the token and remove it. If it doesn't exist it'll will
		// return an error. If it's exist it'll be deleted and a nil error
		// (means success) will be returned. The underlying implementation uses
		// findAndModify so it's consistent across each kontrol.
		session, err := modelhelper.GetSessionFromToken(args.Token)
		if err != nil {
			return err
		}

		if err := modelhelper.RemoveToken(session.ClientId); err != nil {
			return err
		}

		// prevent using a wrong username
		r.Client.Kite.Username = session.Username
		r.Client.Username = session.Username
		return nil
	default:
		return errors.New("authentication type for machine registration is not defined")
	}

	// everything is ok, succefully validated
	return nil
}
