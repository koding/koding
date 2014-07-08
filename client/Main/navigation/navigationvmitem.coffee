class NavigationVMItem extends KDListItemView

  constructor:(options = {}, data)->

    vm                 = data
    @alias             = vm.hostnameAlias.replace 'koding.kd.io', 'kd.io'
    path               = KD.utils.groupifyLink "/IDE/#{@alias}"

    options.tagName    = 'a'
    options.type     or= 'main-nav'
    options.cssClass   = 'vm'
    options.attributes =
      href             : path
      title            : "Go to your VM #{@alias}"

    super options, data


  click : ->

    # @emit 'VMItemClicked', @getData()
    @setClass 'running'


  partial: ->

    return "<figure></figure>#{@alias}"

