package mail

import (
	"math/rand"
	"testing"
	"time"
)

func TestV3NewMail(t *testing.T) {
	m := NewV3Mail()

	if m == nil {
		t.Errorf("NewV3Mail() shouldn't return nil")
	}

	if m.Personalizations == nil {
		t.Errorf("Personalizations shouldn't be nil")
	}

	if m.Attachments == nil {
		t.Errorf("Attachments shouldn't be nil")
	}

	if m.Content == nil {
		t.Errorf("Content shouldn't be nil")
	}
}

func TestV3AddPersonalizations(t *testing.T) {
	numOfPersonalizations := rand.New(rand.NewSource(99)).Intn(10)
	personalizations := make([]*Personalization, 0)
	for i := 0; i < numOfPersonalizations; i++ {
		personalizations = append(personalizations, NewPersonalization())
	}

	m := NewV3Mail()
	m.AddPersonalizations(personalizations...)

	if len(m.Personalizations) != numOfPersonalizations {
		t.Errorf("Mail should have %d personalizations, got %d personalizations", personalizations, len(m.Personalizations))
	}
}

func TestV3AddContent(t *testing.T) {
	numOfContent := 2
	content := make([]*Content, 0)
	for i := 0; i < numOfContent; i++ {
		content = append(content, NewContent("type", "value"))
	}

	m := NewV3Mail()
	m.AddContent(content...)

	if len(m.Content) != numOfContent {
		t.Errorf("Mail should have %d contents, got %d contents", content, len(m.Content))
	}
}

func TestV3AddAttachment(t *testing.T) {
	numOfAttachments := 2
	attachment := make([]*Attachment, 0)
	for i := 0; i < numOfAttachments; i++ {
		attachment = append(attachment, NewAttachment())
	}

	m := NewV3Mail()
	m.AddAttachment(attachment...)

	if len(m.Attachments) != numOfAttachments {
		t.Errorf("Mail should have %d attachments, got %d attachments", attachment, 2)
	}
}

func TestV3SetFrom(t *testing.T) {
	m := NewV3Mail()

	address := "test@example.com"
	name := "Test User"
	e := NewEmail(name, address)
	m.SetFrom(e)

	if m.From.Name != name {
		t.Errorf("name should be %s, got %s", name, e.Name)
	}

	if m.From.Address != address {
		t.Errorf("address should be %s, got %s", address, e.Address)
	}
}

func TestV3SetReplyTo(t *testing.T) {
	m := NewV3Mail()

	address := "test@example.com"
	name := "Test User"
	e := NewEmail(name, address)
	m.SetReplyTo(e)

	if m.ReplyTo.Name != name {
		t.Errorf("name should be %s, got %s", name, e.Name)
	}

	if m.ReplyTo.Address != address {
		t.Errorf("address should be %s, got %s", address, e.Address)
	}
}

func TestV3SetTemplateID(t *testing.T) {
	m := NewV3Mail()

	templateID := "templateabcd12345"

	m.SetTemplateID(templateID)

	if m.TemplateID != templateID {
		t.Errorf("templateID should be %s, got %s", templateID, m.TemplateID)
	}
}

func TestV3AddSection(t *testing.T) {
	m := NewV3Mail()

	sectionKey := "key"
	sectionValue := "value"

	m.AddSection(sectionKey, sectionValue)

	if v, ok := m.Sections[sectionKey]; !ok {
		t.Errorf("key %s not found in Sections map", sectionKey)
	} else if v != sectionValue {
		t.Errorf("value should be %s, got %s", sectionValue, v)
	}
}

func TestV3SetHeader(t *testing.T) {
	m := NewV3Mail()

	headerKey := "key"
	headerValue := "value"

	m.SetHeader(headerKey, headerValue)

	if v, ok := m.Headers[headerKey]; !ok {
		t.Errorf("key %s not found in Headers map", headerKey)
	} else if v != headerValue {
		t.Errorf("value should be %s, got %s", headerValue, v)
	}
}

