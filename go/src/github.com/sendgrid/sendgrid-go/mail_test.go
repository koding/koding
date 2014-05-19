package sendgrid

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/mail"
	"testing"
	"time"
)

func TestNewMail(t *testing.T) {
	m := NewMail()
	if m == nil {
		t.Errorf("NewMail() shouldn't return nil")
	}
}

func TestAddTo(t *testing.T) {
	m := NewMail()
	m.AddTo("Email Name<email@email.com>")
	switch {
	case len(m.To) != 1:
		t.Errorf("AddTo should append to SGMail.To")
	case len(m.ToName) != 1:
		t.Errorf("AddTo should append to SGMail.ToName on a valid email")
	case len(m.SMTPAPIHeader.To) != 1:
		t.Errorf("AddTo should also modify the SMTPAPIHeader.To")
	}
}

func TestAddToFail(t *testing.T) {
	m := NewMail()
	err := m.AddTo(".com")
	if err == nil {
		t.Errorf("AddTo should fail on invalid email addresses")
	}
}

func TestAddTos(t *testing.T) {
	m := NewMail()
	m.AddTos([]string{"Email Name <email+1@email.com>", "email+2@email.com"})
	switch {
	case len(m.To) != 2:
		t.Errorf("AddTos should append to SGMail.To")
	case len(m.ToName) != 1:
		t.Errorf("AddTos should append to SGMail.ToName if a valid email was supplied")
	}
}

func TestAddTosFail(t *testing.T) {
	m := NewMail()
	err := m.AddTos([]string{".co", "email+2@email.com"})
	if err == nil {
		t.Errorf("AddTos should fail in invalid email address")
	}
}

func TestAddRecipients(t *testing.T) {
	m := NewMail()
	emails, _ := mail.ParseAddressList("Joe <email+1@email.com>, Doe <email+2@email.com>")
	m.AddRecipients(emails)
	switch {
	case len(m.To) != 2:
		t.Errorf("AddRecipients should append to SGMail.To")
	case len(m.ToName) != 2:
		t.Errorf("AddRecipients should append to SGMail.ToName if a valid email is supplied")
	case len(m.SMTPAPIHeader.To) != 2:
		t.Errorf("AddRecipients should append to SMTPAPIHeader.To")
	}
}

func TestAddToName(t *testing.T) {
	m := NewMail()
	m.AddToName("Name")
	if len(m.ToName) != 1 {
		t.Errorf("AddToName should append to SG.ToName")
	}
}

func TestAddToNames(t *testing.T) {
	m := NewMail()
	m.AddToNames([]string{"Name", "Name2"})
	if len(m.ToName) != 2 {
		t.Errorf("AddToNames should append to SG.ToName")
	}
}

func TestSetSubject(t *testing.T) {
	m := NewMail()
	testSubject := "Subject"
	m.SetSubject(testSubject)
	if m.Subject != testSubject {
		t.Errorf("SetSubject should modify SGMail.Subject")
	}
}

func TestSetText(t *testing.T) {
	m := NewMail()
	testText := "Text"
	m.SetText(testText)
	if m.Text != testText {
		t.Errorf("SetText should modify SGMail.Text")
	}
}

func TestSetHTML(t *testing.T) {
	m := NewMail()
	testHTML := "<html></html>"
	m.SetHTML(testHTML)
	if m.HTML != testHTML {
		t.Errorf("SetHTML should modify SGMail.HTML")
	}
}

func TestSetFrom(t *testing.T) {
	m := NewMail()
	testFrom, _ := mail.ParseAddress("Joe <email@email.com>")
	m.SetFrom(testFrom.String())
	switch {
	case m.From != testFrom.Address:
		t.Errorf("SetFrom should modify SGMail.From")
	case m.FromName != testFrom.Name:
		t.Errorf("SetFromName should modify SGMail.FromName")
	}
}

func TestSetFromFail(t *testing.T) {
	m := NewMail()
	testFrom := ".com"
	err := m.SetFrom(testFrom)
	if err == nil {
		t.Errorf("SetFrom should fail if an invalid email address is provided")
	}
}

func TestAddBcc(t *testing.T) {
	m := NewMail()
	m.AddBcc("Email Name<email@email.com>")
	if len(m.Bcc) != 1 {
		t.Errorf("AddBcc should append to SGMail.Bcc")
	}
}

