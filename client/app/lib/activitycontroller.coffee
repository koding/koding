remote                = require('./remote').getInstance()
whoami                = require './util/whoami'
showErrorNotification = require './util/showErrorNotification'
showNotification      = require './util/showNotification'
kd                    = require 'kd'
KDObject              = kd.Object
KDInputView           = kd.InputView
KDModalView           = kd.ModalView
KDModalViewWithForms  = kd.ModalViewWithForms

module.exports = class ActivityController extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @newItemsCount   = 0
    @flags           = {}
    groupChannel     = null

    { groupsController, appManager, router } = kd.singletons

    groupsController.ready =>
      groupChannel.close().off()  if groupChannel?
      groupChannel = groupsController.groupChannel
      groupChannel.on 'feed-new', (activities) =>
        revivedActivities = (remote.revive activity for activity in activities)
        isOnActivityPage  = router.getCurrentPath() is "/Activity"
        ++@newItemsCount  unless isOnActivityPage

    @on 'ActivityItemBlockUserClicked',         @bound 'openBlockUserModal'
    @on 'ActivityItemMarkUserAsTrollClicked',   @bound 'markUserAsTroll'
    @on 'ActivityItemUnMarkUserAsTrollClicked', @bound 'unmarkUserAsTroll'

  blockUser: (accountId, duration, callback) -> whoami().blockUser accountId, duration, callback

  openBlockUserModal: (nicknameOrAccountId) ->
    @modal = modal = new KDModalViewWithForms
      title                   : "Block User For a Time Period"
      content                 : """
                                <div class='modalformline'>
                                This will block user from logging in to Koding(with all sub-groups).<br><br>
                                You can specify a duration to block user.
                                Entry format: [number][S|H|D|T|M|Y] eg. 1M
                                </div>
                                """
      overlay                 : yes
      cssClass                : "modalformline"
      width                   : 600
      height                  : "auto"
      tabs                    :
        forms                 :
          BlockUser           :
            callback          : =>
              blockingTime = calculateBlockingTime modal.modalTabs.forms.BlockUser.inputs.duration.getValue()
              @blockUser nicknameOrAccountId, blockingTime, (err, res)->
                if err
                  options = userMessage: "You are not allowed to block user!"
                  showErrorNotification err, options
                  modal.modalTabs.forms.BlockUser.buttons.blockUser.hideLoader()
                else
                  showNotification "User is blocked!"

                modal.destroy()

            buttons           :
              blockUser       :
                title         : "Block User"
                style         : "solid light-gray medium"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : -> @hideLoader()
              cancel          :
                title         : "Cancel"
                style         : "solid light-gray medium"
            fields            :
              duration        :
                label         : "Block User For"
                itemClass     : KDInputView
                name          : "duration"
                placeholder   : "e.g. 1Y 1W 3D 2H..."
                keyup         : ->
                  changeButtonTitle @getValue()
                change        : ->
                  changeButtonTitle @getValue()
                validate             :
                  rules              :
                    required         : yes
                    minLength        : 2
                    regExp           : /\d[SHDTMY]+/i
                  messages           :
                    required         : "Please enter a time period"
                    minLength        : "You must enter one pair"
                    regExp           : "Entry should be in following format [number][S|H|D|T|M|Y] eg. 1M"
                iconOptions          :
                  tooltip            :
                    placement        : "right"
                    offset           : 2
                    title            : """
                                       You can enter {#}H/D/W/M/Y,
                                       Order is not sensitive.
                                       """
    form = modal.modalTabs.forms.BlockUser
    form.on "FormValidationFailed", ->
    form.buttons.blockUser.hideLoader()

    changeButtonTitle = (value)->
      blockingTime = calculateBlockingTime value
      button = modal.modalTabs.forms.BlockUser.buttons.blockUser
      if blockingTime > 0
        date = new Date (Date.now() + blockingTime)
        button.setTitle "Block until: #{date.toUTCString()}"
      else
        button.setTitle "Block"


    calculateBlockingTime = (value)->

      totalTimestamp = 0
      unless value then return totalTimestamp
      for val in value.split(" ")
        # this is the first part of blocking time
        # if val 2D then numericalValue will be 2
        numericalValue = parseInt(val.slice(0, -1), 10) or 0
        if numericalValue is 0 then continue
        hour = numericalValue * 60 * 60 * 1000
        # we will get the lastest part of val as time case
        timeCase = val.charAt(val.length-1)
        switch timeCase.toUpperCase()
          when "S"
            totalTimestamp = 1000 # millisecond
          when "H"
            totalTimestamp = hour
          when "D"
            totalTimestamp = hour * 24
          when "W"
            totalTimestamp = hour * 24 * 7
          when "M"
            totalTimestamp = hour * 24 * 30
          when "Y"
            totalTimestamp = hour * 24 * 365

      return totalTimestamp

  unmarkUserAsTroll:(data)->

    kallback = (acc)=>
      acc.markUserAsExempt false, (err, res)->
        if err
          options = userMessage: "You are not allowed to mark this user as a troll"
          showErrorNotification err, options
        else
          showNotification "@#{acc.profile.nickname} won't be treated as a troll anymore!"

    if data.account._id
      remote.cacheable "JAccount", data.account._id, (err, account)->
        kallback account if account
    else if data.bongo_.constructorName is 'JAccount'
      kallback data

  markUserAsTroll:(data)->

    modal = new KDModalView
      title          : "MARK USER AS TROLL"
      content        : """
                       <div class='modalformline'>
                       This is what we call "Trolling the troll" mode.<br><br>
                       All of the troll's activity will disappear from the feeds, but the troll
                       himself will think that people still gets his posts/comments.<br><br>
                       Are you sure you want to mark him as a troll?
                       </div>
                       """
      height         : "auto"
      overlay        : yes
      width          : 475
      buttons        :
        "YES, THIS USER IS DEFINITELY A TROLL" :
          style      : "solid red medium"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            kallback = (acc)=>
              acc.markUserAsExempt true, (err, res)->
                if err
                  options = userMessage: "You are not allowed to mark this user as a troll"
                  showErrorNotification err, options
                else
                  showNotification "@#{acc.profile.nickname} marked as a troll!"

                modal.destroy()

            if data.account._id
              remote.cacheable "JAccount", data.account._id, (err, account)->
                kallback account if account
            else if data.bongo_.constructorName is 'JAccount'
              kallback data
