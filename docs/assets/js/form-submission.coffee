window.KODING_UTILS ?= {}

KODING_UTILS.submitForm = (options) ->

  options.formSelector ?= null
  options.resultSelector ?= null
  options.referrerSelector ?= null
  options.formHash ?= null

  if options.referrer
    $(options.referrer).val document.referrer

  $(options.formSelector).submit (event) ->

    event.preventDefault()
    $form = $ this

    hostname = {% if jekyll.environment == 'production' %}'https://koding.com'{% else %}'http://dev.koding.com:8090'{% endif %}
    FORM_URL = "#{hostname}/-/wufoo/submit/#{options.formHash}"
    data     = $(this).serializeArray()

    $.ajax
      type : 'POST'
      url  : FORM_URL
      data : data
      success: options.success or () ->
        $form.addClass 'hidden'
        $(options.referrerSelector).removeClass 'hidden'
      error: options.error or ({responseText}) ->
        try
          responseText = JSON.parse responseText
        catch e
          console.log 'couldn\'t parse the response'

        console.log responseText

    return no
