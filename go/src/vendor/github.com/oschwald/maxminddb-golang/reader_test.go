package maxminddb

import (
	"errors"
	"fmt"
	"io/ioutil"
	"math/big"
	"math/rand"
	"net"
	"testing"
	"time"

	. "gopkg.in/check.v1"
)

func TestMaxMindDbReader(t *testing.T) { TestingT(t) }

type MySuite struct{}

var _ = Suite(&MySuite{})

func (s *MySuite) TestReader(c *C) {
	for _, recordSize := range []uint{24, 28, 32} {
		for _, ipVersion := range []uint{4, 6} {
			fileName := fmt.Sprintf("test-data/test-data/MaxMind-DB-test-ipv%d-%d.mmdb", ipVersion, recordSize)
			reader, err := Open(fileName)
			if err != nil {
				c.Logf("unexpected error while opening database: %v", err)
				c.Fail()
			}

			checkMetadata(c, reader, ipVersion, recordSize)

			if ipVersion == 4 {
				checkIpv4(c, reader)
			} else {
				checkIpv6(c, reader)
			}
		}
	}
}

func (s *MySuite) TestReaderBytes(c *C) {
	for _, recordSize := range []uint{24, 28, 32} {
		for _, ipVersion := range []uint{4, 6} {
			fileName := fmt.Sprintf("test-data/test-data/MaxMind-DB-test-ipv%d-%d.mmdb", ipVersion, recordSize)
			bytes, _ := ioutil.ReadFile(fileName)
			reader, err := FromBytes(bytes)
			if err != nil {
				c.Logf("unexpected error while opening bytes: %v", err)
				c.Fail()
			}

			checkMetadata(c, reader, ipVersion, recordSize)

			if ipVersion == 4 {
				checkIpv4(c, reader)
			} else {
				checkIpv6(c, reader)
			}
		}
	}
}

func (s *MySuite) TestDecodingToInterface(c *C) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	if err != nil {
		c.Logf("unexpected error while opening database: %v", err)
		c.Fail()
	}

	var recordInterface interface{}
	err = reader.Lookup(net.ParseIP("::1.1.1.0"), &recordInterface)
	if err != nil {
		c.Logf("unexpected error while doing lookup: %v", err)
		c.Fail()
	}
	record := recordInterface.(map[string]interface{})

	c.Assert(record["array"], DeepEquals, []interface{}{uint64(1), uint64(2), uint64(3)})
	c.Assert(record["boolean"], Equals, true)
	c.Assert(record["bytes"], DeepEquals, []byte{0x00, 0x00, 0x00, 0x2a})
	c.Assert(record["double"], Equals, 42.123456)
	c.Assert(record["float"], Equals, float32(1.1))
	c.Assert(record["int32"], Equals, -268435456)
	c.Assert(record["map"], DeepEquals,
		map[string]interface{}{
			"mapX": map[string]interface{}{
				"arrayX":       []interface{}{uint64(7), uint64(8), uint64(9)},
				"utf8_stringX": "hello",
			}})

	c.Assert(record["uint16"], Equals, uint64(100))
	c.Assert(record["uint32"], Equals, uint64(268435456))
	c.Assert(record["uint64"], Equals, uint64(1152921504606846976))
	c.Assert(record["utf8_string"], Equals, "unicode! ☯ - ♫")
	bigInt := new(big.Int)
	bigInt.SetString("1329227995784915872903807060280344576", 10)
	c.Assert(record["uint128"], DeepEquals, bigInt)
}

type TestType struct {
	Array      []uint                 `maxminddb:"array"`
	Boolean    bool                   `maxminddb:"boolean"`
	Bytes      []byte                 `maxminddb:"bytes"`
	Double     float64                `maxminddb:"double"`
	Float      float32                `maxminddb:"float"`
	Int32      int32                  `maxminddb:"int32"`
	Map        map[string]interface{} `maxminddb:"map"`
	Uint16     uint16                 `maxminddb:"uint16"`
	Uint32     uint32                 `maxminddb:"uint32"`
	Uint64     uint64                 `maxminddb:"uint64"`
	Uint128    big.Int                `maxminddb:"uint128"`
	Utf8String string                 `maxminddb:"utf8_string"`
}

