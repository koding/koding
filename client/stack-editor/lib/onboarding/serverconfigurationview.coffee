kd                    = require 'kd'
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
        row = new kd.CustomHTMLView { cssClass: "row #{service}" }

        do (service, config) =>

          row.addSubView checkbox = new kd.CustomCheckBox
            name         : service
            package      : config.package
            command      : config.command
            defaultValue : no
            click        : =>
              @emit 'StackDataChanged'
              @emit 'HiliteTemplate', 'line', config.package


          row.addSubView new kd.CustomHTMLView
            partial  : config.title
            cssClass : 'label'
            click    : =>
              if checkbox.getValue() then checkbox.setValue 0 else checkbox.setValue 1
              @emit 'StackDataChanged'
              @emit 'HiliteTemplate', 'line', config.package

          @configurationToggles.push checkbox
          section.addSubView row

      @addSubView section
