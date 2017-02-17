package modeltesthelper

import (
	"os"
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

// NewMongoDB looks up environment variable for mongo configuration
// URL. If configuration is found, this function creates a new session
// and replaces modeltesthelper Mongo singleton. If not, fails the
// test.
//
// Test will Fatal if connection to database is broken.
func NewMongoDB(t *testing.T) *MongoDB {
	mongoURL := os.Getenv("KONFIG_MONGO")
	if mongoURL == "" {
		t.Fatalf("error: KONFIG_MONGO is not set")
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
