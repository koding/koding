ReactDOM = require 'react-dom'

module.exports = EmojiPreloaderMixin =

  componentDidMount: ->

    element = ReactDOM.findDOMNode this
    element.classList.add 'emoji-sprite-preloader'
