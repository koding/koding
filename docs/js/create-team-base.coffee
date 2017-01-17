---
---

window.KODING_UTILS ?= {}

do ->
  { KODING_UTILS: utils } = window

  utils.KODING_URL = \
    {% if jekyll.environment == 'production' %}'https://koding.com'{% else %}'http://dev.koding.com:8090'{% endif %}

  utils.KODING_URL_PREFIX = \
    {% if jekyll.environment == 'production' %}'https://'{% else %}'http://'{% endif %}

  utils.KODING_URL_SUFFIX = \
    {% if jekyll.environment == 'production' %}'.koding.com'{% else %}'.dev.koding.com:8090'{% endif %}

  utils.repeat = (delay, fn) -> setInterval fn, delay
  utils.wait = (delay, fn) -> setTimeout fn, delay

  utils.queryAll = document.querySelectorAll.bind document
  utils.forEach = (collection, fn) -> Array::forEach.call collection, fn

  utils.setAutosize = (textareas) ->
    return  unless autosize?
    utils.forEach textareas, (t) -> t.setAttribute 'rows', 1
    autosize textareas

  utils.signup = signup =
    FORM_SELECTOR     : '#SignupForm'
    INPUT_SELECTOR    : '#SignupForm input'
    TEXTAREA_SELECTOR : '#SignupForm textarea'
    PASSWORD_SELECTOR : 'input[name=password]'
    TEAMNAME_SELECTOR : 'input[name=team_url]'
    USERNAME_SELECTOR : 'input[name=username]'
    EMAIL_SELECTOR    : 'input[name=email]'
    SUBMIT_SELECTOR   : '#SignupForm button'

  utils.STRENGTH_MAP = ['weak', 'mediocre', 'good', 'strong', 'very-strong']

  utils.isValidEmail = (email) ->
    re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test email

  utils.setButtonLoading = ($button, isLoading) ->

    if isLoading
    then $button.val('CREATING YOUR TEAM...').css 'opacity', '0.5'
    else $button.val('GET STARTED').css 'opacity', '1'

  utils.makeError = (messages) ->
    messages = [messages]  unless Array.isArray messages

    makeSingleError = (msg) -> "<li><label>#{msg}</label></li>"

    markup = """
      <ul class="errors" style="display:block;">
        #{messages.map(makeSingleError).join ''}
      </ul>
    """

    return $(markup)

  utils.cleanupErrors = ($errors) ->
    $errors.forEach ($error) ->
      $error.removeClass('invalid error')
        .parent()
        .parent()
        .find('.errors')
        .remove()

  utils.showError = ($el, msg) ->

    msg = utils.makeError msg  if 'string' is typeof msg

    $el.one 'focus', ->
      utils.cleanupErrors [ $el ]
      return

    $el.parent().find('.errors').remove()
    $el.addClass('invalid error').parent().remove('.errors').append msg


  utils.contains = (selector, target) ->
    formContainer = document.getElementById(selector)
    formContainer?.contains target


  utils.slugify = (text) ->
    return ''  unless text

    text.split(' ')
      .map (word) -> word.trim()
      .filter(Boolean)
      .join '-'


  utils.bindLegendEvents = (selector) ->

    $(selector).on 'focus', (event) ->
      $input = $(event.target)
      $legend = $input.prev()
      return  unless $legend.html()

      $legend.css 'opacity', 1

    $(selector).on 'blur', (event) ->
      $input = $(event.target)
      $legend = $input.prev()
      return  unless $legend.html()

      $legend.css 'opacity', 0

  utils.bindPasswordEvents = (selector) ->

    { STRENGTH_MAP } = utils
    $(selector).on 'keyup', (event) ->
      $legend = $(this).prev()
      strength = $.pwstrength $(selector).val()

      STRENGTH_MAP.forEach (cls) -> $legend.removeClass cls
      $legend.attr 'data-strength', 'Strength: ' + STRENGTH_MAP[strength]

  utils.toLowerCase = (text = '') ->
    text.split(' ')
      .map (word) -> word.trim().toLowerCase()
      .join ''

  # a submit handler works on capture phase.
  utils.bindSubmitHandler = (fn) ->
    document.addEventListener 'submit', fn, yes

  utils.getFormData = ($form) ->
    $form.serializeArray().reduce (acc, { value, name }) ->
      if name in ['firstname', 'lastname']
        name = name.replace('name', 'Name')
      acc[name] = value
      return acc
    , {}
