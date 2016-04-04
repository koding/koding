kd                      = require 'kd'
HomeStacksCreate        = require './homestackscreate'
HomeStacksTeamStacks    = require './homestacksteamstacks'
HomeStacksPrivateStacks = require './homestacksprivatestacks'
HomeStacksDrafts        = require './homestacksdrafts'

EnvironmentFlux = require 'app/flux/environment'


SECTIONS =
  'Team Stacks'    : HomeStacksTeamStacks
  'Private Stacks' : HomeStacksPrivateStacks
  'Drafts'         : HomeStacksDrafts


header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title


section = (name) ->
  new (SECTIONS[name] or kd.View)
    tagName  : 'section'
    cssClass : "HomeAppView--section #{kd.utils.slugify name}"


module.exports = class HomeStacks extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    kd.singletons.mainController.ready =>

      EnvironmentFlux.actions.loadTeamStackTemplates()
      EnvironmentFlux.actions.loadPrivateStackTemplates()

      @wrapper.addSubView header 'Team Stacks'
      @wrapper.addSubView section 'Team Stacks'

      @wrapper.addSubView header 'Private Stacks'
      @wrapper.addSubView section 'Private Stacks'

      @wrapper.addSubView header 'Drafts'
      @wrapper.addSubView section 'Drafts'
