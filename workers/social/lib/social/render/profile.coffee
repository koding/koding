module.exports = (options, callback) ->

  getStyles    = require './styleblock'
  fetchScripts = require './scriptblock'
  getGraphMeta = require './graphmeta'
  getTitle     = require './title'
  encoder      = require 'htmlencode'

  { account, renderedAccount, loggedIn, content, bongoModels, client } = options
  { profile, counts, skilltags }                                       = renderedAccount
  { nickname, firstName, lastName, hash, about, handles, staticPage }  = profile

  staticPage    ?= {}
  { customize }  = staticPage

  { locationTags, meta } = account

  firstName   ?= 'Koding'
  lastName    ?= 'User'
  nickname    ?= ''
  about       ?= ''
  title        = "#{firstName} #{lastName}"
  slug         = nickname
  amountOfDays = Math.floor (new Date().getTime() - meta.createdAt) / (1000 * 60 * 60 * 24)

  hash    = profile.hash or ''
  avatar  = profile.avatar or no
  bgImg   = "//gravatar.com/avatar/#{hash}?size=90&d=#{encodeURIComponent '//a/images/defaultavatar/default.avatar.90.png'}"
  if avatar
    bgImg = "/-/image/cache?endpoint=crop&grow=false&width=90&height=90&url=#{encodeURIComponent avatar}"

  entryPoint = { slug : profile.nickname, type: 'profile' }

  prepareHTML = (scripts) ->

    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle()}
      #{getStyles()}
    </head>
    <body>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{KONFIG.getConfigScriptTag { entryPoint, roles:['guest'], permissions:[] }}
      <script>KD.isLoggedInOnLoad=#{loggedIn};</script>
      #{scripts}

    </body>
    </html>
    """

  # inject entryPoint
  options.entryPoint = entryPoint

  fetchScripts options, (err, scripts) ->
    callback null, prepareHTML scripts


