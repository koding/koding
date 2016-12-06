kd         = require 'kd'
sectionize = require '../commons/sectionize'
headerize  = require '../commons/headerize'

HomeIntegrationsGitlab = require './homeintegrationsgitlab'
HomeIntegrationsGithub = require './homeintegrationsgithub'
HomeIntegrationsCustomerFeedback = require './homeintegrationscustomerfeedback'
HomeIntegrationsIntercom = require './homeintegrationsintercomintegration'

module.exports = class HomeIntegrations extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView headerize 'GitHub'
    @wrapper.addSubView sectionize 'GitHub', HomeIntegrationsGithub
    @wrapper.addSubView headerize 'GitLab'
    @wrapper.addSubView sectionize 'GitLab', HomeIntegrationsGitlab
    @wrapper.addSubView headerize 'Intercom'
    @wrapper.addSubView sectionize 'Intercom Integration', HomeIntegrationsIntercom
    @wrapper.addSubView headerize 'Chatlio'
    @wrapper.addSubView sectionize 'Customer Feedback', HomeIntegrationsCustomerFeedback
