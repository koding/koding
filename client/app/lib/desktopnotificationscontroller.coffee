_ = require 'lodash'
kd = require 'kd'
Promise = require 'bluebird'
browserNotifications = require('browser-notifications')(Promise)

###*
 * Makes sure browser notifications are supported.
 *
 * @param {Function} callback
 * @return {Function|undefined} callback
###
supported = (callback) ->
  return callback  if browserNotifications.isSupported()


###*
 * Makes sure that user has given us permissions to send desktop notifications.
 *
 * @param {Function} callback - to be called with err, and args object.
 * @return {Function}
###
permitted = (callback) ->
  return (args...) ->
    browserNotifications
      .requestPermissions()
      .then (isPermitted) ->
        return if isPermitted
        then callback null, args...
        else callback { message: 'Browser notifications are not permitted' }
      .catch (err) -> callback err


module.exports = class DesktopNotificationsController extends kd.Controller

  ###
   * Makes sure browser notifications are supported and permitted by user.
   *
   * NOTE: it curries given options object with the result of err from
   * `permitted` helper.
   *
   * @param {Object} options
   * @param {String} options.title
   * @param {String} options.message
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

