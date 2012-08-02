class Emailer
  @smtpTransport = nodemailer.createTransport "SMTP",
    service: "SES"
    auth:
      user: "AKIAJAC35KADH6ZUKSJA"
      pass: "AuuZXaIiI1XacyWULnNbFQcUjZNkGq46OWMVK9o+2BEy"

  @send : (options,callback) ->
    {From,To,Subject,HtmlBody,TextBody} = options
    mailOptions =
      From    : From
      to      : To
      subject : Subject
      text    : TextBody
      html    : HtmlBody

    Emailer.smtpTransport.sendMail mailOptions, (error, response) ->
      if error
        callback error
      else
        callback null, "Message sent: " + response.message

