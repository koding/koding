kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView
KDLoaderView      = kd.LoaderView
KDSelectBox       = kd.SelectBox
KDView            = kd.View
whoami            = require 'app/util/whoami'
notify_           = require 'app/util/notify_'
KodingSwitch      = require 'app/commonviews/kodingswitch'


module.exports = class AccountEmailNotifications extends KDView

  viewAppended: ->

    @addSubView loader = new kd.LoaderView
      cssClass   : 'AccountEmailNotifications-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25

    whoami().fetchEmailFrequency (err, frequency) =>

      path = kd.singletons.router.getCurrentPath()

      if path.search("unsubscribe") > -1
        globalFlag  = no
        frequency.global = globalFlag
        notify_ 'You are unsubscribed from all email notifications.'
      else
        globalFlag = frequency.global

      @putContents frequency or {}
      @switched 'global', globalFlag
      @handleGlobalState frequency.global
      loader.destroy()

    @on 'EmailPrefSwitched', (flag, state) => @["handle#{flag.capitalize()}State"]? state


  handleGlobalState: (state) ->

    @handleDependency ['marketing'], state


  putContents: (frequency) ->

    @fields = fields =
      global              :
        title             : 'Send me email notifications'
      marketing           :
        title             : 'When Koding has member updates <small>Like VM security updates, privacy updates, inactive account notices, offers and campaigns.</small>'

    view = this

    @addSubView @list = new KDCustomHTMLView
      tagName : 'ul'
      cssClass: 'AppModal--account-switchList'

    for own flag, field of fields

      return @["#{flag}FieldAdded"]? frequency[flag]  if field.title is null or field.title is ""

      @list.addSubView field.formView = new KDCustomHTMLView tagName : 'li'

      title = new KDCustomHTMLView
        partial  : field.title
        cssClass : "title"

      fields[flag].switch = fieldSwitch = new KodingSwitch
        defaultValue  : frequency[flag]
        callback      : (state) -> view.switched @getData(), state
      , flag

      fields[flag].loader = new KDLoaderView
        cssClass      : 'email-on-off-loader'
        size          : width : 12
        loaderOptions : color : "#FFFFFF"

      field.formView.addSubView fieldSwitch
      field.formView.addSubView title
      fields[flag].formView.addSubView fields[flag].loader

      @["#{flag}FieldAdded"]? frequency[flag]


  switched: (flag, state) ->

    prefs       = {}
    prefs[flag] = state

    @fields[flag].loader.show()
    @emit 'EmailPrefSwitched', flag, state

    whoami().setEmailPreferences prefs, (err) =>
      return @fields[flag].loader.hide()  unless err

      @emit 'EmailPrefSwitched', flag, !state
      notify_ 'Failed to change state'


  handleDependency: (items, state) ->

    items.forEach (item) =>

      method = if state
      then 'unsetClass'
      else 'setClass'

      field = @fields[item]

      field.formView[method]      'off'
      field.subSettings?[method]  'off'  # Toggle it on / off if current field has any sub settings
