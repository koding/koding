package metrics

import (
	"bytes"
	"encoding/json"
	"koding/tools/utils"
	"math/rand"
	"testing"
)

var td = [][]byte{
	[]byte(`config_show_timing:1.63938732|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:2.6393873|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:3.639387|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:4.63938|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:5.6393|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:6.639|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:7.63|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
	[]byte(`config_show_timing:8|ms|#commandName:config_show,rootCommandName:config,subCommandName:show,debug:false,endpoints_ipCheck_public:https://p.koding.com/-/ipcheck,endpoints_ip_public:https://p.koding.com/-/ip,endpoints_kdLatest_public:https://koding-kd.s3.amazonaws.com/production/latest-version.txt,endpoints_klientLatest_public:https://koding-klient.s3.amazonaws.com/production/latest-version.txt,endpoints_klient_private:http://127.0.0.1:56789/kite,endpoints_koding_private:http://127.0.0.1,endpoints_koding_public:https://koding.com,endpoints_tunnel_public:http://t.koding.com/kite,teamName:team,success:true`),
}

func TestCustomWithRealData(t *testing.T) {
	gzm := &PublishRequest{
		Data: GzippedPayload(td),
	}

	testCustom(t, gzm)
}

func TestCustomWithRandomLengths(t *testing.T) {
	gzm := newRandomPublishReq(20)
	testCustom(t, gzm)
}

func newRandomPublishReq(n int) *PublishRequest {
	data := make([][]byte, n)
	for i := range data {
		data[i] = []byte(utils.Pwgen(rand.Intn(500)))
	}

	return &PublishRequest{
		Data: GzippedPayload(data),
	}
}
func TestNullMarshal(t *testing.T) {
	gzm := PublishRequest{}
	d, err := json.Marshal(gzm)
	if err != nil {
		t.Fatalf("json.Marshal(gzm == %v, want %v", err, nil)
	}

	v := &PublishRequest{}
	err = json.Unmarshal(d, v)
	if err != nil {
		t.Fatalf("json.Unmarshal(d, v) == %v, want %v", err, nil)
	}

	if v.Data != nil {
		t.Fatalf("v.Data == %v, want %v", v.Data, nil)
	}
}

func testCustom(t *testing.T, gzm *PublishRequest) {
	d, err := json.Marshal(gzm)
	if err != nil {
		t.Fatalf("json.Marshal(gzm == %v, want %v", err, nil)
	}

	v := &PublishRequest{}
	err = json.Unmarshal(d, v)
	if err != nil {
		t.Fatalf("json.Unmarshal(d, v) == %v, want %v", err, nil)
	}

	for i, d := range gzm.Data {
		if !bytes.Equal(d, v.Data[i]) {
			t.Fatalf("!bytes.Equal(%q, v.Data[%d]%q)", d, i, v.Data[i])
		}
	}
}
