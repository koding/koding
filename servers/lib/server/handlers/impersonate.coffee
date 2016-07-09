koding = require './../bongo'

{
  setSessionCookie
} = require '../helpers'

module.exports = (req, res) ->
  { JAccount, JSession } = koding.models
  { nickname }           = req.params
  { clientId }           = req.cookies

  JSession.fetchSession { clientId }, (err, result) ->
    return res.status(400).end()  if err or not result

    { session } = result

    { username } = session
    JAccount.one { 'profile.nickname' : username }, (err, account) ->
      return res.status(400).end()  if err or not account

      unless account.can 'administer accounts'
        return res.status(403).end()

      createSessionParams =
        username  : nickname
        groupName : session.groupName or 'koding'

      JSession.createNewSession createSessionParams, (err, session) ->
        return res.status(400).send err.message  if err

        JSession.remove { clientId }, (err) ->
          console.error 'Could not remove session:', err  if err

          setSessionCookie res, session.clientId

          res.clearCookie 'realtimeToken'
          res.status(200).send { success: yes }