func (s *MySuite) TestDecoder(c *C) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	c.Assert(err, IsNil)

	verify := func(result TestType) {
		c.Assert(result.Array, DeepEquals, []uint{uint(1), uint(2), uint(3)})
		c.Assert(result.Boolean, Equals, true)
		c.Assert(result.Bytes, DeepEquals, []byte{0x00, 0x00, 0x00, 0x2a})
		c.Assert(result.Double, Equals, 42.123456)
		c.Assert(result.Float, Equals, float32(1.1))
		c.Assert(result.Int32, Equals, int32(-268435456))

		c.Assert(result.Map, DeepEquals,
			map[string]interface{}{
				"mapX": map[string]interface{}{
					"arrayX":       []interface{}{uint64(7), uint64(8), uint64(9)},
					"utf8_stringX": "hello",
				}})

		c.Assert(result.Uint16, Equals, uint16(100))
		c.Assert(result.Uint32, Equals, uint32(268435456))
		c.Assert(result.Uint64, Equals, uint64(1152921504606846976))
		c.Assert(result.Utf8String, Equals, "unicode! ☯ - ♫")
		bigInt := new(big.Int)
		bigInt.SetString("1329227995784915872903807060280344576", 10)
		c.Assert(&result.Uint128, DeepEquals, bigInt)
	}

	{
		// Directly lookup and decode.
		var result TestType
		c.Assert(reader.Lookup(net.ParseIP("::1.1.1.0"), &result), IsNil)
		verify(result)
	}
	{
		// Lookup record offset, then Decode.
		var result TestType
		offset, err := reader.LookupOffset(net.ParseIP("::1.1.1.0"))
		c.Assert(err, IsNil)
		c.Assert(offset, Not(Equals), NotFound)

		c.Assert(reader.Decode(offset, &result), IsNil)
		verify(result)
	}

	c.Assert(reader.Close(), IsNil)
}

type TestInterface interface {
	method() bool
}

func (t *TestType) method() bool {
	return t.Boolean
}

func (s *MySuite) TestStructInterface(c *C) {
	var result TestInterface = &TestType{}

	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	c.Assert(err, IsNil)

	c.Assert(reader.Lookup(net.ParseIP("::1.1.1.0"), &result), IsNil)

	c.Assert(result.method(), Equals, true)
}

func (s *MySuite) TestNonEmptyNilInterface(c *C) {
	var result TestInterface

	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	c.Assert(err, IsNil)

	err = reader.Lookup(net.ParseIP("::1.1.1.0"), &result)
	c.Assert(err.Error(), Equals, "maxminddb: cannot unmarshal map into type maxminddb.TestInterface")
}

type BoolInterface interface {
	true() bool
}

type Bool bool

func (b Bool) true() bool {
	return bool(b)
}

type ValueTypeTestType struct {
	Boolean BoolInterface `maxminddb:"boolean"`
}

func (s *MySuite) TesValueTypeInterface(c *C) {
	var result ValueTypeTestType
	result.Boolean = Bool(false)

	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	c.Assert(err, IsNil)
	c.Assert(reader.Lookup(net.ParseIP("::1.1.1.0"), &result), IsNil)

	c.Assert(result.Boolean.true(), Equals, true)
}

type NestedMapX struct {
	UTF8StringX string `maxminddb:"utf8_stringX"`
}

type NestedPointerMapX struct {
	ArrayX []int `maxminddb:"arrayX"`
}

type PointerMap struct {
	MapX struct {
		NestedMapX
		*NestedPointerMapX
	} `maxminddb:"mapX"`
}

