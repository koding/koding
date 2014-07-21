addHomeLinkBar = ->
  slug = 'koding'
  """
  <div class='screenshots'>
    <div class="home-links" id='home-login-bar'>
      <div class='overlay'></div>
      <a class="custom-link-view browse orange" href="#"><span class="icon"></span><span class="title">Learn more...</span></a><a class="custom-link-view join green" href="/#{slug}/Login"><span class="icon"></span><span class="title">Request an Invite</span></a><a class="custom-link-view register" href="/#{slug}/Register"><span class="icon"></span><span class="title">Register</span></a><a class="custom-link-view login" href="/#{slug}/Login"><span class="icon"></span><span class="title">Login</span></a>
    </div>
  </div>
  """

module.exports = (options, callback)->

  getStyles    = require './styleblock'
  fetchScripts = require './scriptblock'
  getGraphMeta = require './graphmeta'
  getTitle     = require './title'
  encoder      = require 'htmlencode'

  {account, renderedAccount, isLoggedIn, content, bongoModels, client} = options
  {profile, counts, skilltags}                                         = renderedAccount
  {nickname, firstName, lastName, hash, about, handles, staticPage}    = profile

  staticPage  ?= {}
  {customize}  = staticPage

  {locationTags, meta} = account

  firstName   ?= 'Koding'
  lastName    ?= 'User'
  nickname    ?= ''
  about       ?= ''
  title        = "#{firstName} #{lastName}"
  slug         = nickname
  amountOfDays = Math.floor (new Date().getTime()-meta.createdAt)/(1000*60*60*24)

  hash    = profile.hash or ''
  avatar  = profile.avatar or no
  bgImg   = "//gravatar.com/avatar/#{hash}?size=90&d=#{encodeURIComponent '//a/images/defaultavatar/default.avatar.90.png'}"
  if avatar
    bgImg = "//i.embed.ly/1/display/crop?grow=false&width=90&height=90&key=94991069fb354d4e8fdb825e52d4134a&url=#{encodeURIComponent avatar}"

  entryPoint = { slug : profile.nickname, type: "profile" }

  prepareHTML = (scripts)->

    """
    <!doctype html>
    <html lang="en">
    <head>
      #{getTitle()}
      #{getStyles()}
    </head>
    <body>

      <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

      #{KONFIG.getConfigScriptTag {entryPoint, roles:['guest'], permissions:[]}}
      #{scripts}

    </body>
    </html>
    """

  # inject entryPoint
  options.entryPoint = entryPoint

  fetchScripts options, (err, scripts)->
    callback null, prepareHTML scripts
