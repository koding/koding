CActivity = require '../../activity'

module.exports = class CBlogPostActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : 'JBlogPost'
        as          : 'content'