type TestPointerType struct {
	Array   *[]uint     `maxminddb:"array"`
	Boolean *bool       `maxminddb:"boolean"`
	Bytes   *[]byte     `maxminddb:"bytes"`
	Double  *float64    `maxminddb:"double"`
	Float   *float32    `maxminddb:"float"`
	Int32   *int32      `maxminddb:"int32"`
	Map     *PointerMap `maxminddb:"map"`
	Uint16  *uint16     `maxminddb:"uint16"`
	Uint32  *uint32     `maxminddb:"uint32"`

	// Test for pointer to pointer
	Uint64     **uint64 `maxminddb:"uint64"`
	Uint128    *big.Int `maxminddb:"uint128"`
	Utf8String *string  `maxminddb:"utf8_string"`
}

func (s *MySuite) TestComplexStructWithNestingAndPointer(c *C) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	c.Assert(err, IsNil)

	var result TestPointerType

	err = reader.Lookup(net.ParseIP("::1.1.1.0"), &result)
	c.Assert(err, IsNil)

	c.Assert(*result.Array, DeepEquals, []uint{uint(1), uint(2), uint(3)})
	c.Assert(*result.Boolean, Equals, true)
	c.Assert(*result.Bytes, DeepEquals, []byte{0x00, 0x00, 0x00, 0x2a})
	c.Assert(*result.Double, Equals, 42.123456)
	c.Assert(*result.Float, Equals, float32(1.1))
	c.Assert(*result.Int32, Equals, int32(-268435456))

	c.Assert(result.Map.MapX.ArrayX, DeepEquals, []int{7, 8, 9})

	c.Assert(result.Map.MapX.UTF8StringX, Equals, "hello")

	c.Assert(*result.Uint16, Equals, uint16(100))
	c.Assert(*result.Uint32, Equals, uint32(268435456))
	c.Assert(**result.Uint64, Equals, uint64(1152921504606846976))
	c.Assert(*result.Utf8String, Equals, "unicode! ☯ - ♫")
	bigInt := new(big.Int)
	bigInt.SetString("1329227995784915872903807060280344576", 10)
	c.Assert(result.Uint128, DeepEquals, bigInt)

	c.Assert(reader.Close(), IsNil)
}

func (s *MySuite) TestNestedOffsetDecode(c *C) {
	db, err := Open("test-data/test-data/GeoIP2-City-Test.mmdb")
	c.Assert(err, IsNil)

	off, err := db.LookupOffset(net.ParseIP("81.2.69.142"))
	c.Assert(off, Not(Equals), NotFound)
	c.Check(err, IsNil)

	var root struct {
		CountryOffset uintptr `maxminddb:"country"`

		Location struct {
			Latitude float64 `maxminddb:"latitude"`
			// Longitude is directly nested within the parent map.
			LongitudeOffset uintptr `maxminddb:"longitude"`
			// TimeZone is indirected via a pointer.
			TimeZoneOffset uintptr `maxminddb:"time_zone"`
		} `maxminddb:"location"`
	}
	c.Check(db.Decode(off, &root), IsNil)
	c.Check(root.Location.Latitude, Equals, 51.5142)

	var longitude float64
	c.Check(db.Decode(root.Location.LongitudeOffset, &longitude), IsNil)
	c.Check(longitude, Equals, -0.0931)

	var timeZone string
	c.Check(db.Decode(root.Location.TimeZoneOffset, &timeZone), IsNil)
	c.Check(timeZone, Equals, "Europe/London")

	var country struct {
		IsoCode string `maxminddb:"iso_code"`
	}
	c.Check(db.Decode(root.CountryOffset, &country), IsNil)
	c.Check(country.IsoCode, Equals, "GB")

	c.Check(db.Close(), IsNil)
}

func (s *MySuite) TestDecodingUint16IntoInt(c *C) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")
	if err != nil {
		c.Logf("unexpected error while opening database: %v", err)
		c.Fail()
	}

	var result struct {
		Uint16 int `maxminddb:"uint16"`
	}
	err = reader.Lookup(net.ParseIP("::1.1.1.0"), &result)
	if err != nil {
		c.Log(err)
		c.Fail()
	}

	c.Assert(result.Uint16, Equals, 100)
}

