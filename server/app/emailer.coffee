class Emailer
  @smtpTransport = nodemailer.createTransport "SMTP",
    service: "SES"
    auth:
      user: "AKIAJAC35KADH6ZUKSJA"
      pass: "AuuZXaIiI1XacyWULnNbFQcUjZNkGq46OWMVK9o+2BEy"

  @send : (options,callback) ->
    {From,To,Subject,HtmlBody,TextBody,ReplyTo} = options
    mailOptions =
      from    : From
      to      : To
      subject : Subject

    
    mailOptions.text      = TextBody  if TextBody? isnt ''
    mailOptions.html      = HtmlBody  if HtmlBody? isnt ''
    mailOptions.replyTo   = ReplyTo   if ReplyTo
    
    # console.log mailOptions
    setTimeout ->
      Emailer.smtpTransport.sendMail mailOptions, (error, response) ->
        if error
          # console.log error
          callback error
        else
          # console.log "sent:",mailOptions.to,response
          callback null, "Message sent: " + response.message
    ,1000/20
  @simulate : (options,callback)->

    setTimeout ->
      console.log "[SIMULATION] EMAIL SENT TO #{options.To}"
    ,250