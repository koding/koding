generateHumanstxt = (req, res) ->

  header =
    '''
    /* TEAM */
    Koding, Inc.
    Contact     : hello@koding.com
    Twitter     : twitter.com/koding
    Facebook    : facebook.com/koding
    GitHub      : github.com/koding
    Location    : San Francisco
    \n
    '''

  footer =
    """
    /* SITE */
    Last update : 2016/11/11
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

  content = header + footer
  res.setHeader 'Content-Type', 'text/plain'
  return res.status(200).send content

module.exports = { generateHumanstxt }
