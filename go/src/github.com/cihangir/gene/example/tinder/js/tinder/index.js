module.exports = (function(o) {
  o.baseUrl || (o.baseUrl = '');
  return {
    Account: require('./account')(o),
    FacebookFriends: require('./facebookfriends')(o),
    FacebookProfile: require('./facebookprofile')(o),
    Profile: require('./profile')(o),
  };
})(o);