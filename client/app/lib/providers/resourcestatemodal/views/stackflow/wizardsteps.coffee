module.exports = {
  'Instructions' :
    pages        : [
      require './readmepageview'
      require './stacktemplatepageview'
    ]
  'Credentials'  :
    pages        : [
      require './credentialspageview'
      require './credentialserrorpageview'
    ]
  'BuildStack'   :
    title        : 'Build Stack'
    pages        : [
      require './buildstackpageview'
      require './buildstacksuccesspageview'
      require './buildstackerrorpageview'
      require './buildstacklogspageview'
    ]
}
