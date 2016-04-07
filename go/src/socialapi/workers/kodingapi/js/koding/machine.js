var iz, processRequest;
iz = require('iz');
processRequest = require('./_request.js');
module.exports = (function(o) {
  return {
    GetMachine: function(data, callback) {
      return processRequest(o.baseUrl + '/machine/getmachine', data, callback)
    },
    GetMachineStatus: function(data, callback) {
      return processRequest(o.baseUrl + '/machine/getmachinestatus', data, callback)
    },
    ListMachines: function(data, callback) {
      return processRequest(o.baseUrl + '/machine/listmachines', data, callback)
    },
  }
})(o);