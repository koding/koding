module.exports = new class

  createKodingError = (message) ->
    message:
      if 'string' is typeof err
      then err
      else err.message

  required = (field) =>
    @::[field] = (userData, callback) ->
      callback(
        unless userData[field]?
        then { message: "Missed a required field: #{field}" }
        else null
      )

  ['firstName', 'lastName'].forEach required

  # TODO: do we support invitation codes yet/at all/only for other groups
  ###
  inviteCode:
  ###

  agree: ({agree}, callback) ->
    callback(
      if agree isnt 'on'
      then createKodingError 'You have to agree to the TOS'
      else null
    )

  username: ({username}, callback) ->

    @usernameAvailable username, (err, r) =>
      # r =
      #   forbidden    : yes/no
      #   kodingenUser : yes/no
      #   kodingUser   : yes/no
      callback(
        if err then err
        else if r.forbidden then createKodingError 'That username is forbidden!'
        else if r.kodingUser then callback createKodingError 'That username is taken!'
        else callback null
      )

  password: ({password, passwordConfirm}, callback) ->
    callback(
      if password isnt passwordConfirm
      then createKodingError "Passwords must match"
      else if password.length < 8
      then createKodingError "Password must be at least 8 characters"
      else null
    )