func TestV3AddCategory(t *testing.T) {
	m := NewV3Mail()

	categories := []string{"cats", "dogs", "hamburgers", "cheezeburgers"}

	m.AddCategories(categories...)

	if len(m.Categories) != len(categories) {
		t.Errorf("Length of Categories should be %d, got %d", len(categories), len(m.Categories))
	}
}

func TestV3SetCustomArg(t *testing.T) {
	m := NewV3Mail()

	customArgKey := "key"
	customArgValue := "value"

	m.SetCustomArg(customArgKey, customArgValue)

	if v, ok := m.CustomArgs[customArgKey]; !ok {
		t.Errorf("key %s not found in Headers map", customArgKey)
	} else if v != customArgValue {
		t.Errorf("value should be %s, got %s", customArgValue, v)
	}
}

func TestV3SetSendAt(t *testing.T) {
	m := NewV3Mail()
	sendAt := time.Now().Second()

	m.SetSendAt(sendAt)
	if m.SendAt != sendAt {
		t.Errorf("sendat should be %d, got %d", sendAt, m.SendAt)
	}
}

func TestV3SetBatchID(t *testing.T) {
	m := NewV3Mail()
	batchID := "batchID123455"

	m.SetBatchID(batchID)
	if m.BatchID != batchID {
		t.Errorf("BatchID should be %s, got %s", batchID, m.BatchID)
	}
}

func TestV3SetIPPoolID(t *testing.T) {
	m := NewV3Mail()
	ipPoolID := "42"

	m.SetIPPoolID(ipPoolID)
	if m.IPPoolID != ipPoolID {
		t.Errorf("IP Pool ID should be %d, got %d", ipPoolID, m.IPPoolID)
	}
}

func TestV3SetASM(t *testing.T) {
	m := NewV3Mail()
	asm := NewASM()
	groupID := 1
	groupsToDisplay := []int{1, 2, 3, 4}
	asm.SetGroupID(groupID)
	asm.AddGroupsToDisplay(groupsToDisplay...)

	m.SetASM(asm)

	if m.Asm.GroupID != groupID {
		t.Errorf("GroupID should be %d, got %d", groupID, m.Asm.GroupID)
	}

	if len(m.Asm.GroupsToDisplay) != len(groupsToDisplay) {
		t.Errorf("Length of GroupsToDisplay should be %d, got %d", len(groupsToDisplay), len(m.Asm.GroupsToDisplay))
	}
}

func TestV3SetMailSettings(t *testing.T) {
	m := NewV3Mail()
	ms := NewMailSettings()
	ms.SetBCC(NewBCCSetting().SetEnable(true))
	m.SetMailSettings(ms)

	if m.MailSettings == nil {
		t.Errorf("Mail Settings should not be nil")
	}

	if !*m.MailSettings.BCC.Enable {
		t.Errorf("BCC should be anabled in Mail Settings")
	}
}

func TestV3SetTrackingSettings(t *testing.T) {
	m := NewV3Mail()
	ts := NewTrackingSettings()
	n := NewClickTrackingSetting()
	n.SetEnable(true)
	n.SetEnableText(true)
	ts.SetClickTracking(n)
	m.SetTrackingSettings(ts)

	if m.TrackingSettings == nil {
		t.Errorf("Tracking Settings should not be nil")
	}

	if !*m.TrackingSettings.ClickTracking.Enable {
		t.Errorf("Click Tracking should be enabled")
	}
}

