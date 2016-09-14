package mailgun

import (
	"fmt"
	"io/ioutil"
	"strings"
	"testing"
	"time"
)

const (
	fromUser       = "=?utf-8?q?Katie_Brewer=2C_CFP=C2=AE?= <joe@example.com>"
	exampleSubject = "Joe's Example Subject"
	exampleText    = "Testing some Mailgun awesomeness!"
	exampleHtml    = "<html><head /><body><p>Testing some <a href=\"http://google.com?q=abc&r=def&s=ghi\">Mailgun HTML awesomeness!</a> at www.kc5tja@yahoo.com</p></body></html>"

	exampleMime = `Content-Type: text/plain; charset="ascii"
Subject: Joe's Example Subject
From: Joe Example <joe@example.com>
To: BARGLEGARF <sam.falvo@rackspace.com>
Content-Transfer-Encoding: 7bit
Date: Thu, 6 Mar 2014 00:37:52 +0000

Testing some Mailgun MIME awesomeness!
`
	templateText = "Greetings %recipient.name%!  Your reserved seat is at table %recipient.table%."
)

func TestSendLegacyPlain(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText, toUser)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlain:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyPlainWithTracking(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetTracking(true)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlainWithTracking:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyPlainAt(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetDeliveryTime(time.Now().Add(5 * time.Minute))
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlainAt:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyHtml(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetHtml(exampleHtml)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendHtml:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyTracking(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText+"Tracking!\n", toUser)
		m.SetTracking(false)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendTracking:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyTag(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := NewMessage(fromUser, exampleSubject, exampleText+"Tags Galore!\n", toUser)
		m.AddTag("FooTag")
		m.AddTag("BarTag")
		m.AddTag("BlortTag")
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendTag:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendLegacyMIME(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		mg := NewMailgun(domain, apiKey, "")
		m := NewMIMEMessage(ioutil.NopCloser(strings.NewReader(exampleMime)), toUser)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendMIME:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestGetStoredMessage(t *testing.T) {
	spendMoney(t, func() {
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		mg := NewMailgun(domain, apiKey, "")
		id, err := findStoredMessageID(mg) // somehow...
		if err != nil {
			t.Log(err)
			return
		}

		// First, get our stored message.
		msg, err := mg.GetStoredMessage(id)
		if err != nil {
			t.Fatal(err)
		}
		fields := map[string]string{
			"       From": msg.From,
			"     Sender": msg.Sender,
			"    Subject": msg.Subject,
			"Attachments": fmt.Sprintf("%d", len(msg.Attachments)),
			"    Headers": fmt.Sprintf("%d", len(msg.MessageHeaders)),
		}
		for k, v := range fields {
			fmt.Printf("%13s: %s\n", k, v)
		}

		// We're done with it; now delete it.
		err = mg.DeleteStoredMessage(id)
		if err != nil {
			t.Fatal(err)
		}
	})
}

// Tries to locate the first stored event type, returning the associated stored message key.
func findStoredMessageID(mg Mailgun) (string, error) {
	ei := mg.NewEventIterator()
	err := ei.GetFirstPage(GetEventsOptions{})
	for {
		if err != nil {
			return "", err
		}
		if len(ei.Events()) == 0 {
			break
		}
		for _, event := range ei.Events() {
			if event["event"] == "stored" {
				s := event["storage"].(map[string]interface{})
				k := s["key"]
				return k.(string), nil
			}
		}
		err = ei.GetNext()
	}
	return "", fmt.Errorf("No stored messages found.  Try changing MG_EMAIL_TO to an address that stores messages and try again.")
}

func TestSendMGPlain(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText, toUser)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlain:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGPlainWithTracking(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetTracking(true)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlainWithTracking:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGPlainAt(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetDeliveryTime(time.Now().Add(5 * time.Minute))
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendPlainAt:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGHtml(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText, toUser)
		m.SetHtml(exampleHtml)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendHtml:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGTracking(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText+"Tracking!\n", toUser)
		m.SetTracking(false)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendTracking:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGTag(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		publicApiKey := reqEnv(t, "MG_PUBLIC_API_KEY")
		mg := NewMailgun(domain, apiKey, publicApiKey)
		m := mg.NewMessage(fromUser, exampleSubject, exampleText+"Tags Galore!\n", toUser)
		m.AddTag("FooTag")
		m.AddTag("BarTag")
		m.AddTag("BlortTag")
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendTag:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGMIME(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		mg := NewMailgun(domain, apiKey, "")
		m := mg.NewMIMEMessage(ioutil.NopCloser(strings.NewReader(exampleMime)), toUser)
		msg, id, err := mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("TestSendMIME:MSG(" + msg + "),ID(" + id + ")")
	})
}

func TestSendMGBatchFailRecipients(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		mg := NewMailgun(domain, apiKey, "")
		m := mg.NewMessage(fromUser, exampleSubject, exampleText+"Batch\n")
		for i := 0; i < MaxNumberOfRecipients; i++ {
			m.AddRecipient("") // We expect this to indicate a failure at the API
		}
		err := m.AddRecipientAndVariables(toUser, nil)
		if err == nil {
			// If we're here, either the SDK didn't send the message,
			// OR the API didn't check for empty To: headers.
			t.Fatal("Expected to fail!!")
		}
	})
}

func TestSendMGBatchRecipientVariables(t *testing.T) {
	spendMoney(t, func() {
		toUser := reqEnv(t, "MG_EMAIL_TO")
		domain := reqEnv(t, "MG_DOMAIN")
		apiKey := reqEnv(t, "MG_API_KEY")
		mg := NewMailgun(domain, apiKey, "")
		m := mg.NewMessage(fromUser, exampleSubject, templateText)
		err := m.AddRecipientAndVariables(toUser, map[string]interface{}{
			"name":  "Joe Cool Example",
			"table": 42,
		})
		if err != nil {
			t.Fatal(err)
		}
		_, _, err = mg.Send(m)
		if err != nil {
			t.Fatal(err)
		}
	})
}
