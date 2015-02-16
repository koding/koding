package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  Parse,
			Name:     "mail-parse",
			Type:     handler.PostRequest,
			Endpoint: "/mail/parse",
		},
	)
}

// type Message struct {
// 	Name string
// 	Body string
// 	Time int64
// }

type MailParser struct {
	FromName    string
	From        string
	MailboxHash string
	TextBody    string
}

// func main() {

// 	data := `{
//   "FromName": "Cihangir Savas",
//   "From": "cihangir@koding.com",
//   "FromFull": {
//     "Email": "cihangir@koding.com",
//     "Name": "Cihangir Savas",
//     "MailboxHash": ""
//   },
//   "To": "cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com",
//   "ToFull": [
//     {
//       "Email": "cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com",
//       "Name": "",
//       "MailboxHash": "c753ccab0f110add98f4edee21431ca7"
//     }
//   ],
//   "Cc": "",
//   "CcFull": [],
//   "Bcc": "",
//   "BccFull": [],
//   "Subject": "Re: cihangir+c753ccab0f110add98f4edee21431ca7 test",
//   "MessageID": "941469ab-694d-43bd-931d-15ad0da2d052",
//   "ReplyTo": "",
//   "MailboxHash": "c753ccab0f110add98f4edee21431ca7",
//   "Date": "Sun, 7 Sep 2014 01:42:17 -0700",
//   "TextBody": "testing mail parse.....\r\n",
//   "HtmlBody": "<div dir=\"ltr\"><font color=\"#333333\" face=\"Helvetica Neue, Arial, Helvetica, sans-serif\"><span style=\"font-size:14px;line-height:19.6000003814697px\">testing mail parse.....<\/span><\/font><\/div>\r\n",
//   "StrippedTextReply": "",
//   "Tag": "",
//   "Headers": [
//     {
//       "Name": "X-Spam-Checker-Version",
//       "Value": "SpamAssassin 3.3.1 (2010-03-16) on sc-ord-inbound1"
//     },
//     {
//       "Name": "X-Spam-Status",
//       "Value": "No"
//     },
//     {
//       "Name": "X-Spam-Score",
//       "Value": "-0.7"
//     },
//     {
//       "Name": "X-Spam-Tests",
//       "Value": "HTML_MESSAGE,RCVD_IN_DNSWL_LOW,SPF_PASS"
//     },
//     {
//       "Name": "Received-SPF",
//       "Value": "Pass (sender SPF authorized) identity=mailfrom; client-ip=209.85.216.52; helo=mail-qa0-f52.google.com; envelope-from=cihangir@koding.com; receiver=cihangir+c753ccab0f110add98f4edee21431ca7@inbound.koding.com"
//     },
//     {
//       "Name": "X-Google-DKIM-Signature",
//       "Value": "v=1; a=rsa-sha256; c=relaxed\/relaxed;        d=1e100.net; s=20130820;        h=x-gm-message-state:mime-version:date:message-id:subject:from:to         :content-type;        bh=8Je8F3I+Al30FHRlQlzrFs5oZQvPIQ2UrA0rIk5+Zm4=;        b=DkqIXBatAZTCALrw\/1bh6VWKhnsHoEXS6MzwbE\/KoOkmrVB5gOAQI\/39TUBZUJRRNX         l4uOo0kH9KxI2FEWwP\/n4ViOvxn2sY\/0ZWGPFRM4jhOm7OvFspA3VvZL8wpddxquwk+Z         RosWQ\/ixUb7BrpgoTR3DTnwt7PirYhbvA\/KOSSFSeIuVNjvo0RcSX0BJ8o+kXvyIq2Xd         5MF+jkQwwmhalfxAEiO1jSiLYp4moHznDCfPFxmceT7oSrJ+OuQL96\/UW3ljKK2n4hk8         aQpwBdO2PtUPh17Q6X4D2MgYY1y4\/6+EBuFxLgab65CEE5+Vo6vt7JIxcwZpZROAlFWG         qNZA=="
//     },
//     {
//       "Name": "X-Gm-Message-State",
//       "Value": "ALoCoQl6UC1K8o2LeFAsjSPHhRQA0uQkDQfK6Y0fFFQsJ8eXc0fszOxIwN7qmv0L3tIq5kX2vF54"
//     },
//     {
//       "Name": "MIME-Version",
//       "Value": "1.0"
//     },
//     {
//       "Name": "X-Received",
//       "Value": "by 10.140.92.97 with SMTP id a88mr12550710qge.85.1410079337953; Sun, 07 Sep 2014 01:42:17 -0700 (PDT)"
//     },
//     {
//       "Name": "X-Originating-IP",
//       "Value": "[2604:5500:1c:1fa:6d5e:b6c9:3ec9:4c5d]"
//     },
//     {
//       "Name": "Message-ID",
//       "Value": "<CAORUdqjqgvvHOxtk_isqQ49aToxMzOPUJ40Ga9o2Z7M0En=xEw@mail.gmail.com>"
//     }
//   ],
//   "Attachments": []
// }`

// 	m := &MailParser{}

// 	err := json.Unmarshal([]byte(data), m)

// 	if err != nil {
// 		panic(err)
// 	}

// 	fmt.Println(m.FromName)

// }