func (s *MySuite) TestIpv6inIpv4(c *C) {
	reader, err := Open("test-data/test-data/MaxMind-DB-test-ipv4-24.mmdb")
	if err != nil {
		c.Logf("unexpected error while opening database: %v", err)
		c.Fail()
	}

	var result TestType
	err = reader.Lookup(net.ParseIP("2001::"), &result)

	var emptyResult TestType
	c.Assert(result, DeepEquals, emptyResult)

	expected := errors.New("error looking up '2001::': you attempted to look up an IPv6 address in an IPv4-only database")
	c.Assert(err, DeepEquals, expected)
	if err = reader.Close(); err != nil {
		c.Assert(err, nil, "no error on close")
	}
}

func (s *MySuite) TestBrokenDoubleDatabase(c *C) {
	reader, err := Open("test-data/test-data/GeoIP2-City-Test-Broken-Double-Format.mmdb")
	if err != nil {
		c.Logf("unexpected error while opening database: %v", err)
		c.Fail()
	}

	var result interface{}
	err = reader.Lookup(net.ParseIP("2001:220::"), &result)

	expected := newInvalidDatabaseError("the MaxMind DB file's data section contains bad data (float 64 size of 2)")
	c.Assert(err, DeepEquals, expected)
	if err = reader.Close(); err != nil {
		c.Assert(err, nil, "no error on close")
	}
}

func (s *MySuite) TestInvalidNodeCountDatabase(c *C) {
	_, err := Open("test-data/test-data/GeoIP2-City-Test-Invalid-Node-Count.mmdb")

	expected := newInvalidDatabaseError("the MaxMind DB contains invalid metadata")
	c.Assert(err, DeepEquals, expected)
}

func (s *MySuite) TestMissingDatabase(c *C) {
	reader, err := Open("file-does-not-exist.mmdb")
	if reader != nil {
		c.Log("received reader when doing lookups on DB that doesn't exist")
		c.Fail()
	}
	c.Assert(err, ErrorMatches, "open file-does-not-exist.mmdb.*")
}

func (s *MySuite) TestNonDatabase(c *C) {
	reader, err := Open("README.md")
	if reader != nil {
		c.Log("received reader when doing lookups on DB that doesn't exist")
		c.Fail()
	}
	c.Assert(err.Error(), Equals, "error opening database: invalid MaxMind DB file")
}

func (s *MySuite) TestDecodingToNonPointer(c *C) {
	reader, _ := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")

	var recordInterface interface{}
	err := reader.Lookup(net.ParseIP("::1.1.1.0"), recordInterface)
	c.Assert(err.Error(), Equals, "result param must be a pointer")
	if err = reader.Close(); err != nil {
		c.Assert(err, nil, "no error on close")
	}
}

func (s *MySuite) TestNilLookup(c *C) {
	reader, _ := Open("test-data/test-data/MaxMind-DB-test-decoder.mmdb")

	var recordInterface interface{}
	err := reader.Lookup(nil, recordInterface)
	c.Assert(err.Error(), Equals, "ipAddress passed to Lookup cannot be nil")
	if err = reader.Close(); err != nil {
		c.Assert(err, nil, "no error on close")
	}
}

func checkMetadata(c *C, reader *Reader, ipVersion uint, recordSize uint) {
	metadata := reader.Metadata

	c.Assert(metadata.BinaryFormatMajorVersion, Equals, uint(2))

	c.Assert(metadata.BinaryFormatMinorVersion, Equals, uint(0))
	c.Assert(metadata.BuildEpoch, FitsTypeOf, uint(0))
	c.Assert(metadata.DatabaseType, Equals, "Test")

	c.Assert(metadata.Description, DeepEquals,
		map[string]string{
			"en": "Test Database",
			"zh": "Test Database Chinese",
		})
	c.Assert(metadata.IPVersion, Equals, ipVersion)
	c.Assert(metadata.Languages, DeepEquals, []string{"en", "zh"})

	if ipVersion == 4 {
		c.Assert(metadata.NodeCount, Equals, uint(164))
	} else {
		c.Assert(metadata.NodeCount, Equals, uint(416))
	}

	c.Assert(metadata.RecordSize, Equals, recordSize)
}

