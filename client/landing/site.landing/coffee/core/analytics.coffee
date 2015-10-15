module.exports = class Analytics

  request = (path, method, data) ->

    options = { method, data }
    $.ajax "/-/analytics/#{path}", options
