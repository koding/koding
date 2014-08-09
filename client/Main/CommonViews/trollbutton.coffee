class TrollButtonView extends KDToggleButton

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'troll-button', options.cssClass

    options.states = [
      title    : 'Troll'
      cssClass : 'troll'
      callback : @bound 'troll'
    ,
      title    : 'Untroll'
      cssClass : 'untroll'
      callback : @bound 'untroll'
    ]

    super options, data

    @setState 'Untroll'  if data.isExempt


  troll: ->

    data       = @getData()
    {nickname} = data.profile

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
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            data.markUserAsExempt yes, (err) =>
              return KD.showError err  if err

              modal.destroy()

              new KDNotificationView
                title : "@#{nickname} marked as a troll!"

              @setState 'Untroll'


  untroll: ->

    data       = @getData()
    {nickname} = data.profile

    data.markUserAsExempt no, (err) =>

      return KD.showError err  if err

      new KDNotificationView
        title: "@#{nickname} won't be treated as a troll anymore!"

      @setState 'Troll'