func checkIpv4(c *C, reader *Reader) {

	for i := uint(0); i < 6; i++ {
		address := fmt.Sprintf("1.1.1.%d", uint(1)<<i)
		ip := net.ParseIP(address)

		var result map[string]string
		err := reader.Lookup(ip, &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, DeepEquals, map[string]string{
			"ip": address})
	}
	pairs := map[string]string{
		"1.1.1.3":  "1.1.1.2",
		"1.1.1.5":  "1.1.1.4",
		"1.1.1.7":  "1.1.1.4",
		"1.1.1.9":  "1.1.1.8",
		"1.1.1.15": "1.1.1.8",
		"1.1.1.17": "1.1.1.16",
		"1.1.1.31": "1.1.1.16",
	}

	for keyAddress, valueAddress := range pairs {
		data := map[string]string{"ip": valueAddress}

		ip := net.ParseIP(keyAddress)

		var result map[string]string
		err := reader.Lookup(ip, &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, DeepEquals, data)
	}

	for _, address := range []string{"1.1.1.33", "255.254.253.123"} {
		ip := net.ParseIP(address)

		var result map[string]string
		err := reader.Lookup(ip, &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, IsNil)
	}
}

func checkIpv6(c *C, reader *Reader) {

	subnets := []string{"::1:ffff:ffff", "::2:0:0",
		"::2:0:40", "::2:0:50", "::2:0:58"}

	for _, address := range subnets {
		var result map[string]string
		err := reader.Lookup(net.ParseIP(address), &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, DeepEquals, map[string]string{"ip": address})
	}

	pairs := map[string]string{
		"::2:0:1":  "::2:0:0",
		"::2:0:33": "::2:0:0",
		"::2:0:39": "::2:0:0",
		"::2:0:41": "::2:0:40",
		"::2:0:49": "::2:0:40",
		"::2:0:52": "::2:0:50",
		"::2:0:57": "::2:0:50",
		"::2:0:59": "::2:0:58",
	}

	for keyAddress, valueAddress := range pairs {
		data := map[string]string{"ip": valueAddress}
		var result map[string]string
		err := reader.Lookup(net.ParseIP(keyAddress), &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, DeepEquals, data)
	}

	for _, address := range []string{"1.1.1.33", "255.254.253.123", "89fa::"} {
		var result map[string]string
		err := reader.Lookup(net.ParseIP(address), &result)
		if err != nil {
			c.Logf("unexpected error while doing lookup: %v", err)
			c.Fail()
		}
		c.Assert(result, IsNil)
	}
}

func BenchmarkMaxMindDB(b *testing.B) {
	db, err := Open("GeoLite2-City.mmdb")
	if err != nil {
		b.Fatal(err)
	}

	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	var result interface{}

	for i := 0; i < b.N; i++ {
		ip := randomIPv4Address(b, r)
		err = db.Lookup(ip, &result)
		if err != nil {
			b.Fatal(err)
		}
	}
	if err = db.Close(); err != nil {
		b.Error("error on close")
	}
}

func BenchmarkCountryCode(b *testing.B) {
	db, err := Open("GeoLite2-City.mmdb")
	if err != nil {
		b.Fatal(err)
	}

	type MinCountry struct {
		Country struct {
			IsoCode string `maxminddb:"iso_code"`
		} `maxminddb:"country"`
	}

	r := rand.New(rand.NewSource(0))
	var result MinCountry

	for i := 0; i < b.N; i++ {
		ip := randomIPv4Address(b, r)
		err = db.Lookup(ip, &result)
		if err != nil {
			b.Fatal(err)
		}
	}
	if err = db.Close(); err != nil {
		b.Error("error on close")
	}
}

func randomIPv4Address(b *testing.B, r *rand.Rand) net.IP {
	num := r.Uint32()
	return []byte{byte(num >> 24), byte(num >> 16), byte(num >> 8),
		byte(num)}
}
