CActivity = require './index'

module.exports = class CRepliesActivity extends CActivity

  @trait __dirname, '../../traits/flaggable'
  @trait __dirname, '../../traits/grouprelated'

  {Relationship} = require 'jraphical'

  @share()

  @set
    encapsulatedBy  : CActivity
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : Relationship
        as          : 'subject'