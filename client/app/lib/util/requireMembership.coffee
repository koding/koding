isLoggedIn = require './isLoggedIn'
notify_ = require './notify_'
kd = require 'kd'
globals = require 'globals'
joinGroup_ = require './joinGroup_'

module.exports = (options = {}) ->

  { callback, onFailMsg, onFail, silence, tryAgain, groupName } = options
  unless isLoggedIn()
    # if there is fail message, display it
    if onFailMsg
      notify_ onFailMsg, 'error'

    # if there is fail method, call it
    onFail?()

    # if it's not a silent operation redirect
    unless silence
      kd.getSingleton('router').handleRoute '/Login',
        entryPoint : globals.config.entryPoint

    # if there is callback and we want to try again
    if callback? and tryAgain
      unless kd.lastFuncCall
        kd.lastFuncCall = callback

        mainController = kd.getSingleton('mainController')
        mainController.once 'accountChanged.to.loggedIn', ->
          if isLoggedIn()
            kd.lastFuncCall?()
            kd.lastFuncCall = null
            if groupName
              joinGroup_ groupName, (err) ->
                return notify_ "Joining #{groupName} group failed", 'error'  if err
  else if groupName
    joinGroup_ groupName, (err) ->
      return notify_ "Joining #{groupName} group failed", 'error'  if err
      callback?()
  else
    callback?()
