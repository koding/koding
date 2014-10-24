package jwt

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"reflect"
	"testing"
	"time"
)

var (
	jwtTestDefaultKey []byte
	defaultKeyFunc    Keyfunc = func(t *Token) (interface{}, error) { return jwtTestDefaultKey, nil }
	emptyKeyFunc      Keyfunc = func(t *Token) (interface{}, error) { return nil, nil }
	errorKeyFunc      Keyfunc = func(t *Token) (interface{}, error) { return nil, fmt.Errorf("error loading key") }
	nilKeyFunc        Keyfunc = nil
)

var jwtTestData = []struct {
	name            string
	tokenString     string
	keyfunc         Keyfunc
	claims          map[string]interface{}
	valid           bool
	validationError *ValidationError
}{
	{
		"basic",
		"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.FhkiHkoESI_cG3NPigFrxEk9Z60_oXrOT2vGm9Pn6RDgYNovYORQmmA0zs1AoAOf09ly2Nx2YAg6ABqAYga1AcMFkJljwxTT5fYphTuqpWdy4BELeSYJx5Ty2gmr8e7RonuUztrdD5WfPqLKMm1Ozp_T6zALpRmwTIW0QPnaBXaQD90FplAg46Iy1UlDKr-Eupy0i5SLch5Q-p2ZpaL_5fnTIUDlxC3pWhJTyx_71qDI-mAA_5lE_VdroOeflG56sSmDxopPEG3bFlSu1eowyBfxtu0_CuVd-M42RU75Zc4Gsj6uV77MBtbMrf4_7M_NUTSgoIF3fRqxrj0NzihIBg",
		defaultKeyFunc,
		map[string]interface{}{"foo": "bar"},
		true,
		nil,
	},
	{
		"basic expired",
		"", // autogen
		defaultKeyFunc,
		map[string]interface{}{"foo": "bar", "exp": float64(time.Now().Unix() - 100)},
		false,
		&ValidationError{Errors: ValidationErrorExpired},
	},
	{
		"basic nbf",
		"", // autogen
		defaultKeyFunc,
		map[string]interface{}{"foo": "bar", "nbf": float64(time.Now().Unix() + 100)},
		false,
		&ValidationError{Errors: ValidationErrorNotValidYet},
	},
	{
		"expired and nbf",
		"", // autogen
		defaultKeyFunc,
		map[string]interface{}{"foo": "bar", "nbf": float64(time.Now().Unix() + 100), "exp": float64(time.Now().Unix() - 100)},
		false,
		&ValidationError{Errors: ValidationErrorNotValidYet | ValidationErrorExpired},
	},
	{
		"basic invalid",
		"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.EhkiHkoESI_cG3NPigFrxEk9Z60_oXrOT2vGm9Pn6RDgYNovYORQmmA0zs1AoAOf09ly2Nx2YAg6ABqAYga1AcMFkJljwxTT5fYphTuqpWdy4BELeSYJx5Ty2gmr8e7RonuUztrdD5WfPqLKMm1Ozp_T6zALpRmwTIW0QPnaBXaQD90FplAg46Iy1UlDKr-Eupy0i5SLch5Q-p2ZpaL_5fnTIUDlxC3pWhJTyx_71qDI-mAA_5lE_VdroOeflG56sSmDxopPEG3bFlSu1eowyBfxtu0_CuVd-M42RU75Zc4Gsj6uV77MBtbMrf4_7M_NUTSgoIF3fRqxrj0NzihIBg",
		defaultKeyFunc,
		map[string]interface{}{"foo": "bar"},
		false,
		&ValidationError{Errors: ValidationErrorSignatureInvalid},
	},
	{
		"basic nokeyfunc",
		"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.FhkiHkoESI_cG3NPigFrxEk9Z60_oXrOT2vGm9Pn6RDgYNovYORQmmA0zs1AoAOf09ly2Nx2YAg6ABqAYga1AcMFkJljwxTT5fYphTuqpWdy4BELeSYJx5Ty2gmr8e7RonuUztrdD5WfPqLKMm1Ozp_T6zALpRmwTIW0QPnaBXaQD90FplAg46Iy1UlDKr-Eupy0i5SLch5Q-p2ZpaL_5fnTIUDlxC3pWhJTyx_71qDI-mAA_5lE_VdroOeflG56sSmDxopPEG3bFlSu1eowyBfxtu0_CuVd-M42RU75Zc4Gsj6uV77MBtbMrf4_7M_NUTSgoIF3fRqxrj0NzihIBg",
		nilKeyFunc,
		map[string]interface{}{"foo": "bar"},
		false,
		&ValidationError{Errors: ValidationErrorUnverifiable},
	},
	{
		"basic nokey",
		"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.FhkiHkoESI_cG3NPigFrxEk9Z60_oXrOT2vGm9Pn6RDgYNovYORQmmA0zs1AoAOf09ly2Nx2YAg6ABqAYga1AcMFkJljwxTT5fYphTuqpWdy4BELeSYJx5Ty2gmr8e7RonuUztrdD5WfPqLKMm1Ozp_T6zALpRmwTIW0QPnaBXaQD90FplAg46Iy1UlDKr-Eupy0i5SLch5Q-p2ZpaL_5fnTIUDlxC3pWhJTyx_71qDI-mAA_5lE_VdroOeflG56sSmDxopPEG3bFlSu1eowyBfxtu0_CuVd-M42RU75Zc4Gsj6uV77MBtbMrf4_7M_NUTSgoIF3fRqxrj0NzihIBg",
		emptyKeyFunc,
		map[string]interface{}{"foo": "bar"},
		false,
		&ValidationError{Errors: ValidationErrorSignatureInvalid},
	},
	{
		"basic errorkey",
		"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.FhkiHkoESI_cG3NPigFrxEk9Z60_oXrOT2vGm9Pn6RDgYNovYORQmmA0zs1AoAOf09ly2Nx2YAg6ABqAYga1AcMFkJljwxTT5fYphTuqpWdy4BELeSYJx5Ty2gmr8e7RonuUztrdD5WfPqLKMm1Ozp_T6zALpRmwTIW0QPnaBXaQD90FplAg46Iy1UlDKr-Eupy0i5SLch5Q-p2ZpaL_5fnTIUDlxC3pWhJTyx_71qDI-mAA_5lE_VdroOeflG56sSmDxopPEG3bFlSu1eowyBfxtu0_CuVd-M42RU75Zc4Gsj6uV77MBtbMrf4_7M_NUTSgoIF3fRqxrj0NzihIBg",
		errorKeyFunc,
		map[string]interface{}{"foo": "bar"},
		false,
		&ValidationError{Errors: ValidationErrorUnverifiable},
	},
}

