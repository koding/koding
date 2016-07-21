package main
// This is an example of the Mail helper, located here: /helpers/mail

import (
	"fmt"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
	//"../../.." // to test against the downloaded version
	//"../../../../sendgrid-go/helpers/mail" // to test against the downloaded version
	"os"
)

// Minimum required to send an email
func helloEmail() []byte {

	address := "test@example.com"
	name := "Example User"
	from := mail.NewEmail(name, address)
	subject := "Hello World from the SendGrid Go Library"
	address = "test@example.com"
	name = "Example User"
	to := mail.NewEmail(name, address)
	content := mail.NewContent("text/plain", "some text here")
	m := mail.NewV3MailInit(from, subject, to, content)
	address = "test2@example.com"
	name = "Example User"
	email := mail.NewEmail(name, address)
	m.Personalizations[0].AddTos(email)
	return mail.GetRequestBody(m)
}

// Fully populated Mail object
func kitchenSink() []byte {
	m := mail.NewV3Mail()
	address := "test@example.com"
	name := "Example User"
	e := mail.NewEmail(name, address)
	m.SetFrom(e)

	m.Subject = "Hello World from the SendGrid Go Library"

	p := mail.NewPersonalization()
	tos := []*mail.Email{
		mail.NewEmail("Example User", "test1@example.com"),
		mail.NewEmail("Example User", "test2@example.com"),
	}
	p.AddTos(tos...)
	ccs := []*mail.Email{
		mail.NewEmail("Example User", "test3@example.com"),
		mail.NewEmail("Example User", "test4@example.com"),
	}
	p.AddCCs(ccs...)
	bccs := []*mail.Email{
		mail.NewEmail("Example User", "test5@example.com"),
		mail.NewEmail("Example User", "test6@example.com"),
	}
	p.AddBCCs(bccs...)
	p.Subject = "Hello World from the Personalized SendGrid Go Library"
	p.SetHeader("X-Test", "test")
	p.SetHeader("X-Mock", "true")
	p.SetSubstitution("%name%", "Example User")
	p.SetSubstitution("%city%", "Denver")
	p.SetCustomArg("user_id", "343")
	p.SetCustomArg("type", "marketing")
	p.SetSendAt(1461356286)
	m.AddPersonalizations(p)

	p2 := mail.NewPersonalization()
	tos2 := []*mail.Email{
		mail.NewEmail("Example User", "test1@example.com"),
		mail.NewEmail("Example User", "test2@example.com"),
	}
	p2.AddTos(tos2...)
	ccs2 := []*mail.Email{
		mail.NewEmail("Example User", "test3@example.com"),
		mail.NewEmail("Example User", "test4@example.com"),
	}
	p2.AddCCs(ccs2...)
	bccs = []*mail.Email{
		mail.NewEmail("Example User", "test5@example.com"),
		mail.NewEmail("Example User", "test6@example.com"),
	}
	p2.AddBCCs(bccs...)
	p2.Subject = "Hello World from the Personalized SendGrid Go Library"
	p2.SetHeader("X-Test", "test")
	p2.SetHeader("X-Mock", "true")
	p2.SetSubstitution("%name%", "Example User")
	p2.SetSubstitution("%city%", "Denver")
	p2.SetCustomArg("user_id", "343")
	p2.SetCustomArg("type", "marketing")
	p2.SetSendAt(1461356286)
	m.AddPersonalizations(p2)

	c := mail.NewContent("text/plain", "some text here")
	m.AddContent(c)

	c = mail.NewContent("text/html", "some html here")
	m.AddContent(c)

	a := mail.NewAttachment()
	a.SetContent("TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4gQ3JhcyBwdW12")
	a.SetType("application/pdf")
	a.SetFilename("balance_001.pdf")
	a.SetDisposition("attachment")
	a.SetContentID("Balance Sheet")
	m.AddAttachment(a)

	a2 := mail.NewAttachment()
	a2.SetContent("BwdW")
	a2.SetType("image/png")
	a2.SetFilename("banner.png")
	a2.SetDisposition("inline")
	a2.SetContentID("Banner")
	m.AddAttachment(a2)

	m.SetTemplateID("13b8f94f-bcae-4ec6-b752-70d6cb59f932")

	m.AddSection("%section1%", "Substitution Text for Section 1")
	m.AddSection("%section2%", "Substitution Text for Section 2")

	m.SetHeader("X-Test1", "1")
	m.SetHeader("X-Test2", "2")

	m.AddCategories("May")
	m.AddCategories("2016")

	m.SetCustomArg("campaign", "welcome")
	m.SetCustomArg("weekday", "morning")

	m.SetSendAt(1461356286)

	asm := mail.NewASM()
	asm.SetGroupID(99)
	asm.AddGroupsToDisplay(99)
	m.SetASM(asm)

  // This must be a valid [batch ID](https://sendgrid.com/docs/API_Reference/SMTP_API/scheduling_parameters.html) to work
	// m.SetBatchID("sendgrid_batch_id")

	m.SetIPPoolID("23")

	mailSettings := mail.NewMailSettings()
	bccSettings := mail.NewBCCSetting()
	bccSettings.SetEnable(true)
	bccSettings.SetEmail("test@example.com")
	mailSettings.SetBCC(bccSettings)
	sandBoxMode := mail.NewSetting(true)
	mailSettings.SetSandboxMode(sandBoxMode)
	bypassListManagement := mail.NewSetting(true)
	mailSettings.SetBypassListManagement(bypassListManagement)
	footerSetting := mail.NewFooterSetting()
	footerSetting.SetText("Footer Text")
	footerSetting.SetEnable(true)
	footerSetting.SetHTML("<html><body>Footer Text</body></html>")
	mailSettings.SetFooter(footerSetting)
	spamCheckSetting := mail.NewSpamCheckSetting()
	spamCheckSetting.SetEnable(true)
	spamCheckSetting.SetSpamThreshold(1)
	spamCheckSetting.SetPostToURL("https://spamcatcher.sendgrid.com")
	mailSettings.SetSpamCheckSettings(spamCheckSetting)
	m.SetMailSettings(mailSettings)

	trackingSettings := mail.NewTrackingSettings()
	clickTrackingSettings := mail.NewClickTrackingSetting()
	clickTrackingSettings.SetEnable(true)
	clickTrackingSettings.SetEnableText(true)
	trackingSettings.SetClickTracking(clickTrackingSettings)
	openTrackingSetting := mail.NewOpenTrackingSetting()
	openTrackingSetting.SetEnable(true)
	openTrackingSetting.SetSubstitutionTag("Optional tag to replace with the open image in the body of the message")
	trackingSettings.SetOpenTracking(openTrackingSetting)
	subscriptionTrackingSetting := mail.NewSubscriptionTrackingSetting()
	subscriptionTrackingSetting.SetEnable(true)
	subscriptionTrackingSetting.SetText("text to insert into the text/plain portion of the message")
	subscriptionTrackingSetting.SetHTML("<html><body>html to insert into the text/html portion of the message</body></html>")
	subscriptionTrackingSetting.SetSubstitutionTag("Optional tag to replace with the open image in the body of the message")
	trackingSettings.SetSubscriptionTracking(subscriptionTrackingSetting)
	googleAnalyticsSetting := mail.NewGaSetting()
	googleAnalyticsSetting.SetEnable(true)
	googleAnalyticsSetting.SetCampaignSource("some source")
	googleAnalyticsSetting.SetCampaignTerm("some term")
	googleAnalyticsSetting.SetCampaignContent("some content")
	googleAnalyticsSetting.SetCampaignName("some name")
	googleAnalyticsSetting.SetCampaignMedium("some medium")
	trackingSettings.SetGoogleAnalytics(googleAnalyticsSetting)
	m.SetTrackingSettings(trackingSettings)

	replyToEmail := mail.NewEmail("Example User", "test@example.com")
	m.SetReplyTo(replyToEmail)

	return mail.GetRequestBody(m)
}

func sendHelloEmail() {
	request := sendgrid.GetRequest(os.Getenv("YOUR_SENDGRID_API_KEY"), "/v3/mail/send", "https://api.sendgrid.com")
	request.Method = "POST"
	var Body = helloEmail()
	request.Body = Body
	response, err := sendgrid.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}
}

func sendKitchenSink() {
	request := sendgrid.GetRequest(os.Getenv("YOUR_SENDGRID_API_KEY"), "/v3/mail/send", "https://api.sendgrid.com")
	request.Method = "POST"
	var Body = kitchenSink()
	request.Body = Body
	response, err := sendgrid.API(request)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println(response.StatusCode)
		fmt.Println(response.Body)
		fmt.Println(response.Headers)
	}
}

func main() {
	sendHelloEmail()
	sendKitchenSink()
}
