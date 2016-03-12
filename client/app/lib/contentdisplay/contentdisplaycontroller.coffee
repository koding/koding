getFullnameFromAccount = require '../util/getFullnameFromAccount'
remote = require('../remote').getInstance()
kd = require 'kd'
KDController = kd.Controller
ContentDisplay = require './contentdisplay'
getPlainActivityBody = require 'app/util/getPlainActivityBody'
shortenText = require 'app/util/shortenText'


module.exports = class ContentDisplayController extends KDController

  constructor:(options)->

    super

    @displays = {}
    @attachListeners()


  attachListeners:->

    mc         = kd.singleton 'mainController'
    appManager = kd.singleton 'appManager'
    @on "ContentDisplayWantsToBeShown",  (view)=> mc.ready => @showDisplay view
    @on "ContentDisplayWantsToBeHidden", (view)=> mc.ready => @hideDisplay view
    @on "ContentDisplaysShouldBeHidden",       => mc.ready => @hideAllDisplays()
    appManager.on "ApplicationShowedAView",    => mc.ready => @hideAllDisplays()


  showDisplay:(view)->

    tabPane = new ContentDisplay
      name  : 'content-display'
      type  : 'social'
      view  : view

    tabPane.on 'KDTabPaneInactive', => @hideDisplay view

    @displays[view.id] = view

    {@mainTabView} = kd.singleton "mainView"
    @mainTabView.addPane tabPane

    model = view.getData()
    @changePageTitle model

    return tabPane


  changePageTitle:(model)->

    return  unless model

    {JAccount, SocialMessage, JGroup} = remote.api
    title = switch model.constructor
      when JAccount          then  getFullnameFromAccount model
      when SocialMessage     then  getPlainActivityBody model
      when JGroup            then  model.title
      else "#{model.title}#{getSectionName model}"

    shortenText title, maxLength : 100 # max char length of the title

    kd.singletons.router.setPageTitle title


  hideDisplay:(view)->

    # KD.getSingleton('router').back()
    tabPane = view.parent
    @destroyView view
    @mainTabView.removePane tabPane  if tabPane


  hideAllDisplays:(exceptFor)->

    displayIds =\
      if exceptFor?
      then (id for own id,display of @displays when exceptFor isnt display)
      else (id for own id,display of @displays)

    return if displayIds.length is 0

    lastId = displayIds.pop()
    @destroyView @displays[id] for id in displayIds

    @hideDisplay @displays[lastId]


  destroyView:(view)->

    @emit 'DisplayIsDestroyed', view
    delete @displays[view.id]
    view.destroy()
