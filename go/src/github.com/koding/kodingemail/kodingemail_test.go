package kodingemail

import "testing"

func TestSendTemplateEmail(t *testing.T) {
	testSenderClient := &SenderTestClient{}

	sgclient := InitializeSG("", "")
	sgclient.SenderClient = testSenderClient

	toEmail := "indiana@koding.com"
	templateId := "random"

	err := sgclient.SendTemplateEmail(toEmail, templateId, nil)
	if err != nil {
		t.Fatal(err)
	}

	if len(testSenderClient.Mail.To) != 1 {
		t.Fatal("Expected 1 in to address")
	}

	if testSenderClient.Mail.To[0] != toEmail {
		t.Fatal("To email wasn't set properly")
	}

	templates, ok := testSenderClient.Mail.Filters["templates"]
	if !ok {
		t.Fatal("Templates not set")
	}

	enabled, ok := templates.Settings["enabled"]
	if !ok || enabled != "1" {
		t.Fatal("Templates not enabled")
	}

	tId, ok := templates.Settings["template_id"]
	if !ok || tId != templateId {
		t.Fatal("Template id not set")
	}
}
