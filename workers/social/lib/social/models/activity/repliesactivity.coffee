CActivity = require './index'

module.exports = class CRepliesActivity extends CActivity

  {Relationship} = require 'jraphical'

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : Relationship
        as          : 'subject'