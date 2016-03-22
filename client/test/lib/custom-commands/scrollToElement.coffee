exports.command = scrollToElement = (selector, callback) ->

  this
    .execute "document.querySelector('#{selector}').scrollIntoView()"
    .pause   1000, ->
