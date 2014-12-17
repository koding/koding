package bolt_test

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"runtime"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/boltdb/bolt"
)

var statsFlag = flag.Bool("stats", false, "show performance stats")

// Ensure that opening a database with a bad path returns an error.
func TestOpen_BadPath(t *testing.T) {
	db, err := bolt.Open("", 0666, nil)
	assert(t, err != nil, "err: %s", err)
	assert(t, db == nil, "")
}

// Ensure that a database can be opened without error.
func TestOpen(t *testing.T) {
	path := tempfile()
	defer os.Remove(path)
	db, err := bolt.Open(path, 0666, nil)
	assert(t, db != nil, "")
	ok(t, err)
	equals(t, db.Path(), path)
	ok(t, db.Close())
}

// Ensure that opening an already open database file will timeout.
func TestOpen_Timeout(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("timeout not supported on windows")
	}

	path := tempfile()
	defer os.Remove(path)

	// Open a data file.
	db0, err := bolt.Open(path, 0666, nil)
	assert(t, db0 != nil, "")
	ok(t, err)

	// Attempt to open the database again.
	start := time.Now()
	db1, err := bolt.Open(path, 0666, &bolt.Options{Timeout: 100 * time.Millisecond})
	assert(t, db1 == nil, "")
	equals(t, bolt.ErrTimeout, err)
	assert(t, time.Since(start) > 100*time.Millisecond, "")

	db0.Close()
}

// Ensure that opening an already open database file will wait until its closed.
func TestOpen_Wait(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("timeout not supported on windows")
	}

	path := tempfile()
	defer os.Remove(path)

	// Open a data file.
	db0, err := bolt.Open(path, 0666, nil)
	assert(t, db0 != nil, "")
	ok(t, err)

	// Close it in just a bit.
	time.AfterFunc(100*time.Millisecond, func() { db0.Close() })

	// Attempt to open the database again.
	start := time.Now()
	db1, err := bolt.Open(path, 0666, &bolt.Options{Timeout: 200 * time.Millisecond})
	assert(t, db1 != nil, "")
	ok(t, err)
	assert(t, time.Since(start) > 100*time.Millisecond, "")
}

// Ensure that a re-opened database is consistent.
func TestOpen_Check(t *testing.T) {
	path := tempfile()
	defer os.Remove(path)

	db, err := bolt.Open(path, 0666, nil)
	ok(t, err)
	ok(t, db.View(func(tx *bolt.Tx) error { return <-tx.Check() }))
	db.Close()

	db, err = bolt.Open(path, 0666, nil)
	ok(t, err)
	ok(t, db.View(func(tx *bolt.Tx) error { return <-tx.Check() }))
	db.Close()
}

// Ensure that the database returns an error if the file handle cannot be open.
func TestDB_Open_FileError(t *testing.T) {
	path := tempfile()
	defer os.Remove(path)

	_, err := bolt.Open(path+"/youre-not-my-real-parent", 0666, nil)
	assert(t, err.(*os.PathError) != nil, "")
	equals(t, path+"/youre-not-my-real-parent", err.(*os.PathError).Path)
	equals(t, "open", err.(*os.PathError).Op)
}

// Ensure that write errors to the meta file handler during initialization are returned.
func TestDB_Open_MetaInitWriteError(t *testing.T) {
	t.Skip("pending")
}

// Ensure that a database that is too small returns an error.
func TestDB_Open_FileTooSmall(t *testing.T) {
	path := tempfile()
	defer os.Remove(path)

	db, err := bolt.Open(path, 0666, nil)
	ok(t, err)
	db.Close()

	// corrupt the database
	ok(t, os.Truncate(path, int64(os.Getpagesize())))

	db, err = bolt.Open(path, 0666, nil)
	equals(t, errors.New("file size too small"), err)
}

// TODO(benbjohnson): Test corruption at every byte of the first two pages.

// Ensure that a database cannot open a transaction when it's not open.
func TestDB_Begin_DatabaseNotOpen(t *testing.T) {
	var db bolt.DB
	tx, err := db.Begin(false)
	assert(t, tx == nil, "")
	equals(t, err, bolt.ErrDatabaseNotOpen)
}

// Ensure that a read-write transaction can be retrieved.
func TestDB_BeginRW(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	tx, err := db.Begin(true)
	assert(t, tx != nil, "")
	ok(t, err)
	assert(t, tx.DB() == db.DB, "")
	equals(t, tx.Writable(), true)
	ok(t, tx.Commit())
}

