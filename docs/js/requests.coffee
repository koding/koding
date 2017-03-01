---
---

utils = window.KODING_UTILS ?= {}
utils.KODING_URL = \
  {% if jekyll.environment == 'production' %}'https://koding.com'{% else %}'http://dev.koding.com:8090'{% endif %}

do ->

  intercomSupport = -> new Promise (resolve, reject) ->
    $.ajax
      url: "#{utils.KODING_URL}/-/intercomlauncher"
      type: 'GET'
      success: resolve
      error: reject

  getPermission = -> new Promise (resolve, reject) ->
    $.ajax
      url: "#{utils.KODING_URL}/-/teams/allow"
      type: 'POST'
      success: resolve
      error: reject

  createTeam = (data) -> new Promise (resolve, reject) ->
    $.ajax
      url: "#{utils.KODING_URL}/-/teams/create"
      data: data
      type: 'POST'
      success: resolve
      error: reject

  utils.requests = {
    intercomSupport
    getPermission
    createTeam
  }
