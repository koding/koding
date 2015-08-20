kd           = require 'kd'
KodingSwitch = require 'app/commonviews/kodingswitch'

CONFIG_OPTIONS =
  Database     :
    mysql      : title: 'MySQL',    command: 'apt-get install mysql'
    redis      : title: 'Redis',    command: 'apt-get install redis'
    mongodb    : title: 'Mongo DB', command: 'apt-get install mongodb'
    postgre    : title: 'Postgre',  command: 'apt-get install postgre-sql'
    sqlite     : title: 'SQLite',   command: 'apt-get insall sqlite'
  Language     :
    node       : title: 'Node.js',  command: 'apt-get install node'
    ruby       : title: 'Ruby',     command: 'apt-get install ruby'
    python     : title: 'Python',   command: 'apt-get install python'
    php        : title: 'PHP',      command: 'apt-get install php'
  'Web Server' :
    apache     : title: 'Apache',   command: 'apt-get install apache'
    nginx      : title: 'Nginx',    command: 'apt-get install nginx'


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

        row.addSubView kdSwitch = new KodingSwitch
          size         : 'tiny'
          name         : service
          defaultValue : config.selected or no

        row.addSubView new kd.CustomHTMLView
          partial  : config.title
          cssClass : 'label'

        section.addSubView row

      @addSubView section
