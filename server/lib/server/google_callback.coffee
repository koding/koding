{
  renderOauthPopup
  saveOauthToSession
}                  = require './helpers'
{google}           = KONFIG
http               = require "https"
{parseString}      = require 'xml2js'
querystring        = require 'querystring'
{flatten}          = require "underscore"
koding             = require './bongo'
{JReferrableEmail} = koding.models

module.exports = (req, res) ->

  access_token  = null
  refresh_token = null
  {code}        = req.query
  {clientId}    = req.cookies
  {
    client_id
    client_secret
    redirect_uri
  }            = google

  unless code
    renderOauthPopup res, {error:"No code in query", provider:"google"}
    return

  # Get user info with access token
  fetchUserInfo = (userInfoResp)->
    rawResp = ""
    userInfoResp.on "data", (chunk) -> rawResp += chunk
    userInfoResp.on "end", ->
      try
        {id} = JSON.parse rawResp
      catch e
        renderOauthPopup res, {error:"Error getting id", provider:"google"}

      if id
        googleResp                 = {}
        googleResp["token"]        = access_token
        googleResp["foreignId"]    = id
        googleResp["refreshToken"] = refresh_token
        googleResp["expires"]      = new Date().getTime()+3600

        saveOauthToSession googleResp, clientId, "google", (err)->
          if err
            renderOauthPopup res, {error:"Error saving oauth info", provider:"google"}
            return

          path  = "/m8/feeds/contacts/default/full?"
          path += "access_token=#{access_token}&"
          path += "updated-min=2010-01-01T00:00:00" # just a random date to get latest contacts

          options =
            host   : "www.google.com"
            path   : path
            method : "GET"
          r = http.request options, fetchUserContacts
          r.end()
      else
        renderOauthPopup res, {error:"Error getting id", provider:"google"}

  # Get user contacts with access token
  fetchUserContacts = (contactsResp)->
    rawResp = ""
    contactsResp.on "data", (chunk) -> rawResp += chunk
    contactsResp.on "end", ->
      try
        parseString rawResp, (err, result) ->
          if err
            renderOauthPopup res, {error:"Error parsing contacts info", provider:"google"}
            return

          for i in result.feed.entry
            for e in i["gd:email"]
              email = e["$"].address
              JReferrableEmail.create clientId, email, (err)->
                console.log "error saving JReferrableEmail", err
      catch e
        console.log "google callback error parsing emails"

      renderOauthPopup res, {error:null, provider:"google"}

  authorizeUser = (authUserResp)->
    rawResp = ""
    authUserResp.setEncoding('utf8')
    authUserResp.on "data", (chunk) -> rawResp += chunk
    authUserResp.on "end", ->
      try
        tokenInfo = JSON.parse rawResp
      catch e
        renderOauthPopup res, {error:"Error getting access token", provider:"google"}

      {access_token, refresh_token} = tokenInfo
      if access_token
        options =
          host   : "www.googleapis.com"
          path   : "/oauth2/v2/userinfo?alt=json&access_token=#{access_token}"
          method : "GET"
        r = http.request options, fetchUserInfo
        r.end()
      else
        renderOauthPopup res, {error:"No access token", provider:"google"}

  postData   = querystring.stringify {
    code,
    client_id,
    client_secret,
    redirect_uri,
    grant_type : "authorization_code"
  }

  options   =
    host    : "accounts.google.com"
    path    : "/o/oauth2/token"
    method  : "POST"
    headers : {
      'Content-Type'  : 'application/x-www-form-urlencoded'
      'Content-Length': postData.length,
      'Accept'        :'application/json'
    }

  r = http.request options, authorizeUser
  r.write postData
  r.end()

  r.on 'error', (e)-> console.log 'problem with request: ' + e.message
