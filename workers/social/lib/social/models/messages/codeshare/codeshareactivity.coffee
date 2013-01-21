CActivity = require '../../activity'

module.exports = class CCodeShareActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : "JCodeShare"
        as          : 'content'
