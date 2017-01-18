---
---

utils = window.KODING_UTILS ?= {}

do ->

  validateUsername = (username, opts = { async: yes }) -> new Promise (resolve, reject) ->
    switch
      when username.indexOf('@') > -1
        return validateEmail(username)

      when username.length < 4 or username.length > 25
        return reject
          message: 'Username should be between 4 and 25 characters!'
          decoratedMessage: yes

      when not /^[a-z0-9][a-z0-9-]+$/.test(username)
        return reject
          message: 'For username only lowercase letters and numbers are allowed!'
          decoratedMessage: yes

      when not opts.async
        return resolve()

    $.ajax
      url: "#{utils.KODING_URL}/-/validate/username"
      type: 'POST'
      data: { username }
      success: resolve
      error: reject

  validateTeamName = (slug, opts = { async: yes }) -> new Promise (resolve, reject) ->
    switch
      when slug.length < 3
        return reject
          message: 'Username should be longer than 2 characters.'
          decoratedMessage: yes

      when not /^[a-z0-9][a-z0-9-]+$/.test(slug)
        return reject
          message: 'For team names only letters and numbers are allowed!'
          decoratedMessage: true

      when not opts.async
        return resolve()

    $.ajax
      url: "#{utils.KODING_URL}/-/teams/verify-domain"
      type: 'POST'
      data: { name: slug }
      success: resolve
      error: reject

  validateEmail = (email = '', opts = { async: yes }) -> new Promise (resolve, reject) ->

    switch
      when not utils.isValidEmail(email)
        return reject
          message: 'Email must be formatted correctly.'
          decoratedMessage: yes

      when not opts.async
        return resolve()

    $.ajax
      url: "#{utils.KODING_URL}/-/validate/email"
      type: 'POST'
      data: { email }
      success: resolve
      error: reject

  utils.validators = {
    validateUsername
    validateEmail
    validateTeamName
  }
