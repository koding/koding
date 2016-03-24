_  = require 'lodash'
kd = require 'kd'

###*
 * Makes sure browser notifications are supported.
 * @return {bool}
###
isSupported = -> !!window.Notification


###*
 * Makes sure that user has given us permissions to send desktop notifications.
 *
 * @param {Function} callback - to be called with err, and args object.
 * @return {Function}
###
isPermitted = (callback) ->
  if Notification.permission is 'granted'
    callback()
  else if Notification.permission is 'default'
    Notification.requestPermission (permission) ->
      callback()  if permission is 'granted'


defaultOptions =
  title   : ''
  message : ''
  route   : '/'
  timeout : 4000
  iconUrl : '/a/images/logos/notify_logo.png'


module.exports = class DesktopNotificationsController extends kd.Controller

  ###
   *
   * @param {Object} options
   * @param {String} options.title
   * @param {String} options.icon
   * @param {String} options.message
   * @param {Function} options.onClick
  ###
  notify: (options) ->

    return unless  isSupported()
    isPermitted ->
      options      = _.assign {}, defaultOptions, options

      focusToRoute = ->
        window.focus()
        kd.singletons.router.handleRoute options.route

      notification = new Notification options.title, { body: options.message, icon: options.iconUrl }

      notification.onclick = options.onClick or focusToRoute
      setTimeout  ->
        notification.close()
      , options.timeout

