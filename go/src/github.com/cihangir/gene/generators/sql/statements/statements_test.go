package statements

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestStatements(t *testing.T) {
	s := &schema.Schema{}
	if err := json.Unmarshal([]byte(testdata.TestDataFull), s); err != nil {
		t.Fatal(err.Error())
	}

	s = s.Resolve(s)

	sts, err := (&Generator{}).Generate(common.NewContext(), s)
	equals(t, nil, err)
	for _, s := range sts {
		if strings.HasSuffix(s.Path, "profile_statements.go") {
			equals(t, expected, string(s.Content))
		}
	}
}

func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.Fail()
	}
}

const expected = `// Generated struct for Profile.
package models

// GenerateCreateSQL generates plain sql for the given Profile
func (p *Profile) GenerateCreateSQL() (string, []interface{}, error) {
	psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Insert(p.TableName())
	columns := make([]string, 0)
	values := make([]interface{}, 0)
	if float64(p.ID) != float64(0) {
		columns = append(columns, "id")
		values = append(values, p.ID)
	}
	if p.BooleanWithMaxLength != false {
		columns = append(columns, "boolean_with_max_length")
		values = append(values, p.BooleanWithMaxLength)
	}
	if p.BooleanWithMinLength != false {
		columns = append(columns, "boolean_with_min_length")
		values = append(values, p.BooleanWithMinLength)
	}
	if p.BooleanWithDefault != false {
		columns = append(columns, "boolean_with_default")
		values = append(values, p.BooleanWithDefault)
	}
	if p.StringBare != "" {
		columns = append(columns, "string_bare")
		values = append(values, p.StringBare)
	}
	if p.StringWithDefault != "" {
		columns = append(columns, "string_with_default")
		values = append(values, p.StringWithDefault)
	}
	if p.StringWithMaxLength != "" {
		columns = append(columns, "string_with_max_length")
		values = append(values, p.StringWithMaxLength)
	}
	if p.StringWithMinLength != "" {
		columns = append(columns, "string_with_min_length")
		values = append(values, p.StringWithMinLength)
	}
	if p.StringWithMaxAndMinLength != "" {
		columns = append(columns, "string_with_max_and_min_length")
		values = append(values, p.StringWithMaxAndMinLength)
	}
	if p.StringWithPattern != "" {
		columns = append(columns, "string_with_pattern")
		values = append(values, p.StringWithPattern)
	}
	if !p.StringDateFormatted.IsZero() {
		columns = append(columns, "string_date_formatted")
		values = append(values, p.StringDateFormatted)
	}
	if !p.StringDateFormattedWithDefault.IsZero() {
		columns = append(columns, "string_date_formatted_with_default")
		values = append(values, p.StringDateFormattedWithDefault)
	}
	if p.StringUUIDFormatted != "" {
		columns = append(columns, "string_uuid_formatted")
		values = append(values, p.StringUUIDFormatted)
	}
	if p.StringUUIDFormattedWithDefault != "" {
		columns = append(columns, "string_uuid_formatted_with_default")
		values = append(values, p.StringUUIDFormattedWithDefault)
	}
	if float64(p.NumberBare) != float64(0) {
		columns = append(columns, "number_bare")
		values = append(values, p.NumberBare)
	}
	if float64(p.NumberWithMultipleOf) != float64(0) {
		columns = append(columns, "number_with_multiple_of")
		values = append(values, p.NumberWithMultipleOf)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float64")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float32")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int64")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int64")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int32")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt32)
	}
	if p.EnumBare != "" {
		columns = append(columns, "enum_bare")
		values = append(values, p.EnumBare)
	}
	if float64(p.NumberWithExclusiveMaximumWithoutMaximum) != float64(0) {
		columns = append(columns, "number_with_exclusive_maximum_without_maximum")
		values = append(values, p.NumberWithExclusiveMaximumWithoutMaximum)
	}
	if float64(p.NumberWithExclusiveMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum")
		values = append(values, p.NumberWithExclusiveMinimum)
	}
	if float64(p.NumberWithExclusiveMinimumWithoutMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum_without_minimum")
		values = append(values, p.NumberWithExclusiveMinimumWithoutMinimum)
	}
	if float64(p.NumberWithMaximum) != float64(0) {
		columns = append(columns, "number_with_maximum")
		values = append(values, p.NumberWithMaximum)
	}
	if float64(p.NumberWithMaximumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float32")
		values = append(values, p.NumberWithMaximumAsFloat32)
	}
	if float64(p.NumberWithMaximumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float64")
		values = append(values, p.NumberWithMaximumAsFloat64)
	}
	if float64(p.NumberWithMaximumAsInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int")
		values = append(values, p.NumberWithMaximumAsInt)
	}
	if float64(p.NumberWithMaximumAsInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int16")
		values = append(values, p.NumberWithMaximumAsInt16)
	}
	if float64(p.NumberWithMaximumAsInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int32")
		values = append(values, p.NumberWithMaximumAsInt32)
	}
	if float64(p.NumberWithMaximumAsInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int64")
		values = append(values, p.NumberWithMaximumAsInt64)
	}
	if float64(p.NumberWithMaximumAsInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int8")
		values = append(values, p.NumberWithMaximumAsInt8)
	}
	if float64(p.NumberWithMaximumAsUInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int")
		values = append(values, p.NumberWithMaximumAsUInt)
	}
	if float64(p.NumberWithMaximumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int16")
		values = append(values, p.NumberWithMaximumAsUInt16)
	}
	if float64(p.NumberWithMaximumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int32")
		values = append(values, p.NumberWithMaximumAsUInt32)
	}
	if float64(p.NumberWithMaximumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int64")
		values = append(values, p.NumberWithMaximumAsUInt64)
	}
	if float64(p.NumberWithMaximumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int8")
		values = append(values, p.NumberWithMaximumAsUInt8)
	}
	if float64(p.NumberWithMinimumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float32")
		values = append(values, p.NumberWithMinimumAsFloat32)
	}
	if float64(p.NumberWithMinimumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float64")
		values = append(values, p.NumberWithMinimumAsFloat64)
	}
	if float64(p.NumberWithMinimumAsInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int")
		values = append(values, p.NumberWithMinimumAsInt)
	}
	if float64(p.NumberWithMinimumAsInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int16")
		values = append(values, p.NumberWithMinimumAsInt16)
	}
	if float64(p.NumberWithMinimumAsInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int32")
		values = append(values, p.NumberWithMinimumAsInt32)
	}
	if float64(p.NumberWithMinimumAsInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int64")
		values = append(values, p.NumberWithMinimumAsInt64)
	}
	if float64(p.NumberWithMinimumAsInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int8")
		values = append(values, p.NumberWithMinimumAsInt8)
	}
	if float64(p.NumberWithMinimumAsUInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int")
		values = append(values, p.NumberWithMinimumAsUInt)
	}
	if float64(p.NumberWithMinimumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int16")
		values = append(values, p.NumberWithMinimumAsUInt16)
	}
	if float64(p.NumberWithMinimumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int32")
		values = append(values, p.NumberWithMinimumAsUInt32)
	}
	if float64(p.NumberWithMinimumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int64")
		values = append(values, p.NumberWithMinimumAsUInt64)
	}
	if float64(p.NumberWithMinimumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int8")
		values = append(values, p.NumberWithMinimumAsUInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int16")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int8")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int16")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int32")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int8")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt8)
	}
	return psql.Columns(columns...).Values(values...).ToSql()
}

// GenerateUpdateSQL generates plain update sql statement for the given Profile
func (p *Profile) GenerateUpdateSQL() (string, []interface{}, error) {
	psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Update(p.TableName())
	if p.BooleanWithMaxLength != false {
		psql = psql.Set("boolean_with_max_length", p.BooleanWithMaxLength)
	}
	if p.BooleanWithMinLength != false {
		psql = psql.Set("boolean_with_min_length", p.BooleanWithMinLength)
	}
	if p.BooleanWithDefault != false {
		psql = psql.Set("boolean_with_default", p.BooleanWithDefault)
	}
	if p.StringBare != "" {
		psql = psql.Set("string_bare", p.StringBare)
	}
	if p.StringWithDefault != "" {
		psql = psql.Set("string_with_default", p.StringWithDefault)
	}
	if p.StringWithMaxLength != "" {
		psql = psql.Set("string_with_max_length", p.StringWithMaxLength)
	}
	if p.StringWithMinLength != "" {
		psql = psql.Set("string_with_min_length", p.StringWithMinLength)
	}
	if p.StringWithMaxAndMinLength != "" {
		psql = psql.Set("string_with_max_and_min_length", p.StringWithMaxAndMinLength)
	}
	if p.StringWithPattern != "" {
		psql = psql.Set("string_with_pattern", p.StringWithPattern)
	}
	if !p.StringDateFormatted.IsZero() {
		psql = psql.Set("string_date_formatted", p.StringDateFormatted)
	}
	if !p.StringDateFormattedWithDefault.IsZero() {
		psql = psql.Set("string_date_formatted_with_default", p.StringDateFormattedWithDefault)
	}
	if p.StringUUIDFormatted != "" {
		psql = psql.Set("string_uuid_formatted", p.StringUUIDFormatted)
	}
	if p.StringUUIDFormattedWithDefault != "" {
		psql = psql.Set("string_uuid_formatted_with_default", p.StringUUIDFormattedWithDefault)
	}
	if float64(p.NumberBare) != float64(0) {
		psql = psql.Set("number_bare", p.NumberBare)
	}
	if float64(p.NumberWithMultipleOf) != float64(0) {
		psql = psql.Set("number_with_multiple_of", p.NumberWithMultipleOf)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat64) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_float64", p.NumberWithMultipleOfFormattedAsFloat64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat32) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_float32", p.NumberWithMultipleOfFormattedAsFloat32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt64) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_int64", p.NumberWithMultipleOfFormattedAsInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt64) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_u_int64", p.NumberWithMultipleOfFormattedAsUInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt32) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_int32", p.NumberWithMultipleOfFormattedAsInt32)
	}
	if p.EnumBare != "" {
		psql = psql.Set("enum_bare", p.EnumBare)
	}
	if float64(p.NumberWithExclusiveMaximumWithoutMaximum) != float64(0) {
		psql = psql.Set("number_with_exclusive_maximum_without_maximum", p.NumberWithExclusiveMaximumWithoutMaximum)
	}
	if float64(p.NumberWithExclusiveMinimum) != float64(0) {
		psql = psql.Set("number_with_exclusive_minimum", p.NumberWithExclusiveMinimum)
	}
	if float64(p.NumberWithExclusiveMinimumWithoutMinimum) != float64(0) {
		psql = psql.Set("number_with_exclusive_minimum_without_minimum", p.NumberWithExclusiveMinimumWithoutMinimum)
	}
	if float64(p.NumberWithMaximum) != float64(0) {
		psql = psql.Set("number_with_maximum", p.NumberWithMaximum)
	}
	if float64(p.NumberWithMaximumAsFloat32) != float64(0) {
		psql = psql.Set("number_with_maximum_as_float32", p.NumberWithMaximumAsFloat32)
	}
	if float64(p.NumberWithMaximumAsFloat64) != float64(0) {
		psql = psql.Set("number_with_maximum_as_float64", p.NumberWithMaximumAsFloat64)
	}
	if float64(p.NumberWithMaximumAsInt) != float64(0) {
		psql = psql.Set("number_with_maximum_as_int", p.NumberWithMaximumAsInt)
	}
	if float64(p.NumberWithMaximumAsInt16) != float64(0) {
		psql = psql.Set("number_with_maximum_as_int16", p.NumberWithMaximumAsInt16)
	}
	if float64(p.NumberWithMaximumAsInt32) != float64(0) {
		psql = psql.Set("number_with_maximum_as_int32", p.NumberWithMaximumAsInt32)
	}
	if float64(p.NumberWithMaximumAsInt64) != float64(0) {
		psql = psql.Set("number_with_maximum_as_int64", p.NumberWithMaximumAsInt64)
	}
	if float64(p.NumberWithMaximumAsInt8) != float64(0) {
		psql = psql.Set("number_with_maximum_as_int8", p.NumberWithMaximumAsInt8)
	}
	if float64(p.NumberWithMaximumAsUInt) != float64(0) {
		psql = psql.Set("number_with_maximum_as_u_int", p.NumberWithMaximumAsUInt)
	}
	if float64(p.NumberWithMaximumAsUInt16) != float64(0) {
		psql = psql.Set("number_with_maximum_as_u_int16", p.NumberWithMaximumAsUInt16)
	}
	if float64(p.NumberWithMaximumAsUInt32) != float64(0) {
		psql = psql.Set("number_with_maximum_as_u_int32", p.NumberWithMaximumAsUInt32)
	}
	if float64(p.NumberWithMaximumAsUInt64) != float64(0) {
		psql = psql.Set("number_with_maximum_as_u_int64", p.NumberWithMaximumAsUInt64)
	}
	if float64(p.NumberWithMaximumAsUInt8) != float64(0) {
		psql = psql.Set("number_with_maximum_as_u_int8", p.NumberWithMaximumAsUInt8)
	}
	if float64(p.NumberWithMinimumAsFloat32) != float64(0) {
		psql = psql.Set("number_with_minimum_as_float32", p.NumberWithMinimumAsFloat32)
	}
	if float64(p.NumberWithMinimumAsFloat64) != float64(0) {
		psql = psql.Set("number_with_minimum_as_float64", p.NumberWithMinimumAsFloat64)
	}
	if float64(p.NumberWithMinimumAsInt) != float64(0) {
		psql = psql.Set("number_with_minimum_as_int", p.NumberWithMinimumAsInt)
	}
	if float64(p.NumberWithMinimumAsInt16) != float64(0) {
		psql = psql.Set("number_with_minimum_as_int16", p.NumberWithMinimumAsInt16)
	}
	if float64(p.NumberWithMinimumAsInt32) != float64(0) {
		psql = psql.Set("number_with_minimum_as_int32", p.NumberWithMinimumAsInt32)
	}
	if float64(p.NumberWithMinimumAsInt64) != float64(0) {
		psql = psql.Set("number_with_minimum_as_int64", p.NumberWithMinimumAsInt64)
	}
	if float64(p.NumberWithMinimumAsInt8) != float64(0) {
		psql = psql.Set("number_with_minimum_as_int8", p.NumberWithMinimumAsInt8)
	}
	if float64(p.NumberWithMinimumAsUInt) != float64(0) {
		psql = psql.Set("number_with_minimum_as_u_int", p.NumberWithMinimumAsUInt)
	}
	if float64(p.NumberWithMinimumAsUInt16) != float64(0) {
		psql = psql.Set("number_with_minimum_as_u_int16", p.NumberWithMinimumAsUInt16)
	}
	if float64(p.NumberWithMinimumAsUInt32) != float64(0) {
		psql = psql.Set("number_with_minimum_as_u_int32", p.NumberWithMinimumAsUInt32)
	}
	if float64(p.NumberWithMinimumAsUInt64) != float64(0) {
		psql = psql.Set("number_with_minimum_as_u_int64", p.NumberWithMinimumAsUInt64)
	}
	if float64(p.NumberWithMinimumAsUInt8) != float64(0) {
		psql = psql.Set("number_with_minimum_as_u_int8", p.NumberWithMinimumAsUInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_int", p.NumberWithMultipleOfFormattedAsInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt16) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_int16", p.NumberWithMultipleOfFormattedAsInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt8) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_int8", p.NumberWithMultipleOfFormattedAsInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_u_int", p.NumberWithMultipleOfFormattedAsUInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt16) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_u_int16", p.NumberWithMultipleOfFormattedAsUInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt32) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_u_int32", p.NumberWithMultipleOfFormattedAsUInt32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt8) != float64(0) {
		psql = psql.Set("number_with_multiple_of_formatted_as_u_int8", p.NumberWithMultipleOfFormattedAsUInt8)
	}
	return psql.Where("id = ?", p.ID).ToSql()
}

// GenerateDeleteSQL generates plain delete sql statement for the given Profile
func (p *Profile) GenerateDeleteSQL() (string, []interface{}, error) {
	psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Delete(p.TableName())
	columns := make([]string, 0)
	values := make([]interface{}, 0)
	if float64(p.ID) != float64(0) {
		columns = append(columns, "id = ?")
		values = append(values, p.ID)
	}
	if p.BooleanWithMaxLength != false {
		columns = append(columns, "boolean_with_max_length = ?")
		values = append(values, p.BooleanWithMaxLength)
	}
	if p.BooleanWithMinLength != false {
		columns = append(columns, "boolean_with_min_length = ?")
		values = append(values, p.BooleanWithMinLength)
	}
	if p.BooleanWithDefault != false {
		columns = append(columns, "boolean_with_default = ?")
		values = append(values, p.BooleanWithDefault)
	}
	if p.StringBare != "" {
		columns = append(columns, "string_bare = ?")
		values = append(values, p.StringBare)
	}
	if p.StringWithDefault != "" {
		columns = append(columns, "string_with_default = ?")
		values = append(values, p.StringWithDefault)
	}
	if p.StringWithMaxLength != "" {
		columns = append(columns, "string_with_max_length = ?")
		values = append(values, p.StringWithMaxLength)
	}
	if p.StringWithMinLength != "" {
		columns = append(columns, "string_with_min_length = ?")
		values = append(values, p.StringWithMinLength)
	}
	if p.StringWithMaxAndMinLength != "" {
		columns = append(columns, "string_with_max_and_min_length = ?")
		values = append(values, p.StringWithMaxAndMinLength)
	}
	if p.StringWithPattern != "" {
		columns = append(columns, "string_with_pattern = ?")
		values = append(values, p.StringWithPattern)
	}
	if !p.StringDateFormatted.IsZero() {
		columns = append(columns, "string_date_formatted = ?")
		values = append(values, p.StringDateFormatted)
	}
	if !p.StringDateFormattedWithDefault.IsZero() {
		columns = append(columns, "string_date_formatted_with_default = ?")
		values = append(values, p.StringDateFormattedWithDefault)
	}
	if p.StringUUIDFormatted != "" {
		columns = append(columns, "string_uuid_formatted = ?")
		values = append(values, p.StringUUIDFormatted)
	}
	if p.StringUUIDFormattedWithDefault != "" {
		columns = append(columns, "string_uuid_formatted_with_default = ?")
		values = append(values, p.StringUUIDFormattedWithDefault)
	}
	if float64(p.NumberBare) != float64(0) {
		columns = append(columns, "number_bare = ?")
		values = append(values, p.NumberBare)
	}
	if float64(p.NumberWithMultipleOf) != float64(0) {
		columns = append(columns, "number_with_multiple_of = ?")
		values = append(values, p.NumberWithMultipleOf)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt32)
	}
	if p.EnumBare != "" {
		columns = append(columns, "enum_bare = ?")
		values = append(values, p.EnumBare)
	}
	if float64(p.NumberWithExclusiveMaximumWithoutMaximum) != float64(0) {
		columns = append(columns, "number_with_exclusive_maximum_without_maximum = ?")
		values = append(values, p.NumberWithExclusiveMaximumWithoutMaximum)
	}
	if float64(p.NumberWithExclusiveMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum = ?")
		values = append(values, p.NumberWithExclusiveMinimum)
	}
	if float64(p.NumberWithExclusiveMinimumWithoutMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum_without_minimum = ?")
		values = append(values, p.NumberWithExclusiveMinimumWithoutMinimum)
	}
	if float64(p.NumberWithMaximum) != float64(0) {
		columns = append(columns, "number_with_maximum = ?")
		values = append(values, p.NumberWithMaximum)
	}
	if float64(p.NumberWithMaximumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float32 = ?")
		values = append(values, p.NumberWithMaximumAsFloat32)
	}
	if float64(p.NumberWithMaximumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float64 = ?")
		values = append(values, p.NumberWithMaximumAsFloat64)
	}
	if float64(p.NumberWithMaximumAsInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int = ?")
		values = append(values, p.NumberWithMaximumAsInt)
	}
	if float64(p.NumberWithMaximumAsInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int16 = ?")
		values = append(values, p.NumberWithMaximumAsInt16)
	}
	if float64(p.NumberWithMaximumAsInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int32 = ?")
		values = append(values, p.NumberWithMaximumAsInt32)
	}
	if float64(p.NumberWithMaximumAsInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int64 = ?")
		values = append(values, p.NumberWithMaximumAsInt64)
	}
	if float64(p.NumberWithMaximumAsInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int8 = ?")
		values = append(values, p.NumberWithMaximumAsInt8)
	}
	if float64(p.NumberWithMaximumAsUInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int = ?")
		values = append(values, p.NumberWithMaximumAsUInt)
	}
	if float64(p.NumberWithMaximumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int16 = ?")
		values = append(values, p.NumberWithMaximumAsUInt16)
	}
	if float64(p.NumberWithMaximumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int32 = ?")
		values = append(values, p.NumberWithMaximumAsUInt32)
	}
	if float64(p.NumberWithMaximumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int64 = ?")
		values = append(values, p.NumberWithMaximumAsUInt64)
	}
	if float64(p.NumberWithMaximumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int8 = ?")
		values = append(values, p.NumberWithMaximumAsUInt8)
	}
	if float64(p.NumberWithMinimumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float32 = ?")
		values = append(values, p.NumberWithMinimumAsFloat32)
	}
	if float64(p.NumberWithMinimumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float64 = ?")
		values = append(values, p.NumberWithMinimumAsFloat64)
	}
	if float64(p.NumberWithMinimumAsInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int = ?")
		values = append(values, p.NumberWithMinimumAsInt)
	}
	if float64(p.NumberWithMinimumAsInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int16 = ?")
		values = append(values, p.NumberWithMinimumAsInt16)
	}
	if float64(p.NumberWithMinimumAsInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int32 = ?")
		values = append(values, p.NumberWithMinimumAsInt32)
	}
	if float64(p.NumberWithMinimumAsInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int64 = ?")
		values = append(values, p.NumberWithMinimumAsInt64)
	}
	if float64(p.NumberWithMinimumAsInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int8 = ?")
		values = append(values, p.NumberWithMinimumAsInt8)
	}
	if float64(p.NumberWithMinimumAsUInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int = ?")
		values = append(values, p.NumberWithMinimumAsUInt)
	}
	if float64(p.NumberWithMinimumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int16 = ?")
		values = append(values, p.NumberWithMinimumAsUInt16)
	}
	if float64(p.NumberWithMinimumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int32 = ?")
		values = append(values, p.NumberWithMinimumAsUInt32)
	}
	if float64(p.NumberWithMinimumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int64 = ?")
		values = append(values, p.NumberWithMinimumAsUInt64)
	}
	if float64(p.NumberWithMinimumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int8 = ?")
		values = append(values, p.NumberWithMinimumAsUInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int16 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int8 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int16 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int8 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt8)
	}
	if len(columns) != 0 {
		psql = psql.Where(strings.Join(columns, " AND "), values...)
	}
	return psql.ToSql()
}

// GenerateSelectSQL generates plain select sql statement for the given Profile
func (p *Profile) GenerateSelectSQL() (string, []interface{}, error) {
	psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Select("*").From(p.TableName())
	columns := make([]string, 0)
	values := make([]interface{}, 0)
	if float64(p.ID) != float64(0) {
		columns = append(columns, "id = ?")
		values = append(values, p.ID)
	}
	if p.BooleanWithMaxLength != false {
		columns = append(columns, "boolean_with_max_length = ?")
		values = append(values, p.BooleanWithMaxLength)
	}
	if p.BooleanWithMinLength != false {
		columns = append(columns, "boolean_with_min_length = ?")
		values = append(values, p.BooleanWithMinLength)
	}
	if p.BooleanWithDefault != false {
		columns = append(columns, "boolean_with_default = ?")
		values = append(values, p.BooleanWithDefault)
	}
	if p.StringBare != "" {
		columns = append(columns, "string_bare = ?")
		values = append(values, p.StringBare)
	}
	if p.StringWithDefault != "" {
		columns = append(columns, "string_with_default = ?")
		values = append(values, p.StringWithDefault)
	}
	if p.StringWithMaxLength != "" {
		columns = append(columns, "string_with_max_length = ?")
		values = append(values, p.StringWithMaxLength)
	}
	if p.StringWithMinLength != "" {
		columns = append(columns, "string_with_min_length = ?")
		values = append(values, p.StringWithMinLength)
	}
	if p.StringWithMaxAndMinLength != "" {
		columns = append(columns, "string_with_max_and_min_length = ?")
		values = append(values, p.StringWithMaxAndMinLength)
	}
	if p.StringWithPattern != "" {
		columns = append(columns, "string_with_pattern = ?")
		values = append(values, p.StringWithPattern)
	}
	if !p.StringDateFormatted.IsZero() {
		columns = append(columns, "string_date_formatted = ?")
		values = append(values, p.StringDateFormatted)
	}
	if !p.StringDateFormattedWithDefault.IsZero() {
		columns = append(columns, "string_date_formatted_with_default = ?")
		values = append(values, p.StringDateFormattedWithDefault)
	}
	if p.StringUUIDFormatted != "" {
		columns = append(columns, "string_uuid_formatted = ?")
		values = append(values, p.StringUUIDFormatted)
	}
	if p.StringUUIDFormattedWithDefault != "" {
		columns = append(columns, "string_uuid_formatted_with_default = ?")
		values = append(values, p.StringUUIDFormattedWithDefault)
	}
	if float64(p.NumberBare) != float64(0) {
		columns = append(columns, "number_bare = ?")
		values = append(values, p.NumberBare)
	}
	if float64(p.NumberWithMultipleOf) != float64(0) {
		columns = append(columns, "number_with_multiple_of = ?")
		values = append(values, p.NumberWithMultipleOf)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsFloat32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_float32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsFloat32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt64) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int64 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt64)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt32)
	}
	if p.EnumBare != "" {
		columns = append(columns, "enum_bare = ?")
		values = append(values, p.EnumBare)
	}
	if float64(p.NumberWithExclusiveMaximumWithoutMaximum) != float64(0) {
		columns = append(columns, "number_with_exclusive_maximum_without_maximum = ?")
		values = append(values, p.NumberWithExclusiveMaximumWithoutMaximum)
	}
	if float64(p.NumberWithExclusiveMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum = ?")
		values = append(values, p.NumberWithExclusiveMinimum)
	}
	if float64(p.NumberWithExclusiveMinimumWithoutMinimum) != float64(0) {
		columns = append(columns, "number_with_exclusive_minimum_without_minimum = ?")
		values = append(values, p.NumberWithExclusiveMinimumWithoutMinimum)
	}
	if float64(p.NumberWithMaximum) != float64(0) {
		columns = append(columns, "number_with_maximum = ?")
		values = append(values, p.NumberWithMaximum)
	}
	if float64(p.NumberWithMaximumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float32 = ?")
		values = append(values, p.NumberWithMaximumAsFloat32)
	}
	if float64(p.NumberWithMaximumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_float64 = ?")
		values = append(values, p.NumberWithMaximumAsFloat64)
	}
	if float64(p.NumberWithMaximumAsInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int = ?")
		values = append(values, p.NumberWithMaximumAsInt)
	}
	if float64(p.NumberWithMaximumAsInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int16 = ?")
		values = append(values, p.NumberWithMaximumAsInt16)
	}
	if float64(p.NumberWithMaximumAsInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int32 = ?")
		values = append(values, p.NumberWithMaximumAsInt32)
	}
	if float64(p.NumberWithMaximumAsInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int64 = ?")
		values = append(values, p.NumberWithMaximumAsInt64)
	}
	if float64(p.NumberWithMaximumAsInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_int8 = ?")
		values = append(values, p.NumberWithMaximumAsInt8)
	}
	if float64(p.NumberWithMaximumAsUInt) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int = ?")
		values = append(values, p.NumberWithMaximumAsUInt)
	}
	if float64(p.NumberWithMaximumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int16 = ?")
		values = append(values, p.NumberWithMaximumAsUInt16)
	}
	if float64(p.NumberWithMaximumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int32 = ?")
		values = append(values, p.NumberWithMaximumAsUInt32)
	}
	if float64(p.NumberWithMaximumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int64 = ?")
		values = append(values, p.NumberWithMaximumAsUInt64)
	}
	if float64(p.NumberWithMaximumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_maximum_as_u_int8 = ?")
		values = append(values, p.NumberWithMaximumAsUInt8)
	}
	if float64(p.NumberWithMinimumAsFloat32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float32 = ?")
		values = append(values, p.NumberWithMinimumAsFloat32)
	}
	if float64(p.NumberWithMinimumAsFloat64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_float64 = ?")
		values = append(values, p.NumberWithMinimumAsFloat64)
	}
	if float64(p.NumberWithMinimumAsInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int = ?")
		values = append(values, p.NumberWithMinimumAsInt)
	}
	if float64(p.NumberWithMinimumAsInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int16 = ?")
		values = append(values, p.NumberWithMinimumAsInt16)
	}
	if float64(p.NumberWithMinimumAsInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int32 = ?")
		values = append(values, p.NumberWithMinimumAsInt32)
	}
	if float64(p.NumberWithMinimumAsInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int64 = ?")
		values = append(values, p.NumberWithMinimumAsInt64)
	}
	if float64(p.NumberWithMinimumAsInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_int8 = ?")
		values = append(values, p.NumberWithMinimumAsInt8)
	}
	if float64(p.NumberWithMinimumAsUInt) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int = ?")
		values = append(values, p.NumberWithMinimumAsUInt)
	}
	if float64(p.NumberWithMinimumAsUInt16) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int16 = ?")
		values = append(values, p.NumberWithMinimumAsUInt16)
	}
	if float64(p.NumberWithMinimumAsUInt32) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int32 = ?")
		values = append(values, p.NumberWithMinimumAsUInt32)
	}
	if float64(p.NumberWithMinimumAsUInt64) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int64 = ?")
		values = append(values, p.NumberWithMinimumAsUInt64)
	}
	if float64(p.NumberWithMinimumAsUInt8) != float64(0) {
		columns = append(columns, "number_with_minimum_as_u_int8 = ?")
		values = append(values, p.NumberWithMinimumAsUInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int16 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_int8 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsInt8)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt16) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int16 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt16)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt32) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int32 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt32)
	}
	if float64(p.NumberWithMultipleOfFormattedAsUInt8) != float64(0) {
		columns = append(columns, "number_with_multiple_of_formatted_as_u_int8 = ?")
		values = append(values, p.NumberWithMultipleOfFormattedAsUInt8)
	}
	if len(columns) != 0 {
		psql = psql.Where(strings.Join(columns, " AND "), values...)
	}
	return psql.ToSql()
}

// TableName returns the table name for Profile
func (p *Profile) TableName() string {
	return "account.profile"
}
`
