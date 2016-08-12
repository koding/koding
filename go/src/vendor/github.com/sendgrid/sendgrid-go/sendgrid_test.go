package sendgrid

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"
	"testing"
	"time"
)

var (
	testAPIKey = "SENDGRID_APIKEY"
	testHost   = ""
	prismPath  = os.Getenv("GOPATH") + "/bin"
	prismArgs  = []string{"run", "-s", "https://raw.githubusercontent.com/sendgrid/sendgrid-oai/master/oai_stoplight.json"}
	prismCmd   *exec.Cmd
	buffer     bytes.Buffer
	curl       *exec.Cmd
	sh         *exec.Cmd
)

func TestMain(m *testing.M) {
	// By default prism runs on localhost:4010
	// Learn how to configure prism here: https://designer.stoplight.io/docs/prism
	testHost = "http://localhost:4010"

	prismPath += "/prism"
	if runtime.GOOS == "windows" {
		prismPath += ".exe"
	}

	// Check if prism is installed, if not, install it
	if _, err := os.Stat(prismPath); os.IsNotExist(err) {
		if runtime.GOOS != "windows" {
			curl = exec.Command("curl", "https://raw.githubusercontent.com/stoplightio/prism/master/install.sh")
			sh = exec.Command("sh")
			read, write := io.Pipe()
			curl.Stdout = write
			sh.Stdin = read
			sh.Stdout = &buffer
			curl.Start()
			sh.Start()
			curl.Wait()
			write.Close()
			sh.Wait()
			_, err := io.Copy(os.Stdout, &buffer)
			if err != nil {
				fmt.Println("Error downloading the prism binary, you can try downloading directly here (https://github.com/stoplightio/prism/releases) and place in your $GOPATH/bin directory: ", err)
			}
		} else {
			fmt.Fprintf(os.Stderr, "Please download the Windows binary (https://github.com/stoplightio/prism/releases) and place it in your $GOPATH/bin directory")
			os.Exit(1)
		}
	}

	prismCmd = exec.Command(prismPath, prismArgs...)

	// If you want to see prism's ouput uncomment below.
	// prismReader, err := prismCmd.StdoutPipe()
	// if err != nil {
	// 	fmt.Println("Error creating StdoutPipe for Cmd", err)
	// }

	// scanner := bufio.NewScanner(prismReader)
	// go func() {
	// 	for scanner.Scan() {
	// 		fmt.Printf("prism | %s\n", scanner.Text())
	// 	}
	// }()

	go func() {
		fmt.Println("Start Prism")
		err := prismCmd.Start()
		if err != nil {
			fmt.Println("Error starting prism", err)
		}
	}()

	// Need to give prism enough time to launch!
	duration := time.Second * 15
	time.Sleep(duration)

	exitCode := m.Run()
	if prismCmd != nil {
		prismCmd.Process.Kill()
		prismCmd = nil
	}

	os.Exit(exitCode)
}

func TestSendGridVersion(t *testing.T) {
	if Version != "3.0.0" {
		t.Error("SendGrid version does not match")
	}
}

func TestGetRequest(t *testing.T) {
	request := GetRequest("", "", "")
	if request.BaseURL != "https://api.sendgrid.com" {
		t.Error("Host default not set")
	}
	if request.Headers["Authorization"] != "Bearer " {
		t.Error("Wrong default Authorization")
	}
	if request.Headers["User-Agent"] != "sendgrid/"+Version+";go" {
		t.Error("Wrong default User Agent")
	}

	request = GetRequest("API_KEY", "/v3/endpoint", "https://test.api.com")
	if request.BaseURL != "https://test.api.com/v3/endpoint" {
		t.Error("Host not set correctly")
	}
	if request.Headers["Authorization"] != "Bearer API_KEY" {
		t.Error("Wrong Authorization")
	}
	if request.Headers["User-Agent"] != "sendgrid/"+Version+";go" {
		t.Error("Wrong User Agent")
	}
	if request.Headers["Accept"] != "application/json" {
		t.Error("Wrong Accept header")
	}
}

