CActivity = require '../../activity'

module.exports = class CStatusActivity extends CActivity

  @trait __dirname, '../../../traits/grouprelated'
  
  @share()
  
  @set
    encapsulatedBy  : CActivity
    sharedEvents    : CActivity.sharedEvents
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : 'JStatusUpdate'
        as          : 'content'
