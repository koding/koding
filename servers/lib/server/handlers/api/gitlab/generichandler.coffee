apiErrors = require '../errors'
Bongo = require '../../../bongo'

module.exports = class GenericHandler

  @getBongo = -> Bongo

  @getModels = -> @getBongo().models

  @apiError = (err) -> apiErrors[err] ? apiErrors.internalError

  @validateDataFor = (event, data) ->

    switch event
      when 'create', 'destroy'

        { username, name, email } = data

        unless email
          return { error : apiErrors.invalidInput }

        unless username
          return { error : apiErrors.invalidInput }

        if name and name isnt ''
          [ firstName, lastName... ] = name.split ' '
          lastName = lastName.join ' '
        else
          [ firstName, lastName ] = [ name, '' ]

        suggestedUsername = username

        return {
          error : null, username, email,
          firstName, lastName, suggestedUsername
        }

      else

        { error: apiErrors.notImplementedError }