func Test_test_access_settings_activity_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/activity", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_access_settings_whitelist_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/whitelist", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "ips": [
    {
      "ip": "192.168.1.1"
    },
    {
      "ip": "192.*.*.*"
    },
    {
      "ip": "192.168.1.3/32"
    }
  ]
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_access_settings_whitelist_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/whitelist", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_access_settings_whitelist_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/whitelist", host)
	request.Method = "DELETE"
	request.Body = []byte(` {
  "ids": [
    1,
    2,
    3
  ]
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_access_settings_whitelist__rule_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/whitelist/{rule_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_access_settings_whitelist__rule_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/access_settings/whitelist/{rule_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_alerts_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/alerts", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "email_to": "example@example.com",
  "frequency": "daily",
  "type": "stats_notification"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_alerts_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/alerts", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_alerts__alert_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/alerts/{alert_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "email_to": "example@example.com"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_alerts__alert_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/alerts/{alert_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_alerts__alert_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/alerts/{alert_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "name": "My API Key",
  "sample": "data",
  "scopes": [
    "mail.send",
    "alerts.create",
    "alerts.read"
  ]
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys__api_key_id__put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys/{api_key_id}", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "name": "A New Hope",
  "scopes": [
    "user.profile.read",
    "user.profile.update"
  ]
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys__api_key_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys/{api_key_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "name": "A New Hope"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys__api_key_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys/{api_key_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_api_keys__api_key_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/api_keys/{api_key_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "description": "Suggestions for products our users might like.",
  "is_default": true,
  "name": "Product Suggestions"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "description": "Suggestions for items our users might like.",
  "id": 103,
  "name": "Item Suggestions"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__suppressions_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}/suppressions", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "recipient_emails": [
    "test1@example.com",
    "test2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__suppressions_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}/suppressions", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__suppressions_search_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}/suppressions/search", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "recipient_emails": [
    "exists1@example.com",
    "exists2@example.com",
    "doesnotexists@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_groups__group_id__suppressions__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/groups/{group_id}/suppressions/{email}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_suppressions_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/suppressions", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_suppressions_global_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/suppressions/global", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "recipient_emails": [
    "test1@example.com",
    "test2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_suppressions_global__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/suppressions/global/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_suppressions_global__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/suppressions/global/{email}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_asm_suppressions__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/asm/suppressions/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_browsers_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/browsers/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["aggregated_by"] = "day"
	queryParams["browsers"] = "test_string"
	queryParams["limit"] = "test_string"
	queryParams["offset"] = "test_string"
	queryParams["start_date"] = "2016-01-01"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "categories": [
    "spring line"
  ],
  "custom_unsubscribe_url": "",
  "html_content": "<html><head><title></title></head><body><p>Check out our spring line!</p></body></html>",
  "ip_pool": "marketing",
  "list_ids": [
    110,
    124
  ],
  "plain_content": "Check out our spring line!",
  "segment_ids": [
    110
  ],
  "sender_id": 124451,
  "subject": "New Products for Spring!",
  "suppression_group_id": 42,
  "title": "March Newsletter"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "categories": [
    "summer line"
  ],
  "html_content": "<html><head><title></title></head><body><p>Check out our summer line!</p></body></html>",
  "plain_content": "Check out our summer line!",
  "subject": "New Products for Summer!",
  "title": "May Newsletter"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "send_at": 1489451436
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "send_at": 1489771528
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_now_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules/now", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_campaigns__campaign_id__schedules_test_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/campaigns/{campaign_id}/schedules/test", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "to": "your.email@example.com"
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_categories_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/categories", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["category"] = "test_string"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_categories_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/categories/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["categories"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_categories_stats_sums_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/categories/stats/sums", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["sort_by_metric"] = "test_string"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["sort_by_direction"] = "asc"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_clients_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/clients/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["aggregated_by"] = "day"
	queryParams["start_date"] = "2016-01-01"
	queryParams["end_date"] = "2016-04-01"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_clients__client_type__stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/clients/{client_type}/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["aggregated_by"] = "day"
	queryParams["start_date"] = "2016-01-01"
	queryParams["end_date"] = "2016-04-01"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_custom_fields_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/custom_fields", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "name": "pet",
  "type": "text"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_custom_fields_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/custom_fields", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_custom_fields__custom_field_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/custom_fields/{custom_field_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_custom_fields__custom_field_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/custom_fields/{custom_field_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "202"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 202 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "name": "your list name"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists", host)
	request.Method = "DELETE"
	request.Body = []byte(` [
  1,
  2,
  3,
  4
]`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "name": "newlistname"
}`)
	queryParams := make(map[string]string)
	queryParams["list_id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["list_id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}", host)
	request.Method = "DELETE"
	queryParams := make(map[string]string)
	queryParams["delete_contacts"] = "true"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "202"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 202 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__recipients_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}/recipients", host)
	request.Method = "POST"
	request.Body = []byte(` [
  "recipient_id1",
  "recipient_id2"
]`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__recipients_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}/recipients", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["page"] = "1"
	queryParams["page_size"] = "1"
	queryParams["list_id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__recipients__recipient_id__post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}/recipients/{recipient_id}", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_lists__list_id__recipients__recipient_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/lists/{list_id}/recipients/{recipient_id}", host)
	request.Method = "DELETE"
	queryParams := make(map[string]string)
	queryParams["recipient_id"] = "1"
	queryParams["list_id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients", host)
	request.Method = "PATCH"
	request.Body = []byte(` [
  {
    "email": "jones@example.com",
    "first_name": "Guy",
    "last_name": "Jones"
  }
]`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients", host)
	request.Method = "POST"
	request.Body = []byte(` [
  {
    "age": 25,
    "email": "example@example.com",
    "first_name": "",
    "last_name": "User"
  },
  {
    "age": 25,
    "email": "example2@example.com",
    "first_name": "Example",
    "last_name": "User"
  }
]`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["page"] = "1"
	queryParams["page_size"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients", host)
	request.Method = "DELETE"
	request.Body = []byte(` [
  "recipient_id1",
  "recipient_id2"
]`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_billable_count_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/billable_count", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_count_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/count", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients_search_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/search", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["{field_name}"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients__recipient_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/{recipient_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients__recipient_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/{recipient_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_recipients__recipient_id__lists_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/recipients/{recipient_id}/lists", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_reserved_fields_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/reserved_fields", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "conditions": [
    {
      "and_or": "",
      "field": "last_name",
      "operator": "eq",
      "value": "Miller"
    },
    {
      "and_or": "and",
      "field": "last_clicked",
      "operator": "gt",
      "value": "01/02/2015"
    },
    {
      "and_or": "or",
      "field": "clicks.campaign_identifier",
      "operator": "eq",
      "value": "513"
    }
  ],
  "list_id": 4,
  "name": "Last Name Miller"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments__segment_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments/{segment_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "conditions": [
    {
      "and_or": "",
      "field": "last_name",
      "operator": "eq",
      "value": "Miller"
    }
  ],
  "list_id": 5,
  "name": "The Millers"
}`)
	queryParams := make(map[string]string)
	queryParams["segment_id"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments__segment_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments/{segment_id}", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["segment_id"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments__segment_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments/{segment_id}", host)
	request.Method = "DELETE"
	queryParams := make(map[string]string)
	queryParams["delete_contacts"] = "true"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_contactdb_segments__segment_id__recipients_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/contactdb/segments/{segment_id}/recipients", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["page"] = "1"
	queryParams["page_size"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_devices_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/devices/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["end_date"] = "2016-04-01"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_geo_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/geo/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["country"] = "US"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["subuser"] = "test_string"
	queryParams["ip"] = "test_string"
	queryParams["limit"] = "1"
	queryParams["exclude_whitelabels"] = "true"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_assigned_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/assigned", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "name": "marketing"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools__pool_name__put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "name": "new_pool_name"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools__pool_name__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools__pool_name__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools/{pool_name}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools__pool_name__ips_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools/{pool_name}/ips", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "ip": "0.0.0.0"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_pools__pool_name__ips__ip__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/pools/{pool_name}/ips/{ip}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_warmup_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/warmup", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "ip": "0.0.0.0"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_warmup_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/warmup", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_warmup__ip_address__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/warmup/{ip_address}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips_warmup__ip_address__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/warmup/{ip_address}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_ips__ip_address__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/ips/{ip_address}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_batch_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail/batch", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_batch__batch_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail/batch/{batch_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_send_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail/send", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "asm": {
    "group_id": 1,
    "groups_to_display": [
      1,
      2,
      3
    ]
  },
  "attachments": [
    {
      "content": "[BASE64 encoded content block here]",
      "content_id": "ii_139db99fdb5c3704",
      "disposition": "inline",
      "filename": "file1.jpg",
      "name": "file1",
      "type": "jpg"
    }
  ],
  "batch_id": "[YOUR BATCH ID GOES HERE]",
  "categories": [
    "category1",
    "category2"
  ],
  "content": [
    {
      "type": "text/html",
      "value": "<html><p>Hello, world!</p><img src=[CID GOES HERE]></img></html>"
    }
  ],
  "custom_args": {
    "New Argument 1": "New Value 1",
    "activationAttempt": "1",
    "customerAccountNumber": "[CUSTOMER ACCOUNT NUMBER GOES HERE]"
  },
  "from": {
    "email": "sam.smith@example.com",
    "name": "Sam Smith"
  },
  "headers": {},
  "ip_pool_name": "[YOUR POOL NAME GOES HERE]",
  "mail_settings": {
    "bcc": {
      "email": "ben.doe@example.com",
      "enable": true
    },
    "bypass_list_management": {
      "enable": true
    },
    "footer": {
      "enable": true,
      "html": "<p>Thanks</br>The SendGrid Team</p>",
      "text": "Thanks,/n The SendGrid Team"
    },
    "sandbox_mode": {
      "enable": false
    },
    "spam_check": {
      "enable": true,
      "post_to_url": "http://example.com/compliance",
      "threshold": 3
    }
  },
  "personalizations": [
    {
      "bcc": [
        {
          "email": "sam.doe@example.com",
          "name": "Sam Doe"
        }
      ],
      "cc": [
        {
          "email": "jane.doe@example.com",
          "name": "Jane Doe"
        }
      ],
      "custom_args": {
        "New Argument 1": "New Value 1",
        "activationAttempt": "1",
        "customerAccountNumber": "[CUSTOMER ACCOUNT NUMBER GOES HERE]"
      },
      "headers": {
        "X-Accept-Language": "en",
        "X-Mailer": "MyApp"
      },
      "send_at": 1409348513,
      "subject": "Hello, World!",
      "substitutions": {
        "id": "substitutions",
        "type": "object"
      },
      "to": [
        {
          "email": "john.doe@example.com",
          "name": "John Doe"
        }
      ]
    }
  ],
  "reply_to": {
    "email": "sam.smith@example.com",
    "name": "Sam Smith"
  },
  "sections": {
    "section": {
      ":sectionName1": "section 1 text",
      ":sectionName2": "section 2 text"
    }
  },
  "send_at": 1409348513,
  "subject": "Hello, World!",
  "template_id": "[YOUR TEMPLATE ID GOES HERE]",
  "tracking_settings": {
    "click_tracking": {
      "enable": true,
      "enable_text": true
    },
    "ganalytics": {
      "enable": true,
      "utm_campaign": "[NAME OF YOUR REFERRER SOURCE]",
      "utm_content": "[USE THIS SPACE TO DIFFERENTIATE YOUR EMAIL FROM ADS]",
      "utm_medium": "[NAME OF YOUR MARKETING MEDIUM e.g. email]",
      "utm_name": "[NAME OF YOUR CAMPAIGN]",
      "utm_term": "[IDENTIFY PAID KEYWORDS HERE]"
    },
    "open_tracking": {
      "enable": true,
      "substitution_tag": "%opentrack"
    },
    "subscription_tracking": {
      "enable": true,
      "html": "If you would like to unsubscribe and stop receiving these emails <% clickhere %>.",
      "substitution_tag": "<%click here%>",
      "text": "If you would like to unsubscribe and stop receiveing these emails <% click here %>."
    }
  }
}`)
	request.Headers["X-Mock"] = "202"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 202 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_address_whitelist_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/address_whitelist", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "list": [
    "email1@example.com",
    "example.com"
  ]
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_address_whitelist_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/address_whitelist", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_bcc_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/bcc", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "email": "email@example.com",
  "enabled": false
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_bcc_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/bcc", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_bounce_purge_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/bounce_purge", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "hard_bounces": 5,
  "soft_bounces": 5
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_bounce_purge_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/bounce_purge", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_footer_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/footer", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "html_content": "...",
  "plain_content": "..."
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_footer_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/footer", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_forward_bounce_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/forward_bounce", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "email": "example@example.com",
  "enabled": true
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_forward_bounce_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/forward_bounce", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_forward_spam_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/forward_spam", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "email": "",
  "enabled": false
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_forward_spam_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/forward_spam", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_plain_content_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/plain_content", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": false
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_plain_content_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/plain_content", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_spam_check_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/spam_check", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "max_score": 5,
  "url": "url"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_spam_check_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/spam_check", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_template_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/template", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "html_content": "<% body %>"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mail_settings_template_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mail_settings/template", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_mailbox_providers_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/mailbox_providers/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["mailbox_providers"] = "test_string"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_partner_settings_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/partner_settings", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_partner_settings_new_relic_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/partner_settings/new_relic", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enable_subuser_statistics": true,
  "enabled": true,
  "license_key": ""
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_partner_settings_new_relic_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/partner_settings/new_relic", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_scopes_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/scopes", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "address": "123 Elm St.",
  "address_2": "Apt. 456",
  "city": "Denver",
  "country": "United States",
  "from": {
    "email": "from@example.com",
    "name": "Example INC"
  },
  "nickname": "My Sender ID",
  "reply_to": {
    "email": "replyto@example.com",
    "name": "Example INC"
  },
  "state": "Colorado",
  "zip": "80202"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders__sender_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders/{sender_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "address": "123 Elm St.",
  "address_2": "Apt. 456",
  "city": "Denver",
  "country": "United States",
  "from": {
    "email": "from@example.com",
    "name": "Example INC"
  },
  "nickname": "My Sender ID",
  "reply_to": {
    "email": "replyto@example.com",
    "name": "Example INC"
  },
  "state": "Colorado",
  "zip": "80202"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders__sender_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders/{sender_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders__sender_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders/{sender_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_senders__sender_id__resend_verification_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/senders/{sender_id}/resend_verification", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["end_date"] = "2016-04-01"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "email": "John@example.com",
  "ips": [
    "1.1.1.1",
    "2.2.2.2"
  ],
  "password": "johns_password",
  "username": "John@example.com"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["username"] = "test_string"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_reputations_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/reputations", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["usernames"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["subusers"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_stats_monthly_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/stats/monthly", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["subuser"] = "test_string"
	queryParams["limit"] = "1"
	queryParams["sort_by_metric"] = "test_string"
	queryParams["offset"] = "1"
	queryParams["date"] = "test_string"
	queryParams["sort_by_direction"] = "asc"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers_stats_sums_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/stats/sums", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["end_date"] = "2016-04-01"
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "1"
	queryParams["sort_by_metric"] = "test_string"
	queryParams["offset"] = "1"
	queryParams["start_date"] = "2016-01-01"
	queryParams["sort_by_direction"] = "asc"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "disabled": false
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__ips_put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/ips", host)
	request.Method = "PUT"
	request.Body = []byte(` [
  "127.0.0.1"
]`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__monitor_put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "email": "example@example.com",
  "frequency": 500
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__monitor_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "email": "example@example.com",
  "frequency": 50000
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__monitor_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__monitor_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/monitor", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_subusers__subuser_name__stats_monthly_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/subusers/{subuser_name}/stats/monthly", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["date"] = "test_string"
	queryParams["sort_by_direction"] = "asc"
	queryParams["limit"] = "1"
	queryParams["sort_by_metric"] = "test_string"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_blocks_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/blocks", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["start_time"] = "1"
	queryParams["limit"] = "1"
	queryParams["end_time"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_blocks_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/blocks", host)
	request.Method = "DELETE"
	request.Body = []byte(` {
  "delete_all": false,
  "emails": [
    "example1@example.com",
    "example2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_blocks__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/blocks/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_blocks__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/blocks/{email}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_bounces_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/bounces", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["start_time"] = "1"
	queryParams["end_time"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_bounces_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/bounces", host)
	request.Method = "DELETE"
	request.Body = []byte(` {
  "delete_all": true,
  "emails": [
    "example@example.com",
    "example2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_bounces__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/bounces/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_bounces__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/bounces/{email}", host)
	request.Method = "DELETE"
	queryParams := make(map[string]string)
	queryParams["email_address"] = "example@example.com"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_invalid_emails_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/invalid_emails", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["start_time"] = "1"
	queryParams["limit"] = "1"
	queryParams["end_time"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_invalid_emails_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/invalid_emails", host)
	request.Method = "DELETE"
	request.Body = []byte(` {
  "delete_all": false,
  "emails": [
    "example1@example.com",
    "example2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_invalid_emails__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/invalid_emails/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_invalid_emails__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/invalid_emails/{email}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_spam_report__email__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/spam_report/{email}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_spam_report__email__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/spam_report/{email}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_spam_reports_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/spam_reports", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["start_time"] = "1"
	queryParams["limit"] = "1"
	queryParams["end_time"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_spam_reports_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/spam_reports", host)
	request.Method = "DELETE"
	request.Body = []byte(` {
  "delete_all": false,
  "emails": [
    "example1@example.com",
    "example2@example.com"
  ]
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_suppression_unsubscribes_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/suppression/unsubscribes", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["start_time"] = "1"
	queryParams["limit"] = "1"
	queryParams["end_time"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "name": "example_name"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "name": "new_example_name"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__versions_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}/versions", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "active": 1,
  "html_content": "<%body%>",
  "name": "example_version_name",
  "plain_content": "<%body%>",
  "subject": "<%subject%>",
  "template_id": "ddb96bbc-9b92-425e-8979-99464621b543"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__versions__version_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "active": 1,
  "html_content": "<%body%>",
  "name": "updated_example_name",
  "plain_content": "<%body%>",
  "subject": "<%subject%>"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__versions__version_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__versions__version_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_templates__template_id__versions__version_id__activate_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/templates/{template_id}/versions/{version_id}/activate", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_click_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/click", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_click_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/click", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_google_analytics_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/google_analytics", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "utm_campaign": "website",
  "utm_content": "",
  "utm_medium": "email",
  "utm_source": "sendgrid.com",
  "utm_term": ""
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_google_analytics_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/google_analytics", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_open_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/open", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_open_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/open", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_subscription_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/subscription", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "enabled": true,
  "html_content": "html content",
  "landing": "landing page html",
  "plain_content": "text content",
  "replace": "replacement tag",
  "url": "url"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_tracking_settings_subscription_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/tracking_settings/subscription", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_account_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/account", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_credits_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/credits", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_email_put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/email", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "email": "example@example.com"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_email_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/email", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_password_put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/password", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "new_password": "new_password",
  "old_password": "old_password"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_profile_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/profile", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "city": "Orange",
  "first_name": "Example",
  "last_name": "User"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_profile_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/profile", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_scheduled_sends_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/scheduled_sends", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "batch_id": "YOUR_BATCH_ID",
  "status": "pause"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_scheduled_sends_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/scheduled_sends", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_scheduled_sends__batch_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/scheduled_sends/{batch_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "status": "pause"
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_scheduled_sends__batch_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/scheduled_sends/{batch_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_scheduled_sends__batch_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/scheduled_sends/{batch_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_settings_enforced_tls_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/settings/enforced_tls", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "require_tls": true,
  "require_valid_cert": false
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_settings_enforced_tls_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/settings/enforced_tls", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_username_put(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/username", host)
	request.Method = "PUT"
	request.Body = []byte(` {
  "username": "test_username"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_username_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/username", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_event_settings_patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/event/settings", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "bounce": true,
  "click": true,
  "deferred": true,
  "delivered": true,
  "dropped": true,
  "enabled": true,
  "group_resubscribe": true,
  "group_unsubscribe": true,
  "open": true,
  "processed": true,
  "spam_report": true,
  "unsubscribe": true,
  "url": "url"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_event_settings_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/event/settings", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_event_test_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/event/test", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "url": "url"
}`)
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_settings_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/settings", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "hostname": "myhostname.com",
  "send_raw": false,
  "spam_check": true,
  "url": "http://email.myhosthame.com"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_settings_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/settings", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_settings__hostname__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/settings/{hostname}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "send_raw": true,
  "spam_check": false,
  "url": "http://newdomain.com/parse"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_settings__hostname__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/settings/{hostname}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_settings__hostname__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/settings/{hostname}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_user_webhooks_parse_stats_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/user/webhooks/parse/stats", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["aggregated_by"] = "day"
	queryParams["limit"] = "test_string"
	queryParams["start_date"] = "2016-01-01"
	queryParams["end_date"] = "2016-04-01"
	queryParams["offset"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "automatic_security": false,
  "custom_spf": true,
  "default": true,
  "domain": "example.com",
  "ips": [
    "192.168.1.1",
    "192.168.1.2"
  ],
  "subdomain": "news",
  "username": "john@example.com"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["username"] = "test_string"
	queryParams["domain"] = "test_string"
	queryParams["exclude_subusers"] = "true"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains_default_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/default", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains_subuser_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/subuser", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains_subuser_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/subuser", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__domain_id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{domain_id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "custom_spf": true,
  "default": false
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__domain_id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{domain_id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__domain_id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{domain_id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__domain_id__subuser_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{domain_id}/subuser", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "username": "jane@example.com"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__id__ips_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{id}/ips", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "ip": "192.168.0.1"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__id__ips__ip__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{id}/ips/{ip}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_domains__id__validate_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/domains/{id}/validate", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_ips_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/ips", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "domain": "example.com",
  "ip": "192.168.1.1",
  "subdomain": "email"
}`)
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_ips_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/ips", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["ip"] = "test_string"
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_ips__id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/ips/{id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_ips__id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/ips/{id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_ips__id__validate_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/ips/{id}/validate", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "default": true,
  "domain": "example.com",
  "subdomain": "mail"
}`)
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	queryParams["offset"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "201"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 201 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["limit"] = "1"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links_default_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/default", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["domain"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links_subuser_get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/subuser", host)
	request.Method = "GET"
	queryParams := make(map[string]string)
	queryParams["username"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links_subuser_delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/subuser", host)
	request.Method = "DELETE"
	queryParams := make(map[string]string)
	queryParams["username"] = "test_string"
	request.QueryParams = queryParams
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links__id__patch(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/{id}", host)
	request.Method = "PATCH"
	request.Body = []byte(` {
  "default": true
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links__id__get(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/{id}", host)
	request.Method = "GET"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links__id__delete(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/{id}", host)
	request.Method = "DELETE"
	request.Headers["X-Mock"] = "204"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 204 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links__id__validate_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/{id}/validate", host)
	request.Method = "POST"
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}

func Test_test_whitelabel_links__link_id__subuser_post(t *testing.T) {
	apiKey := "SENDGRID_APIKEY"
	host := "http://localhost:4010"
	request := GetRequest(apiKey, "/v3/whitelabel/links/{link_id}/subuser", host)
	request.Method = "POST"
	request.Body = []byte(` {
  "username": "jane@example.com"
}`)
	request.Headers["X-Mock"] = "200"
	response, err := API(request)
	if err != nil {
		fmt.Println(err)
	}
	if response.StatusCode != 200 {
		t.Error("Wrong status code returned")
	}
}
