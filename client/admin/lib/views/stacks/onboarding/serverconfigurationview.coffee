kd             = require 'kd'
KodingSwitch   = require 'app/commonviews/kodingswitch'
CONFIG_OPTIONS =
  Database     :
    mysql      : title: 'MySQL',    package: 'mysql',       command: 'service mysql start'
    redis      : title: 'Redis',    package: 'redis',       command: ''
    mongodb    : title: 'Mongo DB', package: 'mongodb',     command: ''
    postgre    : title: 'Postgre',  package: 'postgre-sql', command: ''
    sqlite     : title: 'SQLite',   package: 'sqlite',      command: ''
  Language     :
    node       : title: 'Node.js',  package: 'node',        command: ''
    ruby       : title: 'Ruby',     package: 'ruby',        command: ''
    python     : title: 'Python',   package: 'python',      command: ''
    php        : title: 'PHP',      package: 'php',         command: ''
  'Web Server' :
    apache     : title: 'Apache',   package: 'apache',      command: ''
    nginx      : title: 'Nginx',    package: 'nginx',       command: 'nginx start'


module.exports = class ServerConfigurationView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding server-configuration'

    super options, data

    for section, services of CONFIG_OPTIONS
      section = new kd.CustomHTMLView
        tagName  : 'section'
        cssClass : "#{section}"
        partial  : "<p>#{section}</p>"

      for service, config of services
        row = new kd.CustomHTMLView cssClass: 'row'

        do (service, config) ->

          row.addSubView kdSwitch = new KodingSwitch
            size         : 'tiny'
            name         : service
            defaultValue : config.selected or no

          row.addSubView new kd.CustomHTMLView
            partial  : config.title
            cssClass : 'label'
            click    : -> if kdSwitch.getValue() then kdSwitch.setOff() else kdSwitch.setOn()

          section.addSubView row

      @addSubView section
