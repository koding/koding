CommonDomainCreateForm = require './commondomaincreateform'
globals = require 'globals'
nick = require 'app/util/nick'
module.exports = class SubdomainCreateForm extends CommonDomainCreateForm

  constructor:(options = {}, data)->

    super
      label            : ""
      placeholder      : "Type your subdomain "
      buttonTitle      : "Create subdomain"
      suffixDomain     : "#{nick()}.#{globals.config.userSitesDomain}"
      noDomainSelector : yes
    , data
