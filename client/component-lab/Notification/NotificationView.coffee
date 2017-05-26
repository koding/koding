React = require 'app/react'
kd = require 'kd'
Button = require 'lab/Button'
Box = require 'lab/Box'

classnames  = require 'classnames'
styles = require './Notification.stylus'
Helpers = require './helpers'
Constants = require './constants'


module.exports = class NotificationView extends React.Component

  constructor: (props) ->

    super props
    @notificationTimer = null
    @removeCount = 0
    @state =
      removed : no


  hideNotification: ->

    @notificationTimer.clear()  if @notificationTimer
    @setState { removed : yes }
    @removeNotification()


  removeNotification: ->

    @props.onRemove @props.notification.uid


  dismiss: ->

    @hideNotification()  if @props.notification.dismissible


  autoDismissible: (notification) ->

    { dismissible, primaryButtonTitle, secondaryButtonTitle} = notification
    not dismissible and not primaryButtonTitle and not secondaryButtonTitle


  componentDidMount: ->

    notification = @props.notification

    if @autoDismissible notification
      @notificationTimer = new Helpers.Timer =>
        @hideNotification()
      , notification.duration


  handleMouseEnter: ->

    if @autoDismissible @props.notification
      @notificationTimer.pause()


  handleMouseLeave: ->

    if @autoDismissible @props.notification
      @notificationTimer.resume()


  handlePrimaryButtonClick: (event) ->

    event.preventDefault()
    notification = @props.notification
    @hideNotification()
    if typeof notification.onPrimaryButtonClick is 'function'
      notification.onPrimaryButtonClick()


  handleSecondaryButtonClick: (event) ->

    event.preventDefault()
    notification = @props.notification
    @hideNotification()
    if typeof notification.onSecondaryButtonClick is 'function'
      notification.onSecondaryButtonClick()


  render: ->

    notification = @props.notification
    className = classnames [
      styles.kd_notification
      styles["kd_notification_#{notification.type}"]
      styles.kd_notification_dismissible if notification.dismissible and not notification.primaryButtonTitle and not notification.secondaryButtonTitle
    ]
    iconClass = classnames [
      styles.kd_notification_icon
      styles["kd_notification_icon_#{notification.type}"]
    ]
    message = notification.content
    <div
      className={className}
      onMouseEnter={@bound 'handleMouseEnter'}
      onMouseLeave={@bound 'handleMouseLeave'}>
      {
        if notification.type isnt 'default'
          <Box className={styles.kd_notification_level}>
            <i className={iconClass}></i>
          </Box>
      }
      <div className={styles.kd_notification_content}>
        {message}
      </div>
      {
        if notification.dismissible
          <CloseButton onClick={@bound 'dismiss'} />
      }
      {
        if notification.primaryButtonTitle or notification.secondaryButtonTitle
          <Actions
            notification={notification}
            onPrimaryButtonClick={@bound 'handlePrimaryButtonClick'}
            onSecondaryButtonClick={@bound 'handleSecondaryButtonClick'} />
      }
    </div>

  @propTypes :
    notification : React.PropTypes.object
    onRemove : React.PropTypes.func

  @defaultProps =
    onRemove: kd.noop


CloseButton = ({onClick}) ->

  <button
    className={styles.kd_notification_close}
    onClick={onClick}>
      &times;
  </button>


ActionButton = (options) ->

  {type, title, onClick} = options
  <div className={styles.kd_notification_action}>
    <Button
      type={type}
      size="medium"
      onClick={onClick}>
      {title}
    </Button>
  </div>


Actions = (options) ->

  {notification, onPrimaryButtonClick, onSecondaryButtonClick} = options
  actionsClass = if not notification.secondaryButtonTitle
  then styles.kd_notification_single_action
  else styles.kd_notification_multiple_actions
  <div className={styles.kd_notification_actions}>
    <div className={actionsClass}>
      {
        if notification.primaryButtonTitle
          <ActionButton
            type={"link-#{Constants.types[notification.type]}"}
            title={notification.primaryButtonTitle}
            onClick={onPrimaryButtonClick} />
      }
      {
        if notification.secondaryButtonTitle
          <ActionButton
            type="link-secondary"
            title={notification.secondaryButtonTitle}
            onClick={onSecondaryButtonClick} />
      }
    </div>
  </div>
