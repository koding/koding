globals = require 'globals'
nicetime = require './util/nicetime'
notify_ = require './util/notify_'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
CustomLinkView = require './customlinkview'
JView = require './jview'


module.exports = class GlobalNotificationView extends JView

  constructor:->

    super

    @close = new CustomLinkView
      title      : ''
      icon       :
        cssClass : 'close'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        @hideAndDestroy()

    @bindTransitionEnd()

    {scheduledAt, closeTimer} = @getData()

    scheduledAt = (new Date(scheduledAt)).getTime()

    if closeTimer and typeof closeTimer is 'number'
      kd.utils.wait closeTimer, @bound 'hideAndDestroy'

    @timer = new KDCustomHTMLView
      tagName  : 'strong'
      cssClass : if @getOption 'showTimer' then 'hidden'
      partial  : @timerPartial scheduledAt

    @repeater = kd.utils.repeat 2000, =>
      @timer.updatePartial @timerPartial scheduledAt
      kd.utils.killRepeat @repeater  if Date.now() > scheduledAt

    if 'admin' in globals.config.roles and @getData().bongo_
      @adminClose = new KDButtonView
        tagName  : 'span'
        cssClass : 'solid red mini cancel'
        title    : 'ADMIN: Cancel Notification'
        callback : =>
          @getData().cancel (err)=>
            if err then notify_ err
            else @hideAndDestroy()
    else
      @adminClose = new KDCustomHTMLView

    @getData().on? 'restartCanceled', =>
      kd.log 'remove active restart message ::realtime::'
      @hideAndDestroy()

  hideAndDestroy:->
    @once 'transitionend', @bound 'destroy'
    @hide()

  destroy:->

    kd.utils.killRepeat @repeater
    super


  timerPartial:(time)-> "#{nicetime (time - Date.now()) / 1000}."

  show:-> @setClass 'in'

  hide:-> @unsetClass 'in'

  pistachio:->
    """
    <div>
    {{ #(title)}} {{> @timer}} {cite{ #(content)}}
    {{> @close}}{{> @adminClose}}
    </div>
    """
