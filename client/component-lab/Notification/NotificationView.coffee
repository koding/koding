_ = require 'lodash'
React = require 'app/react'
ReactDOM = require 'react-dom'
kd = require 'kd'

getVendorTransition = require 'app/util/getVendorTransition'

Button = require '../Button/Button'
Box = require '../Box/Box'

styles = require './Notification.stylus'
Helpers = require './helpers'
Constants = require './constants'


module.exports = class NotificationView extends React.Component

    constructor: (props) ->

      super props
      @_style = { zIndex: 100 + @props.index }
      @_notificationTimer = null
      @_isMounted = no
      @_removeCount = 0
      @state =
        removed : no


    _hideNotification: ->

      @_notificationTimer.clear() if @_notificationTimer
      @setState { removed : yes } if @_isMounted
      @_removeNotification()


    _removeNotification: ->

      @props.onRemove @props.notification.uid


    _dismiss: ->

      @_hideNotification() if @props.notification.dismissible


    _onTransitionEnd: ->

      if @_removeCount == 0 and @state.removed
        @_removeCount++
        @_removeNotification()


    autoDismissible: (notification) ->
      { dismissible, primaryButtonTitle, secondaryButtonTitle} = notification
      not dismissible and not primaryButtonTitle and not secondaryButtonTitle


    componentDidMount: ->

      transitionEvent = getVendorTransition()
      element = ReactDOM.findDOMNode this
      notification = @props.notification
      @_isMounted = yes
      if transitionEvent
        element.addEventListener transitionEvent, @_onTransitionEnd
        if @autoDismissible notification
          @_notificationTimer = new Helpers.Timer =>
            @_hideNotification()
            return
          , notification.duration


    _handleMouseEnter: ->

      if @autoDismissible @props.notification
        @_notificationTimer.pause()


    _handleMouseLeave: ->

      if @autoDismissible @props.notification
        @_notificationTimer.resume()


    _handlePrimaryButtonClick: (event) ->

      event.preventDefault()
      notification = @props.notification
      @_hideNotification()
      if typeof notification.onPrimaryButtonClick is 'function'
        notification.onPrimaryButtonClick()


    _handleSecondaryButtonClick: (event) ->

      event.preventDefault()
      notification = @props.notification
      @_hideNotification()
      if typeof notification.onSecondaryButtonClick is 'function'
        notification.onSecondaryButtonClick()


    componentWillUnmount: ->

      element = ReactDOM.findDOMNode this
      transitionEvent = getVendorTransition()
      element.removeEventListener transitionEvent, @_onTransitionEnd
      @_isMounted = no


    render: ->

      notification = @props.notification
      className = [
        styles.kd_notification
        styles["kd_notification_#{notification.type}"]
      ]
      iconClass = [
        styles.kd_notification_icon
        styles["kd_notification_icon_#{notification.type}"]
      ]
      message = notification.content
      if notification.dismissible
        className.push styles.kd_notification_dismissible
      if notification.primaryButtonTitle or notification.secondaryButtonTitle
        className = className.filter (word) -> word isnt styles.kd_notification_dismissible
      <div
        className={className.join ' '}
        style={@_style}
        onMouseEnter={@bound '_handleMouseEnter'}
        onMouseLeave={@bound '_handleMouseLeave'}>
        {
          if notification.type isnt 'default'
            <Box className={styles.kd_notification_level}>
              <i className={iconClass.join ' '}></i>
            </Box>
        }
        <div className={styles.kd_notification_content}>
          {message}
        </div>
        {
          if notification.dismissible
            <CloseButton onClick={@bound '_dismiss'} />
        }
        {
          if notification.primaryButtonTitle or notification.secondaryButtonTitle
            <Actions
              notification={notification}
              onPrimaryButtonClick={@bound '_handlePrimaryButtonClick'}
              onSecondaryButtonClick={@bound '_handleSecondaryButtonClick'} />
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


ActionButton = ({type, title, onClick}) ->

  <div className={styles.kd_notification_action}>
    <Button
      type={type}
      size="medium"
      onClick={onClick}>
      {title}
    </Button>
  </div>


Actions = ({notification, onPrimaryButtonClick, onSecondaryButtonClick}) ->

  actionsClass = if not notification.secondaryButtonTitle then styles.kd_notification_single_action else styles.kd_notification_multiple_actions
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