func TestAddBccFail(t *testing.T) {
	m := NewMail()
	err := m.AddBcc(".com")
	if err == nil {
		t.Errorf("AddBcc should fail on invalid email addresses")
	}
}

func TestAddBccs(t *testing.T) {
	m := NewMail()
	m.AddBccs([]string{"Email Name <email+1@email.com>", "email+2@email.com"})
	if len(m.Bcc) != 2 {
		t.Errorf("AddBccs should append to SGMail.Bcc")
	}
}

func TestAddBccsFail(t *testing.T) {
	m := NewMail()
	err := m.AddBccs([]string{".co", "email+2@email.com"})
	if err == nil {
		t.Errorf("AddBccs should fail in invalid email address")
	}
}

func TestAddBccRecipients(t *testing.T) {
	m := NewMail()
	emails, _ := mail.ParseAddressList("Joe <email+1@email.com>, Doe <email+2@email.com>")
	m.AddBccRecipients(emails)
	if len(m.Bcc) != 2 {
		t.Errorf("AddBccRecipients should append to SGMail.Bcc")
	}
}

func TestSetFromName(t *testing.T) {
	m := NewMail()
	testFromName := "Joe"
	m.SetFromName(testFromName)
	if m.FromName != testFromName {
		t.Errorf("SetFromName should modify SGMail.FromName")
	}
}

func TestSetReplyTo(t *testing.T) {
	m := NewMail()
	testReplyTo := "email@email.com"
	m.SetReplyTo(testReplyTo)
	if m.ReplyTo != testReplyTo {
		t.Errorf("SetReplyTo should modify SGMail.ReplyTo")
	}
}

func TestSetReplyToFail(t *testing.T) {
	m := NewMail()
	testReplyTo := ".com"
	err := m.SetReplyTo(testReplyTo)
	if err == nil {
		t.Errorf("SetReplyTo should fail with an invalid address")
	}
}

func TestSetDate(t *testing.T) {
	m := NewMail()
	date := "Today"
	m.SetDate(date)
	if m.Date != date {
		t.Errorf("SetDate should modify SGMail.Date")
	}
}

func TestSetRFCDate(t *testing.T) {
	m := NewMail()
	date := time.Now()
	m.SetRFCDate(date)
	if m.Date == "" {
		t.Errorf("SetDate should fail if date is invalid RFC822")
	}
}

func TestAddAttachment(t *testing.T) {
	m := NewMail()
	fakeServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "THIS IS A TEST!")
	}))
	defer fakeServer.Close()
	res, err := http.Get(fakeServer.URL)
	if err != nil {
		t.Errorf("Fake server could'nt be reached")
	}
	defer res.Body.Close()
	err = m.AddAttachment("Test", res.Body)
	if _, ok := m.Files["Test"]; !ok {
		t.Errorf("Attachment not added")
	}
}

func TestAddAttachmentFail(t *testing.T) {
	m := NewMail()
	fakeServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "THIS IS A TEST!")
	}))
	defer fakeServer.Close()
	res, err := http.Get(fakeServer.URL)
	res.Body.Close()
	if err != nil {
		t.Errorf("Fake server could'nt be reached")
	}

	err = m.AddAttachment("Test", res.Body)
	if _, ok := m.Files["Test"]; ok {
		t.Errorf("Attachment should not be added")
	}
}

func TestAddContentIds(t *testing.T) {
	m := NewMail()
	id, value := "id", "im a value"
	m.AddContentID(id, value)
	if val, ok := m.Content[id]; !ok && val != value {
		t.Errorf("ContentID failed to be added")
	}
}

func TestAddHeaders(t *testing.T) {
	m := NewMail()
	header, value := "id", "im a value"
	m.AddHeader(header, value)
	if val, ok := m.Headers[header]; !ok && val != value {
		t.Errorf("Header failed to be added")
	}
}

func TestHeaderString(t *testing.T) {
	m := NewMail()
	m.AddHeader("Cc", "hello@test.com")
	if _, err := m.HeadersString(); err != nil {
		t.Errorf("Error parsing headers: %v", err)
	}
}
