WebpackNotifierPlugin = require 'webpack-notifier'

module.exports = ->

  return [
    new WebpackNotifierPlugin {
      title: 'Koding Frontend'
      alwaysNotify: yes
    }
  ]
