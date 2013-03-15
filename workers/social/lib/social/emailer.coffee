module.exports = class Emailer
  nodemailer = require 'nodemailer'

  email = require './config.email'

  @smtpTransport = nodemailer.createTransport "SMTP",
    service: "SES"
    auth:
      user: "AKIAJAC35KADH6ZUKSJA"
      pass: "AuuZXaIiI1XacyWULnNbFQcUjZNkGq46OWMVK9o+2BEy"

  @send : (options,callback) ->
    {From,To,Subject,HtmlBody,TextBody,ReplyTo} = options
    mailOptions =
      from    : email.defaultFromAddress
      to      : To
      subject : Subject

    mailOptions.text      = TextBody  if TextBody
    mailOptions.html      = HtmlBody  if HtmlBody
    mailOptions.replyTo   = ReplyTo   if ReplyTo

    # console.log mailOptions
    setTimeout ->
      Emailer.smtpTransport.sendMail mailOptions, (error, response) ->
        # console.log 'got a response', arguments
        if error
          # console.log error
          callback error
        else
          # console.log "sent:",mailOptions.to
          callback null, "Message sent: " + response.message
    ,1000/20

  @simulate : (options,callback)->

    setTimeout ->
      console.log "[SIMULATION] EMAIL SENT TO #{options.To}"
    ,250