func TestV3NewPersonalization(t *testing.T) {
	p := NewPersonalization()

	if p == nil {
		t.Errorf("NewPersonalization() shouldn't return nil")
	}

	if p.To == nil {
		t.Errorf("To shouldn't be nil")
	}
	if len(p.To) != 0 {
		t.Errorf("length of To should should be 0")
	}

	if p.CC == nil {
		t.Errorf("CC shouldn't be nil")
	}
	if len(p.CC) != 0 {
		t.Errorf("length of CC should be 0")
	}

	if p.BCC == nil {
		t.Errorf("BCC shouldn't be nil")
	}
	if len(p.BCC) != 0 {
		t.Errorf("length of BCC should be 0")
	}

	if p.Headers == nil {
		t.Errorf("Headers shouldn't be nil")
	}
	if len(p.Headers) != 0 {
		t.Errorf("length of Headers should be 0")
	}

	if p.Substitutions == nil {
		t.Errorf("Substitutions shouldn't be nil")
	}
	if len(p.Substitutions) != 0 {
		t.Errorf("length of Substitutions should be 0")
	}

	if p.CustomArgs == nil {
		t.Errorf("CustomArgs shouldn't be nil")
	}
	if len(p.CustomArgs) != 0 {
		t.Errorf("length of CustomArgs should be 0")
	}

	if p.Categories == nil {
		t.Errorf("Categories shouldn't be nil")
	}
	if len(p.Categories) != 0 {
		t.Errorf("length of Categories should be 0")
	}
}

func TestV3PersonalizationAddTos(t *testing.T) {
	tos := []*Email{
		NewEmail("Example User", "test@example.com"),
		NewEmail("Example User", "test@example.com"),
	}

	p := NewPersonalization()
	p.AddTos(tos...)

	if len(p.To) != len(tos) {
		t.Errorf("length of To should be %d, got %d", len(tos), len(p.To))
	}
}

func TestV3PersonalizationAddCCs(t *testing.T) {
	ccs := []*Email{
		NewEmail("Example User", "test@example.com"),
		NewEmail("Example User", "test@example.com"),
	}

	p := NewPersonalization()
	p.AddCCs(ccs...)

	if len(p.CC) != len(ccs) {
		t.Errorf("length of CC should be %d, got %d", len(ccs), len(p.CC))
	}

}

func TestV3PersonalizationAddBCCs(t *testing.T) {
	bccs := []*Email{
		NewEmail("Example User", "test@example.com"),
		NewEmail("Example User", "test@example.com"),
	}

	p := NewPersonalization()
	p.AddBCCs(bccs...)

	if len(p.BCC) != len(bccs) {
		t.Errorf("length of BCC should be %d, got %d", len(bccs), len(p.BCC))
	}

}

func TestV3PersonalizationSetHeader(t *testing.T) {
	p := NewPersonalization()

	headerKey := "key"
	headerValue := "value"

	p.SetHeader(headerKey, headerValue)

	if v, ok := p.Headers[headerKey]; !ok {
		t.Errorf("key %s not found in Headers map", headerKey)
	} else if v != headerValue {
		t.Errorf("value should be %s, got %s", headerValue, v)
	}
}

func TestV3PersonalizationSetSubstitution(t *testing.T) {
	p := NewPersonalization()

	substitutionKey := "key"
	substitutionValue := "value"

	p.SetSubstitution(substitutionKey, substitutionValue)

	if v, ok := p.Substitutions[substitutionKey]; !ok {
		t.Errorf("key %s not found in Substitutions map", substitutionKey)
	} else if v != substitutionValue {
		t.Errorf("value should be %s, got %s", substitutionValue, v)
	}
}

func TestV3PersonalizationSetCustomArg(t *testing.T) {
	p := NewPersonalization()

	customArgKey := "key"
	customArgValue := "value"

	p.SetCustomArg(customArgKey, customArgValue)

	if v, ok := p.CustomArgs[customArgKey]; !ok {
		t.Errorf("key %s not found in CustomArgs map", customArgKey)
	} else if v != customArgValue {
		t.Errorf("value should be %s, got %s", customArgValue, v)
	}
}

func TestV3PersonalizationSetSendAt(t *testing.T) {
	p := NewPersonalization()
	sendAt := time.Now().Second()

	p.SetSendAt(sendAt)
	if p.SendAt != sendAt {
		t.Errorf("sendat should be %d, got %d", sendAt, p.SendAt)
	}
}

