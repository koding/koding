package nisql

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	_ "github.com/lib/pq"
)

type nullable struct {
	StringNVal NullString
	StringVal  string

	Int64NVal NullInt64
	Int64Val  int64

	Float64NVal NullFloat64
	Float64Val  float64

	BoolNVal NullBool
	BoolVal  bool

	TimeNVal NullTime
	TimeVal  time.Time
}

func TestInit(t *testing.T) {
	db, err := sql.Open(
		os.Getenv("NISQL_TEST_DIALECT"),
		os.Getenv("NISQL_TEST_DSN"),
	)
	if err != nil {
		t.Fatalf("err while creating connection: %s", err.Error())
	}

	sql := `CREATE TABLE nullable (
    string_n_val VARCHAR (255) DEFAULT NULL,
    string_val VARCHAR (255) DEFAULT 'empty',
    int64_n_val BIGINT DEFAULT NULL,
    int64_val BIGINT DEFAULT 1,
    float64_n_val NUMERIC DEFAULT NULL,
    float64_val NUMERIC DEFAULT 1,
    bool_n_val BOOLEAN,
    bool_val BOOLEAN NOT NULL,
    time_n_val timestamp,
    time_val timestamp NOT NULL
)`

	if _, err = db.Exec(sql); err != nil {
		t.Fatalf("err while creating table: %s", err.Error())
	}

	sql = `INSERT INTO nullable
VALUES
    (
        NULL,
        'NULLABLE',
        NULL,
        42,
        NULL,
        12,
        NULL,
        true,
        NULL,
        NOW()
    )`

	if _, err := db.Exec(sql); err != nil {
		t.Fatalf("err while adding null item: %s", err.Error())
	}

	n := &nullable{}
	err = db.QueryRow("SELECT * FROM nullable").
		Scan(&n.StringNVal,
		&n.StringVal,
		&n.Int64NVal,
		&n.Int64Val,
		&n.Float64NVal,
		&n.Float64Val,
		&n.BoolNVal,
		&n.BoolVal,
		&n.TimeNVal,
		&n.TimeVal,
	)
	if err != nil {
		t.Fatalf(err.Error())
	}

	if n.StringVal != "NULLABLE" {
		t.Fatalf("expected NULLABLE, got: ", n.StringVal)
	}

	if n.StringNVal.Valid {
		t.Fatalf("expected invalid, got valid for string_n_val")
	}

	if n.Int64Val != int64(42) {
		t.Fatalf("expected 42, got: %d", n.Int64Val)
	}

	if n.Int64NVal.Valid {
		t.Fatalf("expected invalid, got valid for int64_n_val")
	}

	if n.Float64Val != float64(12) {
		t.Fatalf("expected 12, got: %f", n.Float64Val)
	}

	if n.Float64NVal.Valid {
		t.Fatalf("expected invalid, got valid for float64_n_val")
	}

	if n.BoolVal != true {
		t.Fatalf("expected true, got: %t", n.BoolVal)
	}

	if n.BoolNVal.Valid {
		t.Fatalf("expected invalid, got valid for bool_n_val")
	}

	if n.TimeNVal.Valid {
		t.Fatalf("expected false, got: %t", n.TimeNVal)
	}

	if n.TimeVal.IsZero() {
		t.Fatalf("expected valid, got invalid for TimeVal: %+v", n.TimeVal)
	}

	if _, err := db.Exec("DELETE FROM nullable"); err != nil {
		t.Fatalf("err while clearing nullable table: %s", err.Error())
	}

	testGetNil(t, n)
}

func dummy(now time.Time) *nullable {
	return &nullable{
		StringNVal: String("string_n_val"),
		StringVal:  "string_val",

		Int64NVal: Int64(123),

		Int64Val: int64(123),

		Float64NVal: Float64(12),
		Float64Val:  float64(12),

		BoolNVal: Bool(true),
		BoolVal:  true,

		TimeNVal: Time(now),
		TimeVal:  now,
	}
}

