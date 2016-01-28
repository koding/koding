ReactDOM = require 'react-dom'

module.exports = (key) ->

  item        = ReactDOM.findDOMNode key
  clientRect  = item.getBoundingClientRect()

  return {
    top  : clientRect.top
    left : clientRect.width + clientRect.left
  }
