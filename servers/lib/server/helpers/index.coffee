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



saveOauthToSession = (oauthInfo, clientId, provider, callback) ->
  { JSession } = koding.models

  query = { 'foreignAuthType': provider }

  if oauthInfo.returnUrl
    query.returnUrl = oauthInfo.returnUrl
    delete oauthInfo.returnUrl

  query["foreignAuth.#{provider}"] = oauthInfo

  JSession.update { clientId }, { $set:query }, callback

redirectOauth = (err, req, res, options) ->
  { returnUrl, provider } = options

  err = if err then "&error=#{err}" else ''
  redirectUrl = "/Home/Oauth?provider=#{provider}#{err}"

  # when returnUrl does not exist, handle oauth authentication in client side
  # this is temporary solution for authenticating registered users
  return res.redirect(redirectUrl)  unless returnUrl

  return res.status(400).send err  if err

  isLoggedIn req, res, (err, isUserLoggedIn, account) ->

    return res.status(400).send err  if err

    # here session belongs to koding domain (not subdomain)
    sessionToken = req.cookies.clientId

    username = account?.profile?.nickname
    client =
      context       :
        user        : username
      connection    :
        delegate    : account
      sessionToken  : sessionToken

    { JUser } = koding.models
    return JUser.authenticateWithOauth client, { provider, isUserLoggedIn }, (err, response) ->

      return res.status(400).send err  if err

      # user is logged in and session data exists
      res.redirect returnUrl


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


fetchGroupMembersAndInvitations = (client, data, callback) ->

  { JGroup, JInvitation } = koding.models
  { group: slug } = client.context
  { connection: { delegate: account } } = client

  queue = [
    (next) ->
      JGroup.one { slug }, (err, group) ->

        return next err  if err

        return next 'There are more than 100 members', null  if group.count.members > 100

        group.fetchMembersWithEmail client, {}, (err, users) ->

          return next err  if err

          userEmails = []
          users.map (user) ->
            { profile: { email } } = user
            userEmails.push email

          next null, userEmails

    (next) ->
      account.fetchEmail (err, email) ->

        return next null, null  if err
        next null, email

    (next) ->
      JInvitation.some$ client, { status: 'pending' }, {}, (err, invitations) ->

        return next null, []  if err

        pendingEmails = []
        invitations.map (invitation) ->
          pendingEmails.push invitation.email

        next null, pendingEmails
  ]

  async.series queue, (err, results) ->

    [ userEmails, myEmail, pendingEmails ] = results
    results = { userEmails, myEmail, pendingEmails }

    return callback err, results


analyzedInvitationResults = (params) ->

  myself = no
  adminEmails = 0
  membersEmails = 0
  alreadyMemberEmails = 0
  alreadyInvitedEmails = 0
  notValidInvites = 0

  { data, userEmails, pendingEmails, myEmail } = params

  invitationCount = data.length

  while invitationCount > 0
    invitationCount = invitationCount - 1
    invite = data[invitationCount]
    invite.role = invite.role?.toLowerCase()

    if not validateEmail(invite.email) or not invite.role
      notValidInvites = notValidInvites + 1
      data.splice invitationCount, 1
      continue

    if invite.role
      if invite.role isnt 'admin' and invite.role isnt 'member'
        notValidInvites = notValidInvites + 1
        data.splice invitationCount, 1
        continue

    if invite.email is myEmail
      data.splice invitationCount, 1
      notValidInvites = notValidInvites + 1
      myself = yes
      continue

    if invite.email in pendingEmails
      data.splice invitationCount, 1
      alreadyInvitedEmails = alreadyInvitedEmails + 1
      continue

    if invite.email in userEmails
      data.splice invitationCount, 1
      alreadyMemberEmails = alreadyMemberEmails + 1
      continue

    if invite.role is 'admin'
      adminEmails = adminEmails + 1
      continue

    if invite.role is 'member'
      membersEmails = membersEmails + 1
      continue

  result =
    myself: myself
    admins : adminEmails
    members: membersEmails
    extras :
      alreadyMembers: alreadyMemberEmails
      notValidInvites: notValidInvites
      alreadyInvited: alreadyInvitedEmails

  return { result, data }


fetchGroupOAuthSettings = (provider, clientId, state, callback) ->

  { JSession, JGroup } = koding.models
  { hostname, protocol } = KONFIG

  JSession.one { clientId }, (err, session) ->
    return callback err  if err
    return callback { message: 'Session invalid' }  unless session

    unless session._id.equals state
      return callback { message: 'Invalid oauth flow' }

    { groupName: slug } = session

    JGroup.one { slug }, (err, group) ->
      return callback err  if err
      return callback { message: 'Group invalid' }  unless group

      if not group.config?[provider]?.enabled
        return callback { message: 'Integration not enabled yet.' }

      group.fetchDataAt provider, (err, data) ->
        return callback err  if err
        return callback { message: 'Integration settings invalid' }  unless data

        callback null, {
          url: group.config[provider].url
          applicationId: group.config[provider].applicationId
          applicationSecret: data.applicationSecret
          redirectUri: "#{protocol}//#{slug}.#{hostname}/-/oauth/#{provider}/callback"
        }


failedReq = (provider, req, res) ->
  redirectOauth 'could not grant access', req, res, { provider }


# Get user info with access token
fetchUserOAuthInfo = (provider, req, res, data) ->

  { scope, access_token } = data
  _provider = provider.toUpperCase()

  return (error, response, body) ->

    if error
      console.error "[#{_provider}][4/4] Failed to fetch user info:", error
      return failedReq provider, req, res

    if 'string' is typeof body
      try body = JSON.parse body

    unless body.id?
      console.error "[#{_provider}][4/4] Missing id in body:", body
      return failedReq provider, req, res

    { username, login, id, email, name } = body
    { returnUrl } = req.query
    { clientId }  = req.cookies

    username ?= login

    if name
      [firstName, restOfNames...] = name.split ' '
      lastName = restOfNames.join ' '

    resp = {
      email
      scope
      lastName
      username
      firstName
      returnUrl
      token     : access_token
      foreignId : String(id)
    }

    saveOauthToSession resp, clientId, provider, (err) ->
      redirectOauth err, req, res, { provider, returnUrl }


module.exports = {
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  serve
  serveHome
  getAlias
  fetchGroupOAuthSettings
  fetchUserOAuthInfo
  failedReq
  saveOauthToSession
  redirectOauth
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
}
