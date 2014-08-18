class ActivityInputHelperView extends KDCustomHTMLView

  helpMap      =
    mysql      :
      niceName : 'MySQL'
      tooltip  :
        title  : 'Open your terminal and type <code>help mysql</code>'
    phpmyadmin :
      niceName : 'phpMyAdmin'
      tooltip  :
        title  : 'Open your terminal and type <code>help phpmyadmin</code>'
    "vm size"  :
      pattern  : 'vm\\ssize|vm\\sconfig'
      niceName : 'VM config'
      tooltip  :
        title  : 'Open your terminal and type <code>help specs</code>'
    "vm down"  :
      pattern  : 'vm\\sdown|vm\\snot\\sworking|vm\\sis\\snot\\sworking'
      niceName : 'non-working VM'
      tooltip  :
        title  : 'You can go to your environments and try to restart your VM'
    help       :
      niceName : 'Help!!!'
      tooltip  :
        title  : "You don't need to type help in your post, just ask your question."
    wordpress  :
      niceName : 'WordPress'
      link     : 'http://learn.koding.com/?s=wordpress'


  constructor: (options = {}, data) ->

    options.cssClass  ?= 'help-container hidden'
    options.partial   ?= 'Need help with:'

    super options, data

    @currentHelperNames = []


  getPattern: ->
    helpKeys = Object.keys helpMap
    ///#{(helpMap[key].pattern or key for key in helpKeys).join('|')}///gi


  checkForCommonQuestions: KD.utils.throttle 200, (val)->

    @hideAllHelpers()

    pattern = @getPattern()
    match   = pattern.exec val
    matches = []
    while match isnt null
      matches.push match[0] if match
      match = pattern.exec val

    @addHelper keyword for keyword in matches


  addHelper: (val) ->

    @show()

    unless helpMap[val.toLowerCase()]
      for own key, item of helpMap when item.pattern
        if ///#{item.pattern}///i.test val
          val = key
          break

    return if val in @currentHelperNames

    {niceName, link, tooltip} = helpMap[val.toLowerCase()]

    Klass     = KDCustomHTMLView
    options   =
      tagName : 'span'
      partial : niceName

    if tooltip
      options.tooltip           = _.extend {}, tooltip
      options.tooltip.cssClass  = 'activity-helper'
      options.tooltip.placement = 'bottom'

    if link
      Klass           = CustomLinkView
      options.tagName = 'a'
      options.title   = niceName
      options.href    = link or '#'
      options.target  = if link?[0] isnt '/' then '_blank' else ''

    @addSubView new Klass options
    @currentHelperNames.push val


  hideAllHelpers:->

    @hide()
    @destroySubViews()
    @currentHelperNames = []


