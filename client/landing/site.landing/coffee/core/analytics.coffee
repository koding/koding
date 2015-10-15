module.exports = class Analytics

  request = (path, method, data) ->

    options = { method, data }
    $.ajax "/-/analytics/#{path}", options


  @track: (action, properties) ->

    data = { action, properties }
    request 'track', 'post', data
