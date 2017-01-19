---
---

window.KODING_UTILS ?= {}

do ->

  utils = window.KODING_UTILS

  { bindLegendEvents, bindPasswordEvents, bindSubmitHandler
    cleanupErrors, contains, queryAll, slugify, makeError, getFormData
    repeat, wait, toLowerCase, setButtonLoading, showError, setAutosize
    KODING_URL, KODING_URL_PREFIX, KODING_URL_SUFFIX
  } = utils

  { FORM_SELECTOR, INPUT_SELECTOR, SUBMIT_SELECTOR
    PASSWORD_SELECTOR, TEAMNAME_SELECTOR, USERNAME_SELECTOR
  } = utils.signup

  # make sure form is on the page
  timer = repeat 200, ->
    # wait until form fields are put, hubspot puts them in lazily
    if queryAll(INPUT_SELECTOR).length >= 3
      formReady()
      clearInterval timer

  textareas = queryAll(FORM_SELECTOR)
  setAutosize textareas  if textareas.length

  formReady = ->

    bindLegendEvents INPUT_SELECTOR
    bindPasswordEvents PASSWORD_SELECTOR

    bindSubmitHandler (event) ->

      return  unless contains 'SignupForm', event.target

      event.stopPropagation()
      event.preventDefault()

      $form         = $(FORM_SELECTOR)
      $password     = $form.find(PASSWORD_SELECTOR)
      $teamName     = $form.find(TEAMNAME_SELECTOR)
      $username     = $form.find(USERNAME_SELECTOR)
      $submitButton = $form.find(SUBMIT_SELECTOR)

      # cleanup custom errors.
      cleanupErrors [ $teamName, $password, $username ]

      formData = utils.getFormData $form
      formData.companyName = formData.team_url or ''
      formData.slug = slugify(formData.companyName)
      formData.agree = 'on'
      formData.passwordConfirm = formData.password

      {
        getSuggestedTeamNameError, getTeamNameNotAvailableError
        getTeamNameUserNameError, getPasswordError, getEmailError
      } = utils.errors

      setButtonLoading $submitButton, true

      username = formData.username or formData.koding_username
      username = toLowerCase username

      if (formData.username or formData.koding_username) is formData.slug
        showError $teamName, getTeamNameUserNameError()
        return setButtonLoading $submitButton, no

      onValidateUsernameFail = (err) ->

        if err.decoratedMessage
        then showError $username, err.message
        else showError $username, getTeamNameUserNameError()

        throw new Error JSON.stringify err, null, 2

      onValidateTeamNameFail = (err) ->
        if err.decoratedMessage
        then showError $teamName, err.message
        else showError $teamName, getTeamNameNotAvailableError()

        throw new Error JSON.stringify err, null, 2

      onCreateTeamFail = (err) ->
        { responseText: res, status } = err
        switch
          when status is 403
            errorResponse = JSON.parse(res)
            $teamName.val(errorResponse.suggested).change()
            showError $teamName, getSuggestedTeamNameError(errorResponse.suggested, formData.slug)

          when status is 400 and res is 'Access denied!'
            showError $password, getPasswordError()

          when status is 400 and /access is blocked/.test(res)
            showError $password, makeError res

          when status is 400 and /Unknown user/.test(res)
            showError $username, makeError 'Unknown username'

          else
            message = '''
              There is a problem with the information you entered, please
              update and resend the form.
            '''
            showError($teamName, message)

        throw new Error JSON.stringify err, null, 2


      onCreateTeamSuccess = ({ token }) ->
        url = "#{KODING_URL_PREFIX}#{formData.slug}#{KODING_URL_SUFFIX}"
        url += if token then "/-/loginwithtoken?token=#{token}" else '/Login'
        return location.replace url

      { validateTeamName, validateUsername } = utils.validators
      { getPermission, createTeam } = utils.requests

      getPermission()
        .then -> validateUsername(username, async: no).catch(onValidateUsernameFail)
        .then -> validateTeamName(formData.slug).catch(onValidateTeamNameFail)
        .then -> createTeam(formData).catch(onCreateTeamFail)
        .then(onCreateTeamSuccess)
        .catch -> setButtonLoading $submitButton, false

      return false
