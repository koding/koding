bongo = require './bongo'

generateHumanstxt = (req, res)->
  {JAccount}       = bongo.models
  JAccount.some {'globalFlags': 'staff'}, {}, (err, accounts)->
    if err or not accounts
      return res.send 500
    else
      body = ""
      for acc in accounts

        if acc?.profile?.nickname?
          {firstName, lastName, nickname} = acc.profile
          person = ""
          if firstName
            person = "#{firstName} "
            person += "#{lastName}\n" if lastName
          else
            person = "#{nickname}\n"
          person += "Site: https://koding.com/#{nickname}\n"

          if acc?.locationTags?
            person +=  "Location: #{acc.locationTags}\n"
          person += "\n"

          body += person

      header =
        """
          /* TEAM */\n
        """

      footer =
        """/* SITE */
            Last update:2013/12/02
            Language: English
            Doctype: HTML5
            IDE: Coffeescript, NodeJS, Golang, Sublime Text, MongoDB, RabbitMQ
        """
      content = header + body + footer
      res.setHeader 'Content-Type', 'text/plain'
      return res.send 200, content

module.exports = { generateHumanstxt }