func TestV3NewAttachment(t *testing.T) {
	a := NewAttachment()

	if a == nil {
		t.Errorf("NewAttachment() shouldn't return nil")
	}

}

func TestV3AttachmentSetContent(t *testing.T) {
	content := "somebase64encodedcontent"
	a := NewAttachment().SetContent(content)

	if a.Content != content {
		t.Errorf("Content should be %s, got %s", content, a.Content)
	}

}

func TestV3AttachmentSetType(t *testing.T) {
	contentType := "pdf"
	a := NewAttachment().SetType(contentType)

	if a.Type != contentType {
		t.Errorf("Type should be %s, got %s", contentType, a.Type)
	}
}

func TestV3AttachmentSetContentID(t *testing.T) {
	contentID := "contentID"
	a := NewAttachment().SetContentID(contentID)

	if a.ContentID != contentID {
		t.Errorf("ContentID should be %s, got %s", contentID, a.ContentID)
	}
}

func TestV3AttachmentSetDispotition(t *testing.T) {
	disposition := "inline"
	a := NewAttachment().SetDisposition(disposition)

	if a.Disposition != disposition {
		t.Errorf("Disposition should be %s, got %s", disposition, a.Disposition)
	}
}

func TestV3AttachmentSetFilename(t *testing.T) {
	filename := "mydoc.pdf"
	a := NewAttachment().SetFilename(filename)

	if a.Filename != filename {
		t.Errorf("Filename should be %s, got %s", filename, a.Filename)
	}
}

func TestV3NewASM(t *testing.T) {
	a := NewASM()

	if a == nil {
		t.Errorf("NewASM() should not return nil")
	}
}

func TestV3ASMSetGroupID(t *testing.T) {
	groupID := 1
	a := NewASM().SetGroupID(groupID)

	if a.GroupID != groupID {
		t.Errorf("GroupID should be %d, got %d", groupID, a.GroupID)
	}
}

func TestV3ASMSetGroupstoDisplay(t *testing.T) {
	groupsToDisplay := []int{1, 2, 3, 4}
	a := NewASM().AddGroupsToDisplay(groupsToDisplay...)

	if len(a.GroupsToDisplay) != len(groupsToDisplay) {
		t.Errorf("Length of GroupsToDisplay should be %d, got %d", groupsToDisplay, a.GroupsToDisplay)
	}
}

func TestV3NewMailSettings(t *testing.T) {
	m := NewMailSettings()

	if m == nil {
		t.Errorf("NewMailSettings() shouldn't return nil")
	}
}

func TestV3MailSettingsSetBCC(t *testing.T) {
	m := NewMailSettings().SetBCC(NewBCCSetting().SetEnable(true))

	if m.BCC == nil {
		t.Errorf("BCC should not be nil")
	}

	if !*m.BCC.Enable {
		t.Errorf("BCC should be enabled")
	}
}

func TestV3MailSettingsSetBypassListManagement(t *testing.T) {
	m := NewMailSettings().SetBypassListManagement(NewSetting(true))
	if m.BypassListManagement == nil {
		t.Errorf("BypassListManagement should not be nil")
	}

	if !*m.BypassListManagement.Enable {
		t.Errorf("BypassListManagement should be enabled")
	}
}

func TestV3MailSettingsSetSandboxMode(t *testing.T) {
	m := NewMailSettings().SetSandboxMode(NewSetting(true))
	if m.SandboxMode == nil {
		t.Errorf("SandboxMode should not be nil")
	}

	if !*m.SandboxMode.Enable {
		t.Errorf("SandboxMode should be enabled")
	}
}

