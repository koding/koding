---
---

utils = window.KODING_UTILS ?= {}

do ->

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
    getPermission
    createTeam
  }