// Ensure that opening a transaction while the DB is closed returns an error.
func TestDB_BeginRW_Closed(t *testing.T) {
	var db bolt.DB
	tx, err := db.Begin(true)
	equals(t, err, bolt.ErrDatabaseNotOpen)
	assert(t, tx == nil, "")
}

// Ensure a database can provide a transactional block.
func TestDB_Update(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	err := db.Update(func(tx *bolt.Tx) error {
		tx.CreateBucket([]byte("widgets"))
		b := tx.Bucket([]byte("widgets"))
		b.Put([]byte("foo"), []byte("bar"))
		b.Put([]byte("baz"), []byte("bat"))
		b.Delete([]byte("foo"))
		return nil
	})
	ok(t, err)
	err = db.View(func(tx *bolt.Tx) error {
		assert(t, tx.Bucket([]byte("widgets")).Get([]byte("foo")) == nil, "")
		equals(t, []byte("bat"), tx.Bucket([]byte("widgets")).Get([]byte("baz")))
		return nil
	})
	ok(t, err)
}

// Ensure a closed database returns an error while running a transaction block
func TestDB_Update_Closed(t *testing.T) {
	var db bolt.DB
	err := db.Update(func(tx *bolt.Tx) error {
		tx.CreateBucket([]byte("widgets"))
		return nil
	})
	equals(t, err, bolt.ErrDatabaseNotOpen)
}

// Ensure a panic occurs while trying to commit a managed transaction.
func TestDB_Update_ManualCommit(t *testing.T) {
	db := NewTestDB()
	defer db.Close()

	var ok bool
	db.Update(func(tx *bolt.Tx) error {
		func() {
			defer func() {
				if r := recover(); r != nil {
					ok = true
				}
			}()
			tx.Commit()
		}()
		return nil
	})
	assert(t, ok, "expected panic")
}

// Ensure a panic occurs while trying to rollback a managed transaction.
func TestDB_Update_ManualRollback(t *testing.T) {
	db := NewTestDB()
	defer db.Close()

	var ok bool
	db.Update(func(tx *bolt.Tx) error {
		func() {
			defer func() {
				if r := recover(); r != nil {
					ok = true
				}
			}()
			tx.Rollback()
		}()
		return nil
	})
	assert(t, ok, "expected panic")
}

// Ensure a panic occurs while trying to commit a managed transaction.
func TestDB_View_ManualCommit(t *testing.T) {
	db := NewTestDB()
	defer db.Close()

	var ok bool
	db.Update(func(tx *bolt.Tx) error {
		func() {
			defer func() {
				if r := recover(); r != nil {
					ok = true
				}
			}()
			tx.Commit()
		}()
		return nil
	})
	assert(t, ok, "expected panic")
}

// Ensure a panic occurs while trying to rollback a managed transaction.
func TestDB_View_ManualRollback(t *testing.T) {
	db := NewTestDB()
	defer db.Close()

	var ok bool
	db.Update(func(tx *bolt.Tx) error {
		func() {
			defer func() {
				if r := recover(); r != nil {
					ok = true
				}
			}()
			tx.Rollback()
		}()
		return nil
	})
	assert(t, ok, "expected panic")
}

// Ensure a write transaction that panics does not hold open locks.
func TestDB_Update_Panic(t *testing.T) {
	db := NewTestDB()
	defer db.Close()

	func() {
		defer func() {
			if r := recover(); r != nil {
				t.Log("recover: update", r)
			}
		}()
		db.Update(func(tx *bolt.Tx) error {
			tx.CreateBucket([]byte("widgets"))
			panic("omg")
		})
	}()

	// Verify we can update again.
	err := db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucket([]byte("widgets"))
		return err
	})
	ok(t, err)

	// Verify that our change persisted.
	err = db.Update(func(tx *bolt.Tx) error {
		assert(t, tx.Bucket([]byte("widgets")) != nil, "")
		return nil
	})
}

// Ensure a database can return an error through a read-only transactional block.
func TestDB_View_Error(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	err := db.View(func(tx *bolt.Tx) error {
		return errors.New("xxx")
	})
	equals(t, errors.New("xxx"), err)
}

// Ensure a read transaction that panics does not hold open locks.
func TestDB_View_Panic(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	db.Update(func(tx *bolt.Tx) error {
		tx.CreateBucket([]byte("widgets"))
		return nil
	})

	func() {
		defer func() {
			if r := recover(); r != nil {
				t.Log("recover: view", r)
			}
		}()
		db.View(func(tx *bolt.Tx) error {
			assert(t, tx.Bucket([]byte("widgets")) != nil, "")
			panic("omg")
		})
	}()

	// Verify that we can still use read transactions.
	db.View(func(tx *bolt.Tx) error {
		assert(t, tx.Bucket([]byte("widgets")) != nil, "")
		return nil
	})
}