func TestV3MailSettingsSpamCheckSettings(t *testing.T) {

	m := NewMailSettings()
	s := NewSpamCheckSetting()
	s.SetEnable(true)
	s.SetPostToURL("http://test.com")
	s.SetSpamThreshold(1)
	m.SetSpamCheckSettings(s)

	if !*m.SpamCheckSetting.Enable {
		t.Errorf("SpamCheckSettings should be enabled")
	}

	if m.SpamCheckSetting.PostToURL == "" {
		t.Errorf("Post to URL should not empty")
	}

	if m.SpamCheckSetting.SpamThreshold != 1 {
		t.Errorf("Spam threshold should be 1")
	}
}

func TestV3MailSettingsSetFooter(t *testing.T) {
	m := NewMailSettings().SetFooter(NewFooterSetting().SetEnable(true))
	if m.Footer == nil {
		t.Errorf("Footer should not be nil")
	}

	if !*m.Footer.Enable {
		t.Errorf("Footer should be enabled")
	}
}

func TestV3NewTrackingSettings(t *testing.T) {
	ts := NewTrackingSettings()

	if ts == nil {
		t.Errorf("NewTrackingSettings() shouldn't return nil")
	}
}

func TestV3TrackingSettingsSetClickTracking(t *testing.T) {
	n := NewClickTrackingSetting()
	n.SetEnable(true)
	n.SetEnableText(true)
	ts := NewTrackingSettings().SetClickTracking(n)

	if ts.ClickTracking == nil {
		t.Errorf("Click Tracking should not be nil")
	}

	if !*ts.ClickTracking.Enable {
		t.Errorf("Click Tracking should be enabled")
	}
}

func TestV3TrackingSettingsSetOpenTracking(t *testing.T) {
	substitutionTag := "subTag"
	ts := NewTrackingSettings().SetOpenTracking(NewOpenTrackingSetting().SetEnable(true).SetSubstitutionTag(substitutionTag))

	if ts.OpenTracking == nil {
		t.Errorf("Open Tracking should not be nil")
	}

	if !*ts.OpenTracking.Enable {
		t.Errorf("Open Tracking should be enabled")
	}

	if ts.OpenTracking.SubstitutionTag != substitutionTag {
		t.Errorf("Substitution Tag should be %s, got %s", substitutionTag, ts.OpenTracking.SubstitutionTag)
	}
}

func TestV3TrackingSettingsSetSubscriptionTracking(t *testing.T) {
	ts := NewTrackingSettings().SetSubscriptionTracking(NewSubscriptionTrackingSetting())

	if ts.SubscriptionTracking == nil {
		t.Errorf("SubscriptionTracking should not be nil")
	}
}

func TestV3TrackingSettingsSetGoogleAnalytics(t *testing.T) {
	campaignName := "campaign1"
	campaignTerm := "campaign1_term"
	campaignSource := "campaign1_source"
	campaignContent := "campaign1_content"
	campaignMedium := "campaign1_medium"

	ts := NewTrackingSettings().SetGoogleAnalytics(NewGaSetting().SetCampaignName(campaignName).SetCampaignTerm(campaignTerm).SetCampaignSource(campaignSource).SetCampaignContent(campaignContent).SetCampaignMedium(campaignMedium).SetEnable(true))

	if ts.GoogleAnalytics == nil {
		t.Errorf("GoogleAnalytics should not be nil")
	}

	if ts.GoogleAnalytics.CampaignName != campaignName {
		t.Errorf("CampaignName should be %s, got %s", campaignName, ts.GoogleAnalytics.CampaignName)
	}

	if ts.GoogleAnalytics.CampaignTerm != campaignTerm {
		t.Errorf("CampaignTerm should be %s, got %s", campaignTerm, ts.GoogleAnalytics.CampaignTerm)
	}

	if ts.GoogleAnalytics.CampaignSource != campaignSource {
		t.Errorf("CampaignSource should be %s, got %s", campaignSource, ts.GoogleAnalytics.CampaignSource)
	}

	if ts.GoogleAnalytics.CampaignContent != campaignContent {
		t.Errorf("CampaignContent should be %s, got %s", campaignContent, ts.GoogleAnalytics.CampaignContent)
	}

	if ts.GoogleAnalytics.CampaignMedium != campaignMedium {
		t.Errorf("CampaignMedium should be %s, got %s", campaignMedium, ts.GoogleAnalytics.CampaignMedium)
	}

}

