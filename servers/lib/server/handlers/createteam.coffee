# coffeelint: disable=cyclomatic_complexity
_                                       = require 'underscore'
async                                   = require 'async'
Bongo                                   = require 'bongo'
koding                                  = require './../bongo'
KONFIG                                  = require 'koding-config-manager'

{ uniq }                                = require 'underscore'
{ hostname, environment }               = KONFIG
{ getClientId, handleClientIdNotFound } = require './../helpers'
{ validateTeamDomain }                  = require '../../../../workers/social/lib/social/models/user/validators'
createPaymentPlan                       = require './createpaymentplan'

module.exports = (req, res, next) ->

  { body }                       = req
  { # slug is team slug, unique name. Can not be changed
    slug
    username
    email
    # newsletter holds announcements config.
    newsletter
    # is request coming from hubspot?
    fromHubspot
    # is group creator already a member
    alreadyMember }              = body
  body.groupName                 = slug
  # needed for JUser.login to know that it is a regular login or group creation
  body.groupIsBeingCreated       = yes

  clientId                       = getClientId req, res

  { JUser, JGroup, JInvitation } = koding.models

  return handleClientIdNotFound res, req  unless clientId

  client              = {}
  context             = { group: slug }
  client.context      = context
  clientIPAddress     = req.headers['x-forwarded-for'] or req.connection.remoteAddress
  # parsing booling from string
  alreadyMember       = alreadyMember is 'true'

  queue = [

    (next) ->
      koding.fetchClient clientId, context, (client_) ->

        client = client_
        # when there is an error in the fetchClient, it returns message in it
        if client.message
          console.error JSON.stringify { req, client }
          return next { status: 500, message: client.message }

        client.clientIP = (clientIPAddress.split ',')[0]

        # subscribe to koding marketing mailings or not
        body.emailFrequency         or= {}
        # convert string boolean to boolean
        body.emailFrequency.marketing = newsletter is 'true'
        next()

    (next) ->
      # checking if group slug is same with the username
      if slug.toLowerCase?() is body.username?.toLowerCase?()
        message = 'Sorry, your group domain and your username can not be the same!'
        return next { status: 400, message: message }

      # checking if group slug was already used
      JGroup.one { slug }, (err, group) ->
        return next { status: 500, message: 'an error occured' }  if err
        return next { status: 403, message: "Sorry,
          Team URL '#{slug}.#{hostname}' is already in use" }  if group
        next()

    (next) ->

      checkUserLogin = (_body, next) ->
        # checking if user exists by trying to login the user
        JUser.login client.sessionToken, _body, (err, result) ->
          errorMessage          = err?.message
          unknownUsernameError  = 'Unknown user name'

          # send HTTP 400 if somehow alreadyMember is true but user doesnt exist
          if alreadyMember and errorMessage is unknownUsernameError
            return next { status: 400, message: unknownUsernameError }

          # setting alreadyMember to true if error is not unknownUsernameError
          # ignoring other errors here since our only concern is checking if user exists
          alreadyMember = errorMessage isnt unknownUsernameError
          next()

      if alreadyMember and fromHubspot and email and not username
        body.username = email
        checkUserLogin body, next

      else if not alreadyMember and fromHubspot and email

        candidateUsername = email.split('@')[0]
        index = 1

        do generateUsername = ->
          _username = "#{candidateUsername}#{index++ or ''}"

          # fetch user with a candidate username
          JUser.one { username: _username }, (err, res) ->

            # if there is an error or there is not a result with this username
            # this means that the candidate username can be used.
            if err or not res
              body.username = _username
              checkUserLogin body, next

            # if there isn't an error that means that there is a user with this
            # username, so generate new one and try with that.
            else
              generateUsername()

      else
        checkUserLogin body, next


  ]

  unless KONFIG.environment is 'production'
    res.header 'Access-Control-Allow-Origin', 'http://dev.koding.com:4000'


  async.series queue, (err) ->

    index = 1
    generateTeamName = (next) ->
      _slug = "#{slug}#{index++}"
      JGroup.one { slug: _slug }, (_err, existingGroup) ->
        if _err or not existingGroup
          err.suggested = _slug
          return res.status(err.status).json err
        next { message: 'try again with new group slug' }

    # if err means that this group exists, try to find a new group name to be
    # suggested.
    if err
      return res.status(err.status).json err  unless err.status is 403
      return async.retry 20, generateTeamName, ->
        return res.status(err.status).json err

    # generating callback function to be used in both login and convert
    createGroup = createGroupKallback client, req, res, body

    if alreadyMember
    then JUser.login client.sessionToken, body, createGroup
    else JUser.convert client, body, createGroup


createGroupKallback = (client, req, res, body) ->

  # returning a callback function
  return (err, result) ->

    return res.status(400).send getErrorMessage err  if err?

    { # companyName, team name, basically a title, can be changed
      companyName
      # slug is team slug, unique name. Can not be changed
      slug
      redirect
      # invitees are comma separated emails which will be invited to that team
      invitees
      # domains holds allowed domains for signinup without invitation, comma separated
      domains
      # username or email of the user, can be already registered or a new one for creation
      username
      # title of team's limit
      limit
    } = body

    token = result.newToken or result.replacementToken

    { JUser, JGroup, JInvitation } = koding.models

    # this logs you in the newly created group but causes problems
    # for the default and other subdomains
    # need to find another way - SY

    teamDomain = ".#{KONFIG.domains.main}"

    # set session token for later usage down the line
    owner                      = result.account
    redirect                  ?= '/'
    client.sessionToken        = token
    client.connection.delegate = result.account

    if validationError = validateGroupData body
      return res.status(validationError.status).send validationError.message

    afterGroupCreate = afterGroupCreateKallback res, {
      body             : body
      client           : client
      username         : result.account.profile.nickname
    }

    createOptions =
      slug            : slug
      title           : companyName
      visibility      : 'hidden'
      allowedDomains  : convertToArray domains # clear & convert domains into array
      defaultChannels : []

    if limit
      createOptions.config = { limit }

    JGroup.create client, createOptions, owner, afterGroupCreate



afterGroupCreateKallback = (res, params) ->

  { JUser, JTeamInvitation, Tracker } = koding.models
  { body : { slug, invitees, coupon, stripeToken }, client,  username } = params

  return (err, group) ->
    if err or not group
      console.error 'Error while creating the group', err
      return res.status(500).send "Couldn't create the group."

    queue = [

      # add other parallel operations here
      (fin) ->
        createInvitations client, invitees, (err) ->
          console.error 'Err while creating invitations', err  if err
          fin()

      (fin) ->
        params = { sessionToken: client.sessionToken }
        params.coupon = coupon  if coupon
        params.source = { token: stripeToken, default: true }  if stripeToken
        createPaymentPlan params, (err) ->
          console.error 'Err while creating payment plan', err  if err
          fin()

    ]

    async.parallel queue, (err) ->
      # do not block group creation
      console.error 'Error while creating group artifacts', body, err if err

      opt =
        username  : username
        groupName : slug

      data =
        token : JUser.createJWT opt

      # add user to Segment group
      Tracker.group slug, username

      return res.status(200).send data


validateGroupData = (body) ->

  unless body.slug
    return { status: 400, message: 'Group slug can not be empty.' }

  unless validateTeamDomain body.slug
    return { status: 400, message: 'Invalid group slug.' }

  else unless body.companyName
    return { status: 400, message: 'Company name can not be empty.' }

  else return null

# convertToArray converts given comma separated string value into cleaned,
# trimmed, lowercased, unified array of string
convertToArray = (commaSeparatedData = '') ->
  return []  if commaSeparatedData is ''

  data = commaSeparatedData.split(',') or []

  data = data
    .filter (s) -> s isnt ''           # clear empty ones
    .map (s) -> s.trim().toLowerCase() # clear empty spaces

  return uniq data # remove duplicates

# createInvitations converts given invitee list into JInvitation and creates
# them in db
createInvitations = (client, invitees, callback) ->
  inviteEmails = convertToArray invitees

  return callback null  if inviteEmails.length is 0 # return early

  # should be in following structure
  #   data = { invitations:[ {email:"cihangir+test26@koding.com"} ] }
  invitations = inviteEmails.map (email) -> { email }

  koding.models.JInvitation.create client, { invitations }, callback


getErrorMessage = (err) ->

  { message } = err
  message     = "#{message}: #{Object.keys err.errors}"  if err.errors?

  return message
