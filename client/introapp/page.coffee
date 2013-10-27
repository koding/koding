class Page extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'kd-page', options.cssClass
    super options, data

  viewAppended:->
    super

    @addSubView title = new KDCustomHTMLView
      partial : @getOptions().content

    title.setStyle
      position   : 'absolute'
      marginLeft : '-80px'
      marginTop  : '-15px'
      color      : 'white'
      fontSize   : '30px'
      top        : '50%'
      left       : '50%'
