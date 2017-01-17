---
---

utils = window.KODING_UTILS ?= {}

do ->

  { makeError } = utils

  getSuggestedTeamNameError = (suggested, original) ->
    makeError """
      <strong>#{original}</strong> is not available.
      We replaced it with <strong>#{suggested}</strong> for you.
    """

  getTeamNameNotAvailableError = ->
    makeError '''
      Team name is not available. Please try with another one.
    '''

  getTeamNameUserNameError = ->
    makeError '''
      Your username and team name cannot be the same.
    '''

  getPasswordError = ->
    makeError [
      "GivenCredentials does't match!"
      "<a href='#{utils.KODING_URL}/Recover'>Forgot password?</a>"
    ]

  getEmailError = ->
    makeError '''
      Email is taken. Please try another one.
    '''

  utils.errors = {
    getSuggestedTeamNameError
    getTeamNameNotAvailableError
    getTeamNameUserNameError
    getPasswordError
    getEmailError
  }
