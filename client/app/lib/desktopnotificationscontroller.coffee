_ = require 'lodash'
kd = require 'kd'
Promise = require 'bluebird'
browserNotifications = require('browser-notifications')(Promise)

###*
 * Makes sure browser notifications are supported.
 *
 * @param {function} callback
 * @param {function|undefined} callback
###
supported = (callback) ->
  return callback  if browserNotifications.isSupported()


###*
 * Makes sure that user has given us permissions to send desktop notifications.
###
permitted = (callback) -> (args...) ->
  browserNotifications
    .requestPermissions()
    .then (isPermitted) ->
      return if isPermitted
      then callback null, args...
      else callback { message: 'Browser notifications are not permitted' }
    .catch (err) -> callback err


module.exports = class DesktopNotificationsController extends kd.Controller

  ###
   * makes sure browser notifications are supported and permitted by user.
   *
   * NOTE: it curries given options object with the result of err from
   * `permitted` helper.
   *
   * @param {object} options
   * @param {string} options.title
   * @param {string} options.message
   * @return {Promise} a promise which will resolve if user clicks to notification.
  ###
  notify: supported permitted (err, options) ->

    # return a promise for caller of this method, both errors and the result of
    # `browserNotifications.send` are reachable via that promise.
    new Promise (resolve, reject) ->
      return reject err  if err

      options = _.assign {}, defaultNotificationOptions, options

      return browserNotifications
        .send options.title, options.message, options.iconUrl
        .then resolve
        .catch reject


defaultNotificationOptions =
  iconUrl: '/a/images/logos/share_logo.png'
  title: ''
  message: ''