// Ensure that an error is returned when a database write fails.
func TestDB_Commit_WriteFail(t *testing.T) {
	t.Skip("pending") // TODO(benbjohnson)
}

// Ensure that DB stats can be returned.
func TestDB_Stats(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucket([]byte("widgets"))
		return err
	})
	stats := db.Stats()
	equals(t, 2, stats.TxStats.PageCount)
	equals(t, 0, stats.FreePageN)
	equals(t, 2, stats.PendingPageN)
}

// Ensure that database pages are in expected order and type.
func TestDB_Consistency(t *testing.T) {
	db := NewTestDB()
	defer db.Close()
	db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucket([]byte("widgets"))
		return err
	})

	for i := 0; i < 10; i++ {
		db.Update(func(tx *bolt.Tx) error {
			ok(t, tx.Bucket([]byte("widgets")).Put([]byte("foo"), []byte("bar")))
			return nil
		})
	}
	db.Update(func(tx *bolt.Tx) error {
		p, _ := tx.Page(0)
		assert(t, p != nil, "")
		equals(t, "meta", p.Type)

		p, _ = tx.Page(1)
		assert(t, p != nil, "")
		equals(t, "meta", p.Type)

		p, _ = tx.Page(2)
		assert(t, p != nil, "")
		equals(t, "free", p.Type)

		p, _ = tx.Page(3)
		assert(t, p != nil, "")
		equals(t, "free", p.Type)

		p, _ = tx.Page(4)
		assert(t, p != nil, "")
		equals(t, "leaf", p.Type)

		p, _ = tx.Page(5)
		assert(t, p != nil, "")
		equals(t, "freelist", p.Type)

		p, _ = tx.Page(6)
		assert(t, p == nil, "")
		return nil
	})
}

// Ensure that DB stats can be substracted from one another.
func TestDBStats_Sub(t *testing.T) {
	var a, b bolt.Stats
	a.TxStats.PageCount = 3
	a.FreePageN = 4
	b.TxStats.PageCount = 10
	b.FreePageN = 14
	diff := b.Sub(&a)
	equals(t, 7, diff.TxStats.PageCount)
	// free page stats are copied from the receiver and not subtracted
	equals(t, 14, diff.FreePageN)
}

func ExampleDB_Update() {
	// Open the database.
	db, _ := bolt.Open(tempfile(), 0666, nil)
	defer os.Remove(db.Path())
	defer db.Close()

	// Execute several commands within a write transaction.
	err := db.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucket([]byte("widgets"))
		if err != nil {
			return err
		}
		if err := b.Put([]byte("foo"), []byte("bar")); err != nil {
			return err
		}
		return nil
	})

	// If our transactional block didn't return an error then our data is saved.
	if err == nil {
		db.View(func(tx *bolt.Tx) error {
			value := tx.Bucket([]byte("widgets")).Get([]byte("foo"))
			fmt.Printf("The value of 'foo' is: %s\n", value)
			return nil
		})
	}

	// Output:
	// The value of 'foo' is: bar
}

func ExampleDB_View() {
	// Open the database.
	db, _ := bolt.Open(tempfile(), 0666, nil)
	defer os.Remove(db.Path())
	defer db.Close()

	// Insert data into a bucket.
	db.Update(func(tx *bolt.Tx) error {
		tx.CreateBucket([]byte("people"))
		b := tx.Bucket([]byte("people"))
		b.Put([]byte("john"), []byte("doe"))
		b.Put([]byte("susy"), []byte("que"))
		return nil
	})

	// Access data from within a read-only transactional block.
	db.View(func(tx *bolt.Tx) error {
		v := tx.Bucket([]byte("people")).Get([]byte("john"))
		fmt.Printf("John's last name is %s.\n", v)
		return nil
	})

	// Output:
	// John's last name is doe.
}

func ExampleDB_Begin_ReadOnly() {
	// Open the database.
	db, _ := bolt.Open(tempfile(), 0666, nil)
	defer os.Remove(db.Path())
	defer db.Close()

	// Create a bucket.
	db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucket([]byte("widgets"))
		return err
	})

	// Create several keys in a transaction.
	tx, _ := db.Begin(true)
	b := tx.Bucket([]byte("widgets"))
	b.Put([]byte("john"), []byte("blue"))
	b.Put([]byte("abby"), []byte("red"))
	b.Put([]byte("zephyr"), []byte("purple"))
	tx.Commit()

	// Iterate over the values in sorted key order.
	tx, _ = db.Begin(false)
	c := tx.Bucket([]byte("widgets")).Cursor()
	for k, v := c.First(); k != nil; k, v = c.Next() {
		fmt.Printf("%s likes %s\n", k, v)
	}
	tx.Rollback()

	// Output:
	// abby likes red
	// john likes blue
	// zephyr likes purple
}

