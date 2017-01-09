# coffeelint: disable=indentation
isEmailValid        = require './emailchecker'
reservedTeamDomains = require './reservedteamdomains'

module.exports = class Validators

  @validateTeamDomain: (name) ->

    teamDomainPattern = ///
      ^                     # beginning of the string
      [a-z0-9]+             # one or more 0-9 and/or a-z
      (
        [-]                 # followed by a single dash
        [a-z0-9]+           # one or more (0-9 and/or a-z)
      )*                    # zero or more of the token in parentheses
      $                     # end of string
    ///

    return (name not in reservedTeamDomains) and (teamDomainPattern.test name)


  createKodingError = (err) ->

    message: if 'string' is typeof err then err else err.message


  required = (field) ->

    Validators::[field] = (userData, callback) ->

      callback \
        unless userData[field]?
          createKodingError "Missed a required field: #{field}"
        else
          null

  # Since we removed first and last name requirement
  #
  # ['firstName', 'lastName'].forEach required


  agree: ({ agree }, callback) ->

    callback \
      unless agree is 'on'
        createKodingError 'You have to agree to the TOS'
      else
        null


  email: ({ email }, callback) ->

    callback \
      unless isEmailValid email
        createKodingError 'Email is not valid.'
      else
        null


  username: ({ username }, callback) ->

    unless username?
      return callback createKodingError 'Missed a required field: username'

    @usernameAvailable username, (err, r) ->

      # r =
      #   forbidden    : yes/no
      #   kodingenUser : yes/no
      #   kodingUser   : yes/no

      callback \

        if err then err
        else if r.forbidden
          createKodingError 'That username is forbidden!'
        else if r.kodingUser
          createKodingError 'That username is taken!'
        else
          null


  password: ({ password, passwordConfirm }, callback) ->

    callback \

      if not password? or not passwordConfirm?
        createKodingError 'Missed a required field: password / passwordConfirm'
      else if password isnt passwordConfirm
        createKodingError 'Passwords must match'
      else if password.length < 8
        createKodingError 'Password must be at least 8 characters'
      else
        null

  @isSoloAccessible: ({ groupName, account, cutoffDate, env }) ->
    # old data might not have createdAt?
    return yes  if not account?.meta?.createdAt?

    # everyone can login to their own team
    return yes  if groupName isnt 'koding'

    # use default cutoffDate if not provided
    cutoffDate ?= new Date 2016, 2, 11 # 11 March 2016

    # user should be created before cutoffDate to be able to login to koding
    return yes  if account.meta.createdAt.getTime() < cutoffDate.getTime()

    # but in any case allow logins on dev and sandbox env
    return yes  if env in ['dev', 'sandbox']

    return no
