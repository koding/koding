package ses_test

const SNSBounceNotification = `
    {
       "notificationType":"Bounce",
       "bounce":{
          "bounceType":"Permanent",
          "reportingMTA":"dns; email.example.com",
          "bouncedRecipients":[
             {
                "emailAddress":"username@example.com",
                "status":"5.1.1",
                "action":"failed",
                "diagnosticCode":"smtp; 550 5.1.1 <username@example.com>... User"
             }
          ],
          "bounceSubType":"General",
          "timestamp":"2012-06-19T01:07:52.000Z",
          "feedbackId":"00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa068a-000000"
       },
       "mail":{
          "timestamp":"2012-06-19T01:05:45.000Z",
          "source":"sender@example.com",
          "messageId":"00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000",
          "destination":[
             "username@example.com"
          ]
       }
    }
`

const SNSComplaintNotification = `
    {
      "notificationType":"Complaint",
      "complaint":{
         "userAgent":"Comcast Feedback Loop (V0.01)",
         "complainedRecipients":[
            {
               "emailAddress":"recipient1@example.com"
            }
         ],
         "complaintFeedbackType":"abuse",
         "arrivalDate":"2009-12-03T04:24:21.000-05:00",
         "timestamp":"2012-05-25T14:59:38.623-07:00",
         "feedbackId":"000001378603177f-18c07c78-fa81-4a58-9dd1-fedc3cb8f49a-000000"
      },
      "mail":{
         "timestamp":"2012-05-25T14:59:38.623-07:00",
         "messageId":"000001378603177f-7a5433e7-8edb-42ae-af10-f0181f34d6ee-000000",
         "source":"email_1337983178623@amazon.com",
         "destination":[
            "recipient1@example.com",
            "recipient2@example.com",
            "recipient3@example.com",
            "recipient4@example.com"
         ]
      }
   }
`

const SNSDeliveryNotification = `
   {
      "notificationType":"Delivery",
      "mail":{
         "timestamp":"2014-05-28T22:40:59.638Z",
         "messageId":"0000014644fe5ef6-9a483358-9170-4cb4-a269-f5dcdf415321-000000",
         "source":"test@ses-example.com",
         "destination":[
            "success@simulator.amazonses.com",
            "recipient@ses-example.com" 
         ]
      },
      "delivery":{
         "timestamp":"2014-05-28T22:41:01.184Z",
         "recipients":["success@simulator.amazonses.com"],
         "processingTimeMillis":546,     
         "reportingMTA":"a8-70.smtp-out.amazonses.com",
         "smtpResponse":"250 ok:  Message 64111812 accepted"
      } 
   }
`
