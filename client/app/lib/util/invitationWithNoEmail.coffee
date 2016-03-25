remote  = require('app/remote').getInstance()

module.exports = (data, currentGroup, callback) ->

  id = data.getId()
  { profile : { email, firstName, lastName } } = data
  invitations = [ { email, firstName, lastName, role : 'member' } ]

  remote.api.JInvitation.create
    invitations : invitations
    noEmail     : yes
    returnCodes : yes
  , (err, res) =>

    return callback err  if err
    return callback {message: 'Something went wrong, please try again!'}  unless res

    invite = res[0]
    invite.status = 'accepted'
    invite.accept().then (response) ->

      currentGroup.unblockMember id, (err) ->

        return callback err  if err
        callback null, response

    .catch (err) -> callback err