func TestV3NewBCCSetting(t *testing.T) {
	b := NewBCCSetting()

	if b == nil {
		t.Errorf("NewBCCSetting() shouldn't return nil")
	}
}

func TestV3BCCSettingSetEnable(t *testing.T) {
	b := NewBCCSetting().SetEnable(true)

	if !*b.Enable {
		t.Errorf("BCCSetting should be enabled")
	}
}

func TestV3BCCSettingSetEmail(t *testing.T) {

	address := "joe@schmoe.net"
	b := NewBCCSetting().SetEmail(address)

	if b.Email == "" {
		t.Errorf("Email should not be empty")
	}
}

func TestV3NewFooterSetting(t *testing.T) {
	f := NewFooterSetting()

	if f == nil {
		t.Errorf("NewFooterSetting() shouldn't return nil")
	}
}

func TestV3FooterSettingSetEnable(t *testing.T) {
	f := NewFooterSetting().SetEnable(true)

	if !*f.Enable {
		t.Errorf("FooterSetting should be enabled")
	}
}

func TestV3FooterSettingSetText(t *testing.T) {
	text := "some test here"
	f := NewFooterSetting().SetText(text)

	if f.Text != text {
		t.Errorf("Text should be %s, got %s", text, f.Text)
	}
}

func TestV3FooterSettingSetHtml(t *testing.T) {
	html := "<h1>some html</h1>"
	f := NewFooterSetting().SetHTML(html)

	if f.Html != html {
		t.Errorf("Html should be %s, got %s", html, f.Html)
	}
}

func TestV3NewOpenTrackingSetting(t *testing.T) {
	o := NewOpenTrackingSetting()

	if o == nil {
		t.Errorf("NewOpenTrackingSetting() shouldn't return nil")
	}
}

func TestV3OpenTrackingSettingSetEnable(t *testing.T) {
	f := NewOpenTrackingSetting().SetEnable(true)

	if !*f.Enable {
		t.Errorf("OpenTrackingSetting should be enabled")
	}

}

func TestV3OpenTrackingSettingSetSubstitutionTag(t *testing.T) {
	substitutionTag := "tag"
	f := NewOpenTrackingSetting().SetSubstitutionTag(substitutionTag)

	if f.SubstitutionTag != substitutionTag {
		t.Errorf("SubstitutionTag should be %s, got %s", substitutionTag, f.SubstitutionTag)
	}
}

func TestV3NewSubscriptionTrackingSetting(t *testing.T) {
	s := NewSubscriptionTrackingSetting()

	if s == nil {
		t.Errorf("NewSubscriptionTrackingSetting() shouldn't return nil")
	}
}

func TestV3NewSubscriptionTrackingSetEnable(t *testing.T) {
	s := NewSubscriptionTrackingSetting().SetEnable(true)

	if !*s.Enable {
		t.Errorf("SubscriptionTracking should be enabled")
	}
}

func TestV3NewSubscriptionTrackingSetSubstitutionTag(t *testing.T) {
	substitutionTag := "subTag"
	s := NewSubscriptionTrackingSetting().SetSubstitutionTag(substitutionTag)

	if s.SubstitutionTag != substitutionTag {
		t.Errorf("SubstitutionTag should be %s, got %s", substitutionTag, s.SubstitutionTag)
	}
}

func TestV3NewSubscriptionTrackingSetText(t *testing.T) {
	text := "text"

	s := NewSubscriptionTrackingSetting().SetText(text)
	if s.Text != text {
		t.Errorf("Text should be %s, got %s", text, s.Text)
	}
}

func TestV3NewSubscriptionTrackingSetHtml(t *testing.T) {
	html := "<h1>hello</h1>"

	s := NewSubscriptionTrackingSetting().SetHTML(html)

	if s.Html != html {
		t.Errorf("Html should be %s, got %s", html, s.Html)
	}
}

