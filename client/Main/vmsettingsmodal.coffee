class VMSettingsModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title    or= 'Configure Your VM'
    options.cssClass or= 'vm-settings'
    options.content  or= ''
    options.overlay   ?= yes
    options.width     ?= 660
    options.height   or= 'auto'
    options.arrowTop or= no
    options.tabs     or=
      forms            :
        Settings       :
          callback     : @bound 'submit'
          buttons      :
            send       :
              style    : 'message-send solid green'
              type     : 'submit'
              iconOnly : yes
            cancel     :
              title    : 'Nevermind'
              style    : 'transparent'
              callback : @bound 'destroy'
          fields            :
            domain          :
              label         : 'Domain:'
              name          : 'domain'
              type          : 'select'
              defaultValue  : ''
              selectOptions : [
                { title : "1K Call"   ,    value : 1000   }
                { title : "10K Call"  ,    value : 10000  }
                { title : "100K Call" ,    value : 100000 }
              ]

    super options, data

    {appManager, router} = KD.singletons

    if @getOption 'arrowTop'
      @addSubView (new KDCustomHTMLView
        cssClass : 'modal-arrow'
        position :
          top    : @getOption 'arrowTop'
      ), 'kdmodal-inner'


  submit: (formData)->

    log formData

