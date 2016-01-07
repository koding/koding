module.exports = (req, res) ->

  res.cookie 'useOldKoding', 'true'
  res.redirect 301, '/'
