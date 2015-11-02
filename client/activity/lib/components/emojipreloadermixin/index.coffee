React = require 'kd-react'

module.exports = EmojiPreloaderMixin =

  componentDidMount: ->

    element = React.findDOMNode this
    element.classList.add 'emoji-sprite-preloader'

