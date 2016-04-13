kd                      = require 'kd'
sectionize              = require '../commons/sectionize'
headerize               = require '../commons/headerize'
HomeStacksCreate        = require './homestackscreate'
HomeStacksTeamStacks    = require './homestacksteamstacks'
HomeStacksPrivateStacks = require './homestacksprivatestacks'
HomeStacksDrafts        = require './homestacksdrafts'

EnvironmentFlux         = require 'app/flux/environment'


module.exports = class HomeStacks extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    kd.singletons.mainController.ready =>

      EnvironmentFlux.actions.loadTeamStackTemplates()
      EnvironmentFlux.actions.loadPrivateStackTemplates()

      @wrapper.addSubView new HomeStacksCreate

      @wrapper.addSubView headerize 'Team Stacks'
      @wrapper.addSubView sectionize 'Team Stacks', HomeStacksTeamStacks

      @wrapper.addSubView headerize 'Private Stacks'
      @wrapper.addSubView sectionize 'Private Stacks', HomeStacksPrivateStacks

      @wrapper.addSubView headerize 'Drafts'
      @wrapper.addSubView sectionize 'Drafts', HomeStacksDrafts
