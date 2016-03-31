package stringext

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"
)

var testData = []struct {
	Value                   string
	ToLowerFirst            string
	ToUpperFirst            string
	Pointerize              string
	JSONTag                 string
	JSONTagRequired         string
	Normalize               string
	ToFieldName             string
	DepunctWithInitialUpper string
	DepunctWithInitialLower string
	Capitalize              string
}{
	{
		Value:                   "name",
		ToLowerFirst:            "name",
		ToUpperFirst:            "Name",
		Pointerize:              "n",
		JSONTag:                 "`json:\"name,omitempty\"`",
		JSONTagRequired:         "`json:\"name\"`",
		Normalize:               "name",
		ToFieldName:             "name",
		DepunctWithInitialUpper: "Name",
		DepunctWithInitialLower: "name",
		Capitalize:              "Name",
	},
	{
		Value:                   "provider_id",
		ToLowerFirst:            "provider_id",
		ToUpperFirst:            "Provider_id",
		Pointerize:              "p",
		JSONTag:                 "`json:\"providerId,omitempty\"`",
		JSONTagRequired:         "`json:\"providerId\"`",
		Normalize:               "providerId",
		ToFieldName:             "provider_id",
		DepunctWithInitialUpper: "ProviderID",
		DepunctWithInitialLower: "providerID",
		Capitalize:              "Provider_id",
	},
	{
		Value:                   "app-identity",
		ToLowerFirst:            "app-identity",
		ToUpperFirst:            "App-identity",
		Pointerize:              "a",
		JSONTag:                 "`json:\"appIdentity,omitempty\"`",
		JSONTagRequired:         "`json:\"appIdentity\"`",
		Normalize:               "appIdentity",
		ToFieldName:             "app_identity",
		DepunctWithInitialUpper: "AppIdentity",
		DepunctWithInitialLower: "appIdentity",
		Capitalize:              "App-identity",
	},
	{
		Value:                   "uuid",
		ToLowerFirst:            "uuid",
		ToUpperFirst:            "Uuid",
		Pointerize:              "u",
		JSONTag:                 "`json:\"uuid,omitempty\"`",
		JSONTagRequired:         "`json:\"uuid\"`",
		Normalize:               "uuid",
		ToFieldName:             "uuid",
		DepunctWithInitialUpper: "UUID",
		DepunctWithInitialLower: "uuid",
		Capitalize:              "Uuid",
	},
	{
		Value:                   "oauth-client",
		ToLowerFirst:            "oauth-client",
		ToUpperFirst:            "Oauth-client",
		Pointerize:              "o",
		JSONTag:                 "`json:\"oauthClient,omitempty\"`",
		JSONTagRequired:         "`json:\"oauthClient\"`",
		Normalize:               "oauthClient",
		ToFieldName:             "oauth_client",
		DepunctWithInitialUpper: "OAuthClient",
		DepunctWithInitialLower: "oauthClient",
		Capitalize:              "Oauth-client",
	},
	{
		Value:                   "Dyno all",
		ToLowerFirst:            "dyno all",
		ToUpperFirst:            "Dyno all",
		Pointerize:              "d",
		JSONTag:                 "`json:\"dynoAll,omitempty\"`",
		JSONTagRequired:         "`json:\"dynoAll\"`",
		Normalize:               "DynoAll",
		ToFieldName:             "dyno_all",
		DepunctWithInitialUpper: "DynoAll",
		DepunctWithInitialLower: "DynoAll",
		Capitalize:              "Dyno all",
	},
	{
		Value:                   "providerId",
		ToLowerFirst:            "providerId",
		ToUpperFirst:            "ProviderId",
		Pointerize:              "p",
		JSONTag:                 "`json:\"providerId,omitempty\"`",
		JSONTagRequired:         "`json:\"providerId\"`",
		Normalize:               "providerId",
		ToFieldName:             "provider_id",
		DepunctWithInitialUpper: "ProviderID",
		DepunctWithInitialLower: "providerID",
		Capitalize:              "Providerid",
	},
	{
		Value:                   "Id",
		ToLowerFirst:            "id",
		ToUpperFirst:            "Id",
		Pointerize:              "i",
		JSONTag:                 "`json:\"id,omitempty\"`",
		JSONTagRequired:         "`json:\"id\"`",
		Normalize:               "Id",
		ToFieldName:             "id",
		DepunctWithInitialUpper: "ID",
		DepunctWithInitialLower: "ID",
		Capitalize:              "Id",
	},
}

func TestToLowerFirst(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.ToLowerFirst, ToLowerFirst(ict.Value))
	}
}

func TestUpperFirst(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.ToUpperFirst, ToUpperFirst(ict.Value))
	}
}

func TestPointerize(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.Pointerize, Pointerize(ict.Value))
	}
}

func TestJSONTag(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.JSONTag, JSONTag(ict.Value, false))
	}
}

func TestJSONTagRequired(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.JSONTagRequired, JSONTag(ict.Value, true))
	}
}

func TestNormalize(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.Normalize, Normalize(ict.Value))
	}
}

func TestToFieldName(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.ToFieldName, ToFieldName(ict.Value))
	}
}

func TestDepunctWithInitialUpper(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.DepunctWithInitialUpper, DepunctWithInitialUpper(ict.Value))
	}
}

func TestDepunctWithInitialLower(t *testing.T) {
	for _, ict := range testData {
		equals(t, ict.DepunctWithInitialLower, DepunctWithInitialLower(ict.Value))
	}
}

func equals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.Fail()
	}
}

func TestAsComment(t *testing.T) {
	const data = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?"
	const res = `// Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium
// doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore
// veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim
// ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia
// consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque
// porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur,
// adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et
// dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis
// nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex
// ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea
// voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem
// eum fugiat quo voluptas nulla pariatur?
`
	equals(t, AsComment(data), res)

	const utfData = "Mesela karışık beyaz depo erkek çirkin. Taraftar dur acil dana bundan but manyak çünkü. Sürücü bugün ayna dört bacak ondan gidilmez eşşek yapılmaz portakal sarı. Ekran dün salı araç git eğlence kırk mor koç. Dün petrol abaküs felaket afet milyon niçin doğa tatlı resim şu dalga. Askı yeşil düzeysiz balya politika esinti dükkan pazar deniz plastik. Demokrasi sekiz ahenk çay civa bagaj düşün ehliyet meslek disiplin depo ne. Garanti dosya geri han."
	const utfRes = `// Mesela karışık beyaz depo erkek çirkin. Taraftar dur acil dana bundan but
// manyak çünkü. Sürücü bugün ayna dört bacak ondan gidilmez eşşek
// yapılmaz portakal sarı. Ekran dün salı araç git eğlence kırk mor koç.
// Dün petrol abaküs felaket afet milyon niçin doğa tatlı resim şu dalga.
// Askı yeşil düzeysiz balya politika esinti dükkan pazar deniz plastik.
// Demokrasi sekiz ahenk çay civa bagaj düşün ehliyet meslek disiplin depo
// ne. Garanti dosya geri han.
`
	equals(t, AsComment(utfData), utfRes)
}

func TestContains(t *testing.T) {
	d := []string{"foo", "bar", "zaa"}
	equals(t, Contains("foo", d), true)
	equals(t, Contains("bar", d), true)
	equals(t, Contains("zaa", d), true)
	equals(t, Contains("qux", d), false)

}
