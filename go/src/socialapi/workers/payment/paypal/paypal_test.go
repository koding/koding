package paypal

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"net/url"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/stripe"
	"strconv"
	"time"

	"github.com/koding/paypal"
	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	StartingPlan     = "developer"
	StartingInterval = "month"
	Creds            config.Paypal
)

func init() {
	r := runner.New("paypaltest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	Creds = r.Conf.Paypal
	InitializeClientKey(r.Conf.Paypal)

	stripe.CreateDefaultPlans()

	rand.Seed(time.Now().UTC().UnixNano())
}

func generateToken() string {
	return strconv.Itoa(rand.Int())
}

func generateFakeUserInfo() (string, string, string) {
	token, accId := generateToken(), bson.NewObjectId().Hex()
	email := accId + "@koding.com"

	return token, accId, email
}

func subscribeFn(fn func(string, string, string)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId)

		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
}

func checkCustomerIsSaved(accId string) bool {
	customerModel, err := FindCustomerByOldId(accId)
	if err != nil {
		return false
	}

	if customerModel == nil {
		return false
	}

	if customerModel.OldId != accId {
		return false
	}

	return true
}

func startTestServer() *httptest.Server {
	server := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			_ = r.ParseForm()

			var resp []byte
			switch r.Form.Get("METHOD") {
			case "SetExpressCheckout":
				resp = tokenResponse()
			case "GetExpressCheckoutDetails":
				resp = checkoutResponse()
			case "CreateRecurringPaymentsProfile":
				resp = subscribeResponse()
			}

			w.Write(resp)
		},
	))

	returnURL = Creds.ReturnUrl
	cancelURL = Creds.CancelUrl

	client = paypal.NewDefaultClientEndpoint(
		Creds.Username, Creds.Password, Creds.Signature, server.URL, true,
	)

	return server
}

func subscribeResponse() []byte {
	profileId := strconv.Itoa(rand.Int())

	values := url.Values{}
	values.Set("ACK", "Success")
	values.Set("BUILD", "13630372")
	values.Set("CORRELATIONID", "7f7363b7c00fa")
	values.Set("PROFILEID", profileId)
	values.Set("PROFILESTATUS", "ActiveProfile")
	values.Set("TIMESTAMP", "2014-11-04T23:18:28Z")
	values.Set("VERSION", "84")

	return []byte(values.Encode())
}

func checkoutResponse() []byte {
	values := url.Values{}
	values.Set("ACK", "Success")
	values.Set("L_PAYMENTREQUEST_0_NAME0", "hobbyist-month")

	return []byte(values.Encode())
}

func tokenResponse() []byte {
	values := url.Values{}
	values.Set("ACK", "Success")
	values.Set("TOKEN", generateToken())

	return []byte(values.Encode())
}
