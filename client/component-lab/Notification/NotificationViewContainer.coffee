React = require 'app/react'
ReactView = require 'app/react/reactview'

NotificationView = require './NotificationView'
FlipMove = require 'react-flip-move'

styles = require './Notification.stylus'

module.exports = class NotificationViewContainer extends ReactView

  constructor: (options = {}, data) ->

    options.appendToDomBody ?= yes
    options.notifications ?= []
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody


  getAnimationProps: ->

      enter :
        from :
          transform : 'scale(0.9)'
          opacity : 0
        to :
          transform : ''
          opacity : ''
      leave :
        from :
          transform : 'scale(1)'
          opacity : 1
        to :
          transform : 'scale(0.9)'
          opacity : 0


  onNotificationRemove: (uid) ->

    @options.onNotificationRemove(uid)


  renderReact: ->

    return <span />  unless @options.notifications.length

    { enter, leave } = @getAnimationProps()
    <div className={styles.kd_notification_list}>
      <FlipMove
        enterAnimation={enter}
        leaveAnimation={leave}>
        {
          @options.notifications.map (notification, index) =>
            <NotificationView
            index={index}
            key={notification.uid}
            notification={notification}
            onRemove={@bound 'onNotificationRemove'} />
        }
      </FlipMove>
    </div>