// TestDB represents a wrapper around a Bolt DB to handle temporary file
// creation and automatic cleanup on close.
type TestDB struct {
	*bolt.DB
}

// NewTestDB returns a new instance of TestDB.
func NewTestDB() *TestDB {
	db, err := bolt.Open(tempfile(), 0666, nil)
	if err != nil {
		panic("cannot open db: " + err.Error())
	}
	return &TestDB{db}
}

// Close closes the database and deletes the underlying file.
func (db *TestDB) Close() {
	// Log statistics.
	if *statsFlag {
		db.PrintStats()
	}

	// Check database consistency after every test.
	db.MustCheck()

	// Close database and remove file.
	defer os.Remove(db.Path())
	db.DB.Close()
}

// PrintStats prints the database stats
func (db *TestDB) PrintStats() {
	var stats = db.Stats()
	fmt.Printf("[db] %-20s %-20s %-20s\n",
		fmt.Sprintf("pg(%d/%d)", stats.TxStats.PageCount, stats.TxStats.PageAlloc),
		fmt.Sprintf("cur(%d)", stats.TxStats.CursorCount),
		fmt.Sprintf("node(%d/%d)", stats.TxStats.NodeCount, stats.TxStats.NodeDeref),
	)
	fmt.Printf("     %-20s %-20s %-20s\n",
		fmt.Sprintf("rebal(%d/%v)", stats.TxStats.Rebalance, truncDuration(stats.TxStats.RebalanceTime)),
		fmt.Sprintf("spill(%d/%v)", stats.TxStats.Spill, truncDuration(stats.TxStats.SpillTime)),
		fmt.Sprintf("w(%d/%v)", stats.TxStats.Write, truncDuration(stats.TxStats.WriteTime)),
	)
}

// MustCheck runs a consistency check on the database and panics if any errors are found.
func (db *TestDB) MustCheck() {
	db.View(func(tx *bolt.Tx) error {
		// Collect all the errors.
		var errors []error
		for err := range tx.Check() {
			errors = append(errors, err)
			if len(errors) > 10 {
				break
			}
		}

		// If errors occurred, copy the DB and print the errors.
		if len(errors) > 0 {
			var path = tempfile()
			tx.CopyFile(path, 0600)

			// Print errors.
			fmt.Print("\n\n")
			fmt.Printf("consistency check failed (%d errors)\n", len(errors))
			for _, err := range errors {
				fmt.Println(err)
			}
			fmt.Println("")
			fmt.Println("db saved to:")
			fmt.Println(path)
			fmt.Print("\n\n")
			os.Exit(-1)
		}

		return nil
	})
}

// CopyTempFile copies a database to a temporary file.
func (db *TestDB) CopyTempFile() {
	path := tempfile()
	db.View(func(tx *bolt.Tx) error { return tx.CopyFile(path, 0600) })
	fmt.Println("db copied to: ", path)
}

// tempfile returns a temporary file path.
func tempfile() string {
	f, _ := ioutil.TempFile("", "bolt-")
	f.Close()
	os.Remove(f.Name())
	return f.Name()
}

// mustContainKeys checks that a bucket contains a given set of keys.
func mustContainKeys(b *bolt.Bucket, m map[string]string) {
	found := make(map[string]string)
	b.ForEach(func(k, _ []byte) error {
		found[string(k)] = ""
		return nil
	})

	// Check for keys found in bucket that shouldn't be there.
	var keys []string
	for k, _ := range found {
		if _, ok := m[string(k)]; !ok {
			keys = append(keys, k)
		}
	}
	if len(keys) > 0 {
		sort.Strings(keys)
		panic(fmt.Sprintf("keys found(%d): %s", len(keys), strings.Join(keys, ",")))
	}

	// Check for keys not found in bucket that should be there.
	for k, _ := range m {
		if _, ok := found[string(k)]; !ok {
			keys = append(keys, k)
		}
	}
	if len(keys) > 0 {
		sort.Strings(keys)
		panic(fmt.Sprintf("keys not found(%d): %s", len(keys), strings.Join(keys, ",")))
	}
}

func trunc(b []byte, length int) []byte {
	if length < len(b) {
		return b[:length]
	}
	return b
}

func truncDuration(d time.Duration) string {
	return regexp.MustCompile(`^(\d+)(\.\d+)`).ReplaceAllString(d.String(), "$1")
}
