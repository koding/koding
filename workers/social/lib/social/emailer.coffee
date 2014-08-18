module.exports = class Emailer
  nodemailer = require 'nodemailer'

  email = require './config.email'

  @smtpTransport = nodemailer.createTransport "SMTP",
    service: "SendGrid"
    auth:
      user: "koding"
      pass: "DEQl7_Dr"

  @send : (options,callback) ->
    {From,To,Subject,HtmlBody,TextBody,ReplyTo,Bcc} = options
    mailOptions =
      from    : From or email.defaultFromMail
      to      : To
      subject : Subject

    mailOptions.text    = TextBody  if TextBody
    mailOptions.html    = HtmlBody  if HtmlBody
    mailOptions.replyTo = ReplyTo   if ReplyTo
    mailOptions.bcc     = Bcc       if Bcc

    # console.log mailOptions
    setTimeout ->
      Emailer.smtpTransport.sendMail mailOptions, (error, response) ->
        # console.log 'got a response', arguments
        if error
          # console.log error
          callback error
        else
          callback null, response
    ,1000/20

  @simulate : (options,callback)->

    setTimeout ->
      console.log "[SIMULATION] EMAIL SENT TO #{options.To}"
    ,250
