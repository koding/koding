CActivity = require '../../activity'

module.exports = class CStatusActivity extends CActivity

  JStatusUpdate = require './index'

  @share()
  
  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JStatusUpdate
        as          : 'content'
