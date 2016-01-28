$ = require 'jquery'

module.exports = class Analytics

  request = (path, method, data) ->

    options = { method, data }
    $.ajax "/-/analytics/#{path}", options


  @track: (action, properties) ->

    data = { action, properties }
    request 'track', 'post', data


  @page: (name, category) ->

    properties =
      url      : window.location.toString()
      path     : window.location.pathname
      title    : window.document.title
      referrer : window.document.referrer

    data = { name, category, properties }
    request 'page', 'post', data
