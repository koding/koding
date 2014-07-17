class NavigationVMItem extends KDListItemView

  constructor:(options = {}, data)->

    vm                 = data
    @alias             = vm.hostnameAlias.replace 'koding.kd.io', 'kd.io'
    path               = KD.utils.groupifyLink "/IDE/VM/#{@alias}"

    options.tagName    = 'a'
    options.type     or= 'main-nav'
    options.cssClass   = 'vm'
    options.attributes =
      href             : path
      # title            : "Go to your VM #{@alias}"

    super options, data


  click: (event) ->

    return yes  if event.target.tagName.toLowerCase() isnt 'span'

    KD.utils.stopDOMEvent event

    list = @getDelegate()
    list.emit 'VMCogClicked', @getData()




  partial: -> return "<figure></figure>#{@alias}<span></span>"


