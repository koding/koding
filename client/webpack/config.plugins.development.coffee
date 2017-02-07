WebpackNotifierPlugin = require 'webpack-notifier'
{ BundleAnalyzerPlugin } = require 'webpack-bundle-analyzer'

module.exports = ->

  return [

    new WebpackNotifierPlugin
      title: 'Koding Frontend'
      alwaysNotify: yes

    new BundleAnalyzerPlugin
      analyzerMode: 'static'
      reportFilename: 'report.html'
      # change this to true if you want the see the analyze to open
      # automatically on each bundle change. Otherwise you can click to the link
      # on terminal after rebundle.
      openAnalyzer: no

  ]
