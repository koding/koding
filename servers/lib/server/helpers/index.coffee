koding = require '../bongo'
KONFIG  = require 'koding-config-manager'
request = require 'request'
url     = require 'url'
async = require 'async'
error_messages =
  404: 'Page not found'
  500: 'Something wrong.'

{
  fetchSession
  findUsernameFromSession
  isLoggedIn
  addReferralCode
  handleClientIdNotFound
  getClientId
  setSessionCookie
  checkAuthorizationBearerHeader
} = require './session'

{
  fetchGroupOAuthSettings
  saveOauthToSession
  fetchUserOAuthInfo
  redirectOauth
  failedReq
} = require './oauth'

validateEmail = (email) ->
  re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  return re.test email

error_ = (code, message) ->
  # Refactor this to use pistachio instead of underscore template engine - FKA
  staticpages  = require '../staticpages'
  { template } = require 'underscore'
  messageHTML  = message.split('\n')
    .map((line) -> "<p>#{line}</p>")
    .join '\n'

  { errorTemplate } = staticpages
  errorTemplate   = staticpages.notFoundTemplate if code is 404

  template errorTemplate, { code, error_messages, messageHTML }

error_404 = ->
  error_ 404, 'Return to Koding home'

error_500 = ->
  error_ 500, 'Something wrong with the Koding servers.'

authTemplate = (msg) ->
  { authRegisterTemplate } = require '../staticpages'
  { template }             = require 'underscore'
  template authRegisterTemplate, { msg }

authenticationFailed = (res, err) ->
  res.status(403).send "forbidden! (reason: #{err?.message or "no session!"})"


serve = (content, res) ->
  res.header 'Content-type', 'text/html'

  res.send content

# www.regextester.com/22
ipv4Regex = ///^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$///
isV4Format = (ip) -> ipv4Regex.test ip


isTeamPage = (req) ->
  hostname = req?.headers?['x-host']
  return no  unless hostname

  hostname = "http://#{hostname}" unless /^http/.test hostname
  { hostname } = url.parse hostname

  # special case for QA team, sometimes they test on ips
  return no  if isV4Format hostname

  labels = hostname.split '.'
  subdomains = labels.slice 0, labels.length - 2

  return no  unless subdomain = subdomains.pop()

  envMatch = no

  for name in ['default', 'dev', 'sandbox', 'latest', 'prod']
    if name is subdomain
      envMatch = yes
      break

  return yes  unless envMatch

  return if subdomain = subdomains.pop()
  then yes
  else no

serveHome = (req, res, next) ->
  { JGroup } = bongoModels = koding.models
  { generateFakeClient }   = require '../client'
  generateFakeClient req, res, (err, client, session) ->
    return next() if err or not client

    isLoggedIn req, res, (err, isLoggedIn, account) ->
      if err
        res.status(500).send error_500()
        return console.error err

      # construct options
      client.connection.delegate = account
      { params }                 = req
      { loggedIn, loggedOut }    = JGroup.render
      fn                         = if isLoggedIn then loggedIn else loggedOut
      options                    = { client, account, bongoModels, params, session }

      serveKodingHome = ->
        fn.kodingHome options, (err, subPage) ->
          return next()  if err
          return serve subPage, res

      return serveKodingHome() if req.path isnt '/'

      # main path has a special case where all users should be redirected to
      # hubspot

      # if incoming request goes to a team page, should resolve immediately -
      # without a redirection requirement
      if isTeamPage(req)
        return serveKodingHome() if isLoggedIn

        return res.redirect 307, '/Login'

      # but if we are in dev or sandbox env, serve content as we used to
      if KONFIG.environment in ['dev', 'default', 'sandbox']
        return serveKodingHome()  if isLoggedIn

        return res.redirect 307, '/Teams'

      # all other requests coming to slash, goes back to KONFIG.marketingPagesURL
      return res.redirect 307, KONFIG.marketingPagesURL


getAlias = do ->
  caseSensitiveAliases = ['auth']
  (url) ->
    rooted = '/' is url.charAt 0
    url = url.slice 1  if rooted
    if url in caseSensitiveAliases
      alias = "#{url.charAt(0).toUpperCase()}#{url.slice 1}"
    if alias and rooted then "/#{alias}" else alias


isInAppRoute = (name) ->
  [firstLetter] = name
  return false  if /^[0-9]/.test firstLetter # user nicknames can start with numbers
  return true   if firstLetter.toUpperCase() is firstLetter
  return false

isMainDomain = (req) ->

  { headers } = req

  return no  unless headers

  { host } = headers

  mainDomains = [
    KONFIG.domains.base
    KONFIG.domains.main
    "dev.#{KONFIG.domains.base}"
    "prod.#{KONFIG.domains.base}"
    "latest.#{KONFIG.domains.base}"
    "sandbox.#{KONFIG.domains.base}"
  ]

  return host in mainDomains


module.exports = {
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  serve
  serveHome
  getAlias
  saveOauthToSession

  isInAppRoute
  isMainDomain
  isTeamPage
  analyzedInvitationResults
  fetchGroupMembersAndInvitations

  # exports from session
  fetchSession
  findUsernameFromSession
  isLoggedIn
  addReferralCode
  handleClientIdNotFound
  getClientId
  setSessionCookie
  checkAuthorizationBearerHeader

  # exports from oauth
  fetchGroupOAuthSettings
  saveOauthToSession
  fetchUserOAuthInfo
  redirectOauth
  failedReq

  # exports from csv uploader
  fetchGroupMembersAndInvitations
  analyzedInvitationResults
}
