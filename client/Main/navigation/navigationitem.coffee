class NavigationItem extends JTreeItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.type or= 'main-nav'

    super options, data


    data  = @getData()
    @type = data.type

    if data.jMachine
      @type  = 'machine'
      @setClass 'machine'
      @child = new NavigationMachineItem {}, data
    else if data.type is 'title'
      @setClass 'sub-title'
      @child = new KDCustomHTMLView tagName : 'h3', partial : data.title
    else if data.type is 'workspace'
      @setClass 'workspace'
      @child = new KDCustomHTMLView
        partial : """
          <figure></figure>
          <a href='#{KD.utils.groupifyLink data.href}'>#{data.title}</a>
          """
    else if data.type is 'app'
      @setClass 'app'
      @child = new KDCustomHTMLView
        partial : """
          <figure></figure>
          <a href='#{KD.utils.groupifyLink data.href}'>#{data.title}</a>
          """


  pistachio: ->

    """
    <cite></cite>{{> @child}}
    """