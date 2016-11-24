---
---

window.KODING_UTILS ?= {}

KODING_UTILS.bindFormSubmission = (options) ->

  options.formSelector ?= null
  options.resultSelector ?= null
  options.referrerSelector ?= null
  options.hideFormOnSuccess ?= yes
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

        if options.hideFormOnSuccess
          $form.addClass 'hidden'
        if options.resultSelector
          $(options.resultSelector).removeClass 'hidden'

      error: options.error or ({responseText}) ->

        try
          responseText = JSON.parse responseText
        catch e
          console.log 'couldn\'t parse the response'

        if responseText
          { FieldErrors } = responseText
          for err in FieldErrors
            $("input[name=#{err.ID}]").addClass 'error'

    return no
