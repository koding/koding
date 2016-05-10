package tsm1_test

import (
	"fmt"
	"reflect"
	"testing"
	"time"

	"github.com/davecgh/go-spew/spew"
	"github.com/influxdata/influxdb/tsdb/engine/tsm1"
)

func TestEncoding_FloatBlock(t *testing.T) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, float64(i))
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %s\n\texp: %s\n", spew.Sdump(decodedValues), spew.Sdump(values))
	}
}

func TestEncoding_FloatBlock_ZeroTime(t *testing.T) {
	values := make([]tsm1.Value, 3)
	for i := 0; i < 3; i++ {
		values[i] = tsm1.NewValue(0, float64(i))
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues, values)
	}
}

func TestEncoding_FloatBlock_SimilarFloats(t *testing.T) {
	values := make([]tsm1.Value, 5)
	values[0] = tsm1.NewValue(1444238178437870000, 6.00065e+06)
	values[1] = tsm1.NewValue(1444238185286830000, 6.000656e+06)
	values[2] = tsm1.NewValue(1444238188441501000, 6.000657e+06)
	values[3] = tsm1.NewValue(1444238195286811000, 6.000659e+06)
	values[4] = tsm1.NewValue(1444238198439917000, 6.000661e+06)

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues, values)
	}
}

func TestEncoding_IntBlock_Basic(t *testing.T) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, int64(i))
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if len(decodedValues) != len(values) {
		t.Fatalf("unexpected results length:\n\tgot: %v\n\texp: %v\n", len(decodedValues), len(values))
	}

	for i := 0; i < len(decodedValues); i++ {
		if decodedValues[i].UnixNano() != values[i].UnixNano() {
			t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues[i].UnixNano(), values[i].UnixNano())
		}

		if decodedValues[i].Value() != values[i].Value() {
			t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues[i].Value(), values[i].Value())
		}
	}
}

func TestEncoding_IntBlock_Negatives(t *testing.T) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		v := int64(i)
		if i%2 == 0 {
			v = -v
		}
		values[i] = tsm1.NewValue(t, int64(v))
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues, values)
	}
}

func TestEncoding_BooleanBlock_Basic(t *testing.T) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		v := true
		if i%2 == 0 {
			v = false
		}
		values[i] = tsm1.NewValue(t, v)
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues, values)
	}
}

func TestEncoding_StringBlock_Basic(t *testing.T) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, fmt.Sprintf("value %d", i))
	}

	b, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	decodedValues, err = tsm1.DecodeBlock(b, decodedValues)
	if err != nil {
		t.Fatalf("unexpected error decoding block: %v", err)
	}

	if !reflect.DeepEqual(decodedValues, values) {
		t.Fatalf("unexpected results:\n\tgot: %v\n\texp: %v\n", decodedValues, values)
	}
}

func TestEncoding_BlockType(t *testing.T) {
	tests := []struct {
		value     interface{}
		blockType byte
	}{
		{value: float64(1.0), blockType: tsm1.BlockFloat64},
		{value: int64(1), blockType: tsm1.BlockInteger},
		{value: true, blockType: tsm1.BlockBoolean},
		{value: "string", blockType: tsm1.BlockString},
	}

	for _, test := range tests {
		var values []tsm1.Value
		values = append(values, tsm1.NewValue(0, test.value))

		b, err := tsm1.Values(values).Encode(nil)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		bt, err := tsm1.BlockType(b)
		if err != nil {
			t.Fatalf("unexpected error decoding block type: %v", err)
		}

		if got, exp := bt, test.blockType; got != exp {
			t.Fatalf("block type mismatch: got %v, exp %v", got, exp)
		}
	}

	_, err := tsm1.BlockType([]byte{10})
	if err == nil {
		t.Fatalf("expected error decoding block type, got nil")
	}
}

func TestEncoding_Count(t *testing.T) {
	tests := []struct {
		value     interface{}
		blockType byte
	}{
		{value: float64(1.0), blockType: tsm1.BlockFloat64},
		{value: int64(1), blockType: tsm1.BlockInteger},
		{value: true, blockType: tsm1.BlockBoolean},
		{value: "string", blockType: tsm1.BlockString},
	}

	for _, test := range tests {
		var values []tsm1.Value
		values = append(values, tsm1.NewValue(0, test.value))

		b, err := tsm1.Values(values).Encode(nil)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if got, exp := tsm1.BlockCount(b), 1; got != exp {
			t.Fatalf("block count mismatch: got %v, exp %v", got, exp)
		}
	}
}

func getTimes(n, step int, precision time.Duration) []int64 {
	t := time.Now().Round(precision).UnixNano()
	a := make([]int64, n)
	for i := 0; i < n; i++ {
		a[i] = t + (time.Duration(i*60) * precision).Nanoseconds()
	}
	return a
}

func BenchmarkDecodeBlock_Float_Empty(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, float64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Float_EqualSize(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, float64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.Value, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Float_TypeSpecific(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, float64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.FloatValue, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeFloatBlock(bytes, tsm1.NewTimeDecoder(), &tsm1.FloatDecoder{}, &decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Integer_Empty(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, int64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Integer_EqualSize(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, int64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.Value, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Integer_TypeSpecific(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, int64(i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.IntegerValue, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeIntegerBlock(bytes, tsm1.NewTimeDecoder(), &tsm1.IntegerDecoder{}, &decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Boolean_Empty(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, true)
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Boolean_EqualSize(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, true)
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.Value, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_Boolean_TypeSpecific(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, true)
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.BooleanValue, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBooleanBlock(bytes, tsm1.NewTimeDecoder(), &tsm1.BooleanDecoder{}, &decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_String_Empty(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, fmt.Sprintf("value %d", i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	var decodedValues []tsm1.Value
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_String_EqualSize(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, fmt.Sprintf("value %d", i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.Value, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeBlock(bytes, decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkDecodeBlock_String_TypeSpecific(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, fmt.Sprintf("value %d", i))
	}

	bytes, err := tsm1.Values(values).Encode(nil)
	if err != nil {
		b.Fatalf("unexpected error: %v", err)
	}

	decodedValues := make([]tsm1.StringValue, len(values))
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err = tsm1.DecodeStringBlock(bytes, tsm1.NewTimeDecoder(), &tsm1.StringDecoder{}, &decodedValues)
		if err != nil {
			b.Fatalf("unexpected error decoding block: %v", err)
		}
	}
}

func BenchmarkValues_Deduplicate(b *testing.B) {
	valueCount := 1000
	times := getTimes(valueCount, 60, time.Second)
	values := make([]tsm1.Value, len(times))
	for i, t := range times {
		values[i] = tsm1.NewValue(t, fmt.Sprintf("value %d", i))
	}
	values = append(values, values...)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		tsm1.Values(values).Deduplicate()
	}
}
