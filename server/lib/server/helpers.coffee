koding     = require './bongo'

error_messages =
  404: "Page not found."
  500: "Something wrong."

error_ = (code, message)->
  messageHTML = message.split('\n')
    .map((line)-> "<p>#{line}</p>")
    .join '\n'
  """
  <!DOCTYPE html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <title>#{code} - #{error_messages[code]}</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel="stylesheet" href="//koding.com/hello/css/style.css">

  <link href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
  </head>
  <body>
    <div id="container">
      <header>
        <a href="http://koding.com">Koding.com</a>
      </header>
      <h2>
        #{code} - #{error_messages[code]}
      </h2>
      <div class="wrap" style="text-align: center;">
      #{messageHTML}
      </div>
    </div>
    <footer>
      fayamf
    </footer>
  </body>
  </html>
  """

error_404 = ->
  error_ 404, "This webpage is not available."

error_500 = ->
  error_ 500, "Something wrong with the Koding servers."

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

findUsernameFromKey = (req, res, callback) ->
  fetchJAccountByKiteUserNameAndKey req, (err, account)->
    if err
      console.log "we have a problem houston", err
      callback err, null
    else if not account
      console.log "couldnt find the account"
      res.send 401
      callback false, null
    else
      callback false, account.profile.nickname

findUsernameFromSession = (req, res, callback) ->
  {clientId} = req.cookies
  unless clientId?
    process.nextTick -> callback null, no, ""
  else
    koding.models.JSession.fetchSession clientId, (err, session)->
      if err
        console.error err
        callback err, undefined, ""
      else unless session?
        res.send 403, 'Access denied!'
        callback null, false, ""
      else
        callback null, false, session.username

fetchJAccountByKiteUserNameAndKey = (req, callback)->
  if req.fields
    {username, key} = req.fields
  else
    {username, key} = req.body

  {JKodingKey, JAccount} = koding.models
  {ObjectId} = require "bongo"

  JKodingKey.fetchByUserKey
    username: username
    key     : key
  , (err, kodingKey)=>
    console.log err, kodingKey.owner
    #if err or not kodingKey
    #  return callback(err, kodingKey)

    JAccount.one
      _id: ObjectId(kodingKey.owner)
    , (err, account)->
      if not account or err
         callback("couldnt find account #{kodingKey.owner}", null)
         return
      console.log "account ====================="
      console.log account
      console.log "======== account"
      req.account = account
      callback(err, account)

renderLoginTemplate = (resp, res)->
  saveOauthToSession resp, ->
    {loginTemplate} = require './staticpages'
    serve loginTemplate, res

serve = (content, res)->
  res.header 'Content-type', 'text/html'
  res.send content

isLoggedIn = (req, res, callback)->
  {JName} = koding.models
  findUsernameFromSession req, res, (err, isLoggedIn, username)->
    return callback null, no, {}  unless username
    JName.fetchModels username, (err, models)->
      user = models.last
      user.fetchAccount "koding", (err, account)->
        if err or account.type is 'unregistered'
        then callback err, no, account
        else callback null, yes, account

saveOauthToSession = (resp, callback)->
  {JSession} = koding.models
  {provider, access_token, id, login, email, firstName, lastName, clientId} = resp
  JSession.one {clientId}, (err, session)->
    foreignAuth           = {}
    foreignAuth[provider] =
      token     : access_token
      foreignId : String(id)
      username  : login
      email     : email
      firstName : firstName
      lastName  : lastName

    JSession.update {clientId}, $set: {foreignAuth}, callback

getAlias = do->
  caseSensitiveAliases = ['auth']
  (url)->
    rooted = '/' is url.charAt 0
    url = url.slice 1  if rooted
    if url in caseSensitiveAliases
      alias = "#{url.charAt(0).toUpperCase()}#{url.slice 1}"
    if alias and rooted then "/#{alias}" else alias

module.exports = {
  error_
  error_404
  error_500
  authenticationFailed
  findUsernameFromKey
  findUsernameFromSession
  fetchJAccountByKiteUserNameAndKey
  renderLoginTemplate
  serve
  isLoggedIn
  saveOauthToSession
  getAlias
}