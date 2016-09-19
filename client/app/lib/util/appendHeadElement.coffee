module.exports = ({ type, url }, callback) ->

  kd = require 'kd'

  switch type
    when 'style'
      tagName    = 'link'
      attributes = { rel: 'stylesheet', href: url }
      bind       = 'load'
      load       = -> callback null, { type, url }

    when 'script'
      tagName = 'script'
      attributes = { type: 'text/javascript', src: url }
      bind       = 'load'
      load       = -> callback null, { type, url }

  global.document.head.appendChild (new kd.CustomHTMLView {
    tagName, attributes, bind, load
  }).getElement()
