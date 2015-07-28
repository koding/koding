kd = require 'kd'


module.exports = ->

    { frontApp } = kd.singletons.appManager

    return frontApp.rtm?.isReady and kd.dom.hasClass document.activeElement, 'collab-chat-input'