func TestV3NewGaSetting(t *testing.T) {
	g := NewGaSetting()

	if g == nil {
		t.Errorf("NewGaSetting() shouldn't return nil")
	}
}

func TestV3GaSettingSetCampaignName(t *testing.T) {
	campaignName := "campaign1"

	g := NewGaSetting().SetCampaignName(campaignName)

	if g.CampaignName != campaignName {
		t.Errorf("CampaignName should be %s, got %s", campaignName, g.CampaignName)
	}

}

func TestV3GaSettingSetCampaignTerm(t *testing.T) {
	campaignTerm := "campaign1_term"

	g := NewGaSetting().SetCampaignTerm(campaignTerm)
	if g.CampaignTerm != campaignTerm {
		t.Errorf("CampaignTerm should be %s, got %s", campaignTerm, g.CampaignTerm)
	}
}

func TestV3GaSettingSetCampaignSource(t *testing.T) {
	campaignSource := "campaign1_source"
	g := NewGaSetting().SetCampaignSource(campaignSource)

	if g.CampaignSource != campaignSource {
		t.Errorf("CampaignSource should be %s, got %s", campaignSource, g.CampaignSource)
	}
}

func TestV3GaSettingSetCampaignContent(t *testing.T) {
	campaignContent := "campaign1_content"

	g := NewGaSetting().SetCampaignContent(campaignContent)
	if g.CampaignContent != campaignContent {
		t.Errorf("CampaignContent should be %s, got %s", campaignContent, g.CampaignContent)
	}
}

func TestV3NewSetting(t *testing.T) {
	s := NewSetting(true)

	if s == nil {
		t.Errorf("NewSetting() shouldn't return nil")
	}

	if !*s.Enable {
		t.Errorf("NewSetting(true) should retun a setting with Enabled = true")
	}
}

func TestV3NewEmail(t *testing.T) {
	name := "Johnny"
	address := "Johnny@rocket.io"

	e := NewEmail(name, address)

	if e.Name != name {
		t.Errorf("Name should be %s, got %s", name, e.Name)
	}

	if e.Address != address {
		t.Errorf("Address should be %s, got %s", address, e.Address)
	}
}

func TestV3NewClickTrackingSetting(t *testing.T) {
	c := NewClickTrackingSetting()
	c.SetEnable(true)
	c.SetEnableText(false)

	if !*c.Enable {
		t.Error("Click Tracking should be enabled")
	}

	if *c.EnableText {
		t.Error("Enable Text should not be enabled")
	}
}

func TestV3NewSpamCheckSetting(t *testing.T) {
	spamThreshold := 8
	postToURL := "http://myurl.com"
	s := NewSpamCheckSetting()
	s.SetEnable(true)
	s.SetSpamThreshold(spamThreshold)
	s.SetPostToURL(postToURL)

	if !*s.Enable {
		t.Error("SpamCheck should be enabled")
	}

	if s.SpamThreshold != spamThreshold {
		t.Errorf("SpamThreshold should be %d, got %d", spamThreshold, s.SpamThreshold)
	}

	if s.PostToURL != postToURL {
		t.Errorf("PostToURL should be %s, got %s", postToURL, s.PostToURL)
	}
}

func TestV3NewSandboxModeSetting(t *testing.T) {
	spamCheck := NewSpamCheckSetting()
	spamCheck.SetEnable(true)
	spamCheck.SetSpamThreshold(1)
	spamCheck.SetPostToURL("http://wwww.google.com")
	s := NewSandboxModeSetting(true, true, spamCheck)

	if !*s.Enable {
		t.Error("Sandbox Mode should be enabled")
	}

	if !*s.ForwardSpam {
		t.Error("ForwardSpam should be enabled")
	}

	if s.SpamCheck == nil {
		t.Error("SpamCheck should not be nil")
	}
}
