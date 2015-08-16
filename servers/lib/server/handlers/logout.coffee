module.exports = (req, res) ->

  if req.method is 'POST'
    res.clearCookie 'clientId'
    res.clearCookie 'useOldKoding'
    res.clearCookie 'koding082014'

  res.redirect 301, '/'
