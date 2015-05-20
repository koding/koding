koding = require './../bongo'

module.exports = (req, res) ->
  { JAccount, JSession } = koding.models
  {nickname} = req.params

  {clientId} = req.cookies

  JSession.fetchSession clientId, (err, result)->
    return res.status(400).end()  if err or not result

    { username } = result.session
    JAccount.one { "profile.nickname" : username }, (err, account) ->
      return res.status(400).end()  if err or not account

      unless account.can 'administer accounts'
        return res.status(403).end()

      JSession.createNewSession {
        nickname  : nickname
        # set parent group name into kookie
        groupName : result.groupName or "koding"
      }, (err, session) ->
        return res.status(400).send err.message  if err

        JSession.remove {clientId}, (err) ->
          console.error 'Could not remove session:', err  if err

          res.cookie 'clientId', session.clientId, path : '/'  if session.clientId
          res.clearCookie 'realtimeToken'
          res.status(200).send({success: yes})
