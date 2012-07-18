page_demoNotification = (parentView)->

  parentView.addSubView header = new KDHeaderView type : "big", title : "KD Notifications Demo"

  top = new KDView
    cssClass : "generic-content-box"
  parentView.addSubView top

  buttonModal = new KDButtonView
    title       : "Create Modal"
    callback    : ()->
      new KDModalView
        title   : "Are you sure?"
        content : "Are you sure to login, there is no way back!"
        overlay : yes

  buttonNotification = new KDButtonView
    title       : "Show a Notification"
    callback    : ()->
      new KDNotificationView
        type    : "main"
        title   : "Ooops."
        content : "Something weird happened"
        duration: 0
        overlay : yes

  buttonNotificationTray = new KDButtonView
    title       : "Tray Notification"
    callback    : ()->
      new KDNotificationView
        type    : "tray"
        title   : "Hey!"
        content : "This is a tray notification"

  buttonNotificationGrowl = new KDButtonView
    title       : "Growl Notification"
    callback    : ()->
      new KDNotificationView
        type      : "growl"
        title     : "Helloo!"
        content   : "This is a growl notification, As in Ruby, switch statements</br> in CoffeeScript can take multiple values for each when</br> clause. If any of the values match, the clause</br> runs."
        duration  : 10000
        showTimer : yes

  labelSelect = new KDLabelView
    title : "Select notification type:"

  selectSample = new KDInputView
    type          : "select"
    label         : labelSelect
    defaultValue  : "growl"
    selectOptions : [
      {
        title : "Standard Notification"
        value : "tray"
      },{
        title : "Tray Notification"
        value : "tray"
      },{
        title : "Growl Notification"
        value : "growl"
      }
    ]

  top.addSubView buttonModal
  top.addSubView labelSelect
  top.addSubView selectSample
  top.addSubView buttonNotification
  top.addSubView buttonNotificationTray
  top.addSubView buttonNotificationGrowl