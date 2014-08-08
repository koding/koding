class FeederSingleView extends KDCustomHTMLView

  constructor:(options = {})->
    options.cssClass  =  KD.utils.curry 'app-content', options.cssClass

    super options

    # @listenWindowResize()

    # @on "viewAppended", =>
    #   siblings        = @parent.getSubViews()
    #   index           = siblings.indexOf @
    #   @_olderSiblings = siblings.slice 0,index

  _windowDidResize:->

    # offset = 0
    # offset += olderSibling.getHeight() for olderSibling in @_olderSiblings
    # newH = @parent.getHeight() - offset
    # @setHeight newH

    # width = @getWidth()
    # @unsetClass "extra-wide wide medium narrow extra-narrow"

    # @setClass if width > 1200            then "extra-wide"
    # else if width < 1200 and width > 900 then "wide"
    # else if width < 900 and width > 600  then "medium"
    # else if width < 600 and width > 300  then "narrow"
    # else                                      "extra-narrow"