func TestMarshal(t *testing.T) {
	now := time.Now().UTC()
	nset := dummy(now)

	allSetRes, err := json.Marshal(nset)
	if err != nil {
		t.Fatalf("err while marshaling: %s", err.Error())
	}

	// test all-set variables marshaling
	allSetExpectedResString := fmt.Sprintf(
		`{"StringNVal":"string_n_val","StringVal":"string_val","Int64NVal":123,"Int64Val":123,"Float64NVal":12,"Float64Val":12,"BoolNVal":true,"BoolVal":true,"TimeNVal":"%s","TimeVal":"%s"}`,
		now.Format(time.RFC3339Nano),
		now.Format(time.RFC3339Nano),
	)
	if allSetExpectedResString != string(allSetRes) {
		t.Fatalf("Marshal err: expected: %s, got: %s", allSetExpectedResString, string(allSetRes))
	}

	// test not-set variables marshalling
	nnonset := &nullable{}
	nonSetRes, err := json.Marshal(nnonset)
	if err != nil {
		t.Fatalf("err while marshaling:%s", err.Error())
	}

	nonSetExpectedResString := fmt.Sprintf(
		`{"StringNVal":null,"StringVal":"","Int64NVal":null,"Int64Val":0,"Float64NVal":null,"Float64Val":0,"BoolNVal":null,"BoolVal":false,"TimeNVal":null,"TimeVal":"%s"}`,
		zeroDate().Format(time.RFC3339Nano),
	)
	if nonSetExpectedResString != string(nonSetRes) {
		t.Fatalf("Marshal err: expected: %s, got: %s", nonSetExpectedResString, string(nonSetRes))
	}
}

func TestUnMarshal(t *testing.T) {
	now := time.Now().UTC()
	nset := dummy(now)

	allSetRes, err := json.Marshal(nset)
	if err != nil {
		t.Fatalf("err while marshaling: %s", err.Error())
	}

	// test not-set variables marshalling
	nnonset := &nullable{}
	nonSetRes, err := json.Marshal(nnonset)
	if err != nil {
		t.Fatalf("err while marshaling:%s", err.Error())
	}

	// test all set variables unmarshalling
	nset2 := &nullable{}
	if err := json.Unmarshal(allSetRes, nset2); err != nil {
		t.Fatalf("Unmarshal err: %s", err.Error())
	}

	if !reflect.DeepEqual(nset, nset2) {
		t.Fatalf("not same: \nn:%#v,\nn2:%#v", nset, nset2)
	}

	// test not-set variables unmarshaling
	nnonset2 := &nullable{}
	if err := json.Unmarshal(nonSetRes, nnonset2); err != nil {
		t.Fatalf("Unmarshal err: %s", err.Error())
	}

	// deep equal fails on zerodate's loc property, check it manually
	if nnonset.TimeVal.UnixNano() != nnonset2.TimeVal.UnixNano() {
		t.Fatalf("time marshaling is not correct")
	}

	nnonset.TimeVal = zeroDate()
	nnonset2.TimeVal = zeroDate()

	if !reflect.DeepEqual(nnonset, nnonset2) {
		t.Fatalf("not same: \nn:%#v,\nn2:%#v", nnonset, nnonset2)
	}

	testGetNonNil(t, nset)
	testGetNil(t, nnonset)

	testGetNonNil(t, nset2)
	testGetNil(t, nnonset2)
}

func TestMarshalNullTime(t *testing.T) {
	nt := &NullTime{}
	err := nt.UnmarshalJSON([]byte("null1"))
	if err == nil {
		t.Fatal("null1 is not a valid time")
	}
}

func TestMarshalNullBool(t *testing.T) {
	nb := &NullBool{}
	err := nb.UnmarshalJSON([]byte("null1"))
	if err == nil {
		t.Fatal("null1 is not a valid bool")
	}
}

func zeroDate() time.Time {
	return time.Date(1, time.January, 1, 0, 0, 0, 0, time.FixedZone("", 0))
}

func testGetNil(t *testing.T, n *nullable) {
	testF(t, "n.StringNVal.Get() == nil", n.StringNVal.Get() == nil)
	testF(t, "n.Int64NVal.Get() == nil", n.Int64NVal.Get() == nil)
	testF(t, "n.Float64NVal.Get() == nil", n.Float64NVal.Get() == nil)
	testF(t, "n.BoolNVal.Get() == nil", n.BoolNVal.Get() == nil)
	testF(t, "n.TimeNVal.Get() == nil", n.TimeNVal.Get() == nil)
}

func testGetNonNil(t *testing.T, n *nullable) {
	testF(t, "n.StringNVal.Get() != nil", n.StringNVal.Get() != nil)
	testF(t, "n.Int64NVal.Get() != nil", n.Int64NVal.Get() != nil)
	testF(t, "n.Float64NVal.Get() != nil", n.Float64NVal.Get() != nil)
	testF(t, "n.BoolNVal.Get() != nil", n.BoolNVal.Get() != nil)
	testF(t, "n.TimeNVal.Get() != nil", n.TimeNVal.Get() != nil)
}

func testF(tb testing.TB, msg string, res bool) {
	if !res {
		fmt.Printf("exp: %s\n", msg)
		tb.Fail()
	}
}
