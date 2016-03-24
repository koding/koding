kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
globals = require 'globals'

module.exports = (name) ->

  # resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

  # if appManifest.devMode # TODO: change url to https when vm urls are ready for it
  #   resourceRoot = "http://#{KD.getSingleton('vmController').defaultVm}/.applications/#{utils.slugify name}/"


  # for size in [64, 128, 160, 256, 512]
  #   if icns and icns[String size]
  #     thumb = "#{resourceRoot}/#{icns[String size]}"
  #     break

  image  = if name is 'Ace' then 'icn-ace' else 'default.app.thumb'
  thumb  = "#{globals.config.apiUri}/a/images/#{image}.png"

  img = new KDCustomHTMLView
    tagName     : 'img'
    bind        : 'error'
    error       : ->
      @getElement().setAttribute 'src', '/a/images/default.app.thumb.png'
    attributes  :
      src       : thumb

  return img
