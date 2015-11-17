kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDSlidePageView = kd.SlidePageView
JView = require './jview'


module.exports = class HelpPage extends KDSlidePageView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'help-page', options.cssClass

    super options, data

  addLinks:(links)->

    links.forEach (link)=>
      target = if link.command then '' else " target='_blank'"
      options =
        tagName : 'li'
        partial : "<a href='#{link.url}'#{target}>#{link.title}</a>"

      if link.command
        options.click = (event)=>
          kd.utils.stopDOMEvent event

          kd.singletons.appManager.require 'Terminal',(app)=>
            @getDelegate().emit 'InternalLinkClicked', link
            kd.utils.wait 500, =>
              kd.singletons.router.handleRoute link.url
              kd.singletons.appManager.tell 'Terminal', 'runCommand', link.command

      @addSubView (new KDCustomHTMLView options), 'ul'

  pistachio:->
    """
      {h3{#(title)}}
      <ul></ul>
    """
