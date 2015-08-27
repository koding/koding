kd                    = require 'kd'
KodingSwitch          = require 'app/commonviews/kodingswitch'
SERVER_CONFIG_OPTIONS = require './serverconfigoptions'


module.exports = class ServerConfigurationView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding server-configuration'

    super options, data

    @configurationToggles = []

    for section, services of SERVER_CONFIG_OPTIONS
      section = new kd.CustomHTMLView
        tagName  : 'section'
        cssClass : "#{section}"
        partial  : "<p>#{section}</p>"

      for service, config of services
        row = new kd.CustomHTMLView cssClass: 'row'

        do (service, config) =>

          row.addSubView kdSwitch = new KodingSwitch
            size         : 'tiny'
            name         : service
            package      : config.package
            command      : config.command
            defaultValue : no
            callback     : => @emit 'UpdateStackTemplate'

          row.addSubView new kd.CustomHTMLView
            partial  : config.title
            cssClass : 'label'
            click    : =>
              if kdSwitch.getValue() then kdSwitch.setOff() else kdSwitch.setOn()
              @emit 'UpdateStackTemplate'

          @configurationToggles.push kdSwitch
          section.addSubView row

      @addSubView section
