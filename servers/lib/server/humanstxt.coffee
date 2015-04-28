bongo = require './bongo'

generateHumanstxt = (req, res)->
  {JAccount}       = bongo.models
  JAccount.some {'globalFlags': 'staff'}, {}, (err, accounts)->
    if err or not accounts
      return res.status(500).end()
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
        /* TEAM */
        Koding, Inc.
        Contact     : hello@koding.com
        Twitter     : twitter.com/koding
        Facebook    : facebook.com/koding
        GitHub      : github.com/koding
        Location    : San Francisco
        \n
        """

      footer =
        """
        /* SITE */
        Last update : 2015/4/16
        Language    : English
        Standards   : HTML5, CSS3
        Software    : Golang, NodeJS, Coffeescript, KD, MongoDB, PostgreSql, http://github.com/koding for more.


        /\\ \\                /\\ \\  __
        \\ \\ \\/'\\     ___    \\_\\ \\/\\_\\    ___      __
         \\ \\ , <    / __`\\  /'_` \\/\\ \\ /' _ `\\  /'_ `\\
          \\ \\ \\\\`\\ /\\ \\L\\ \\/\\ \\L\\ \\ \\ \\/\\ \\/\\ \\/\\ \\L\\ \\
           \\ \\_\\ \\_\\ \\____/\\ \\___,_\\ \\_\\ \\_\\ \\_\\ \\____ \\
            \\/_/\\/_/\\/___/  \\/__,_ /\\/_/\\/_/\\/_/\\/___L\\ \\
                                                  /\\____/
                                                  \\_/__/
        """
      content = header + body + footer
      res.setHeader 'Content-Type', 'text/plain'
      return res.status(200).send content

module.exports = { generateHumanstxt }