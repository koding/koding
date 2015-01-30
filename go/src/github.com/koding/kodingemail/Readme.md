kodingemail
-----------

This library is a wrapper around sengrid's client meant to be used by koding workers.

Example:

    // initialize sengrid client with auth, sets default from
    // name and from address
    client := kodingemail.InitializeSG(<username>, <password>)

    // set substitution variables
    sub := map[string]string{"planId" : "Free"}

    err := client.SendTemplateEmail("to@koding.com", "template_id", sub)
    if err != nil {
      log.Fatal(err)
    }

Included is a mock implementation of SGClient which can be used in tests:

    // initialize test client
	  testSenderClient := &SenderTestClient{}

    client := kodingemail.InitializeSG(<username>, <password>)
	  client.Client = testSenderClient

    err := client.SendTemplateEmail("to@koding.com", "template_id", sub)
    if err != nil {
      log.Fatal(err)
    }

    // assert to field was set properly
    if testSenderClient.Mail.To[0] != toEmail {
      log.Fatal("To email wasn't set properly")
    }

