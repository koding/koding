module.exports = {
  'instructions' :
    title        : 'Instructions'
    pages        : [
      require './readmepageview'
      require './stacktemplatepageview'
    ]
  'credentials'  :
    title        : 'Credentials'
    pages        : [
      require './credentialspageview'
      require './credentialserrorpageview'
    ]
  'buildstack'   :
    title        : 'Build Stack'
    pages        : [
      require './buildstackpageview'
      require './buildstacksuccesspageview'
      require './buildstackerrorpageview'
      require './buildstacktimeoutpageview'
    ]
}