func init() {
	var e error
	if jwtTestDefaultKey, e = ioutil.ReadFile("test/sample_key.pub"); e != nil {
		panic(e)
	}
}

func makeSample(c map[string]interface{}) string {
	key, e := ioutil.ReadFile("test/sample_key")
	if e != nil {
		panic(e.Error())
	}

	token := New(GetSigningMethod("RS256"))
	token.Claims = c
	s, e := token.SignedString(key)

	if e != nil {
		panic(e.Error())
	}

	return s
}

func TestJWT(t *testing.T) {
	for _, data := range jwtTestData {
		if data.tokenString == "" {
			data.tokenString = makeSample(data.claims)
		}
		token, err := Parse(data.tokenString, data.keyfunc)

		if !reflect.DeepEqual(data.claims, token.Claims) {
			t.Errorf("[%v] Claims mismatch. Expecting: %v  Got: %v", data.name, data.claims, token.Claims)
		}
		if data.valid && err != nil {
			t.Errorf("[%v] Error while verifying token: %T:%v", data.name, err, err)
		}
		if !data.valid && err == nil {
			t.Errorf("[%v] Invalid token passed validation", data.name)
		}
		if data.validationError != nil {
			if err == nil {
				t.Errorf("[%v] Expecting error.  Didn't get one.", data.name)
			} else {
				// perform deep equal without the string bit
				err.(*ValidationError).err = ""
				if !reflect.DeepEqual(data.validationError, err) {
					t.Errorf("[%v] Errors don't match expectation", data.name)
				}

			}
		}
	}
}

func TestParseRequest(t *testing.T) {
	// Bearer token request
	for _, data := range jwtTestData {
		if data.tokenString == "" {
			data.tokenString = makeSample(data.claims)
		}

		r, _ := http.NewRequest("GET", "/", nil)
		r.Header.Set("Authorization", fmt.Sprintf("Bearer %v", data.tokenString))
		token, err := ParseFromRequest(r, data.keyfunc)

		if !reflect.DeepEqual(data.claims, token.Claims) {
			t.Errorf("[%v] Claims mismatch. Expecting: %v  Got: %v", data.name, data.claims, token.Claims)
		}
		if data.valid && err != nil {
			t.Errorf("[%v] Error while verifying token: %v", data.name, err)
		}
		if !data.valid && err == nil {
			t.Errorf("[%v] Invalid token passed validation", data.name)
		}
	}
}
