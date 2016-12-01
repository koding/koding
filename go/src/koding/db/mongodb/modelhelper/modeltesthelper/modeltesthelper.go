package modeltesthelper

import (
	"os"
	"strings"
	"testing"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
)

// MongoDB is a Mongo database helper which is used for mongo-related tests.
type MongoDB struct {
	// DB stores a database session which was used as a replacement for database
	// singleton object.
	DB *mongodb.MongoDB
}

var mongoEnvs = []string{
	"WERCKER_MONGODB_URL",
	"MONGODB_URL",
}

// NewMongoDB looks up environment variables for mongo configuration URL. If
// configuration is found, this function creates a new session and replaces
// modeltesthelper Mongo singleton. If not, fails the test.
//
// Test will Fatal if connection to database is broken.
func NewMongoDB(t *testing.T) *MongoDB {
	var mongoURL string
	for _, mongoEnv := range mongoEnvs {
		if mongoURL = os.Getenv(mongoEnv); mongoURL != "" {
			break
		}
	}

	if mongoURL == "" {
		t.Fatalf("mongodb: one of env variables must be set: %s", strings.Join(mongoEnvs, ", "))
	}

	modelhelper.Initialize(mongoURL)

	m := &MongoDB{DB: modelhelper.Mongo}
	if err := m.DB.Session.Ping(); err != nil {
		t.Fatalf("mongodb: cannot connect to %s: %v", mongoURL, err)
	}

	return m
}

// Close closes underlying session to mongo database.
func (m *MongoDB) Close() {
	if m.DB != nil {
		m.DB.Close()
	}
}
