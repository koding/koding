koding = require './bongo'
JName = require '../../models/name'
KONFIG  = require 'koding-config-manager'
request = require 'request'
url     = require 'url'
async = require 'async'
error_messages =
  404: 'Page not found'
  500: 'Something wrong.'

validateEmail = (email) ->
  re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  return re.test email

error_ = (code, message) ->
  # Refactor this to use pistachio instead of underscore template engine - FKA
  staticpages  = require './staticpages'
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
  { authRegisterTemplate } = require './staticpages'
  { template }             = require 'underscore'
  template authRegisterTemplate, { msg }

authenticationFailed = (res, err) ->
  res.status(403).send "forbidden! (reason: #{err?.message or "no session!"})"

findUsernameFromKey = (req, res, callback) ->
  fetchJAccountByKiteUserNameAndKey req, (err, account) ->
    if err
      console.error 'we have a problem houston', err
      callback err, null
    else if not account
      console.error 'couldnt find the account'
      res.status(401).end()
      callback false, null
    else
      callback false, account.profile.nickname


fetchSession = (req, res, callback) ->

  { clientId } = req.cookies

  unless clientId?
    return process.nextTick -> callback null

  koding.models.JSession.fetchSession { clientId }, (err, result) ->

    if err
      return callback err
    else unless result?
      return callback null

    { session } = result
    unless session?
    then callback null
    else callback null, session


findUsernameFromSession = (req, res, callback) ->

  fetchSession req, res, (err, session) ->
    callback err, session?.username


fetchJAccountByKiteUserNameAndKey = (req, callback) ->
  if req.fields
    { username, key } = req.fields
  else
    { username, key } = req.body

  { JKodingKey, JAccount } = koding.models
  { ObjectId }             = require 'bongo'

  JKodingKey.fetchByUserKey
    username: username
    key     : key
  , (err, kodingKey) ->
    console.error err, kodingKey.owner
    #if err or not kodingKey
    #  return callback(err, kodingKey)

    JAccount.one
      _id: ObjectId(kodingKey.owner)
    , (err, account) ->
      if not account or err
        callback("couldnt find account #{kodingKey.owner}", null)
        return

      req.account = account
      callback(err, account)

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
  { generateFakeClient }   = require './client'

  generateFakeClient req, res, (err, client, session) ->
    if err or not client
      console.error err
      return next()
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

      if req.path isnt '/'
        return serveKodingHome()

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

      # all other requests coming to slash, goes back to KONFIG.hubspotPageURL
      return res.redirect 307, KONFIG.hubspotPageURL



isLoggedIn = (req, res, callback) ->

  { JName } = koding.models

  findUsernameFromSession req, res, (err, username) ->

    return callback null, no, {}  unless username

    JName.fetchModels username, (err, result) ->

      return callback null, no, {}  unless result?

      { models } = result

      return callback null, no, {}  if err or not models?.first

      user = models.last
      user.fetchAccount 'koding', (err, account) ->

        if err or not account or account.type is 'unregistered'

          return callback err, no, account

        return callback null, yes, account


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

  redirectUrl = "/Home/Oauth?provider=#{provider}&error=#{err}"

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

      if err
      then res.status(400).send err
      # user is logged in and session data exists
      else res.redirect returnUrl


getAlias = do ->
  caseSensitiveAliases = ['auth']
  (url) ->
    rooted = '/' is url.charAt 0
    url = url.slice 1  if rooted
    if url in caseSensitiveAliases
      alias = "#{url.charAt(0).toUpperCase()}#{url.slice 1}"
    if alias and rooted then "/#{alias}" else alias

# adds referral code into cookie if exists
addReferralCode = (req, res) ->
  match = req.path.match(/\/R\/(.*)/)
  if match and refCode = match[1]
    res.cookie 'referrer', refCode, { maxAge: 900000, secure: true }

handleClientIdNotFound = (res, req) ->
  err = { message: 'clientId is not set' }
  console.error JSON.stringify { req: req.body, err }
  return res.status(500).send err

getClientId = (req, res) ->
  return req.cookies.clientId or req.pendingCookies.clientId

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


{ sessionCookie } = KONFIG

setSessionCookie = (res, sessionId, options = {}) ->

  options.path    = '/'
  options.secure  = sessionCookie.secure
  options.expires = new Date(Date.now() + sessionCookie.maxAge)

  # somehow we are sending two clientId cookies in some cases, last writer wins.
  res.clearCookie 'clientId', options
  res.cookie 'clientId', sessionId, options


checkAuthorizationBearerHeader = (req) ->

  return null  unless req.headers?.authorization
  parts = req.headers.authorization.split ' '

  return null  unless parts.length is 2 and parts[0] is 'Bearer'
  token = parts[1]

  return null  unless typeof token is 'string' and token.length > 0

  return token

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


module.exports = {
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  fetchSession
  findUsernameFromKey
  findUsernameFromSession
  fetchJAccountByKiteUserNameAndKey
  serve
  serveHome
  isLoggedIn
  getAlias
  addReferralCode
  saveOauthToSession
  redirectOauth
  handleClientIdNotFound
  getClientId
  isInAppRoute
  isMainDomain
  setSessionCookie
  checkAuthorizationBearerHeader
  isTeamPage
  analyzedInvitationResults
  fetchGroupMembersAndInvitations
}
