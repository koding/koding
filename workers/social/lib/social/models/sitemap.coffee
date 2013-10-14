
jraphical = require 'jraphical'

module.exports = class JSitemap extends jraphical.Module

  @set
    schema                :
      name                :
        type              : String
        required          : yes
      content             :
        type              : String
        required          : yes