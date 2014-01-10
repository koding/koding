var posix;
try {
    // Node >=0.5
    posix = require(__dirname + '/../../build/Release/posix.node');
}
catch(e) {
    // Node <0.5
    posix = require(__dirname + '/../../build/default/posix.node');
}

var syslog_constants = {};
posix.update_syslog_constants(syslog_constants);

function syslog_const(value) {
    if(!syslog_constants[value]) {
        throw "invalid syslog constant value: " + value;
    }

    return syslog_constants[value];
}

function syslog_flags(option, prefix) {
    prefix = prefix || "";
    var opt = 0;
    for(var key in option) {
        var flag = syslog_const(prefix + key); // checks all flags
        opt |= option[key] ? flag : 0;
    }
    return opt;
}

module.exports = {
    getgid: process.getgid,
    getuid: process.getuid,
    setgid: process.setgid,
    setuid: process.setuid,

    chroot: posix.chroot,
    closelog: posix.closelog,
    getegid: posix.getegid,
    geteuid: posix.geteuid,
    getgrnam: posix.getgrnam,
    getpgid: posix.getpgid,
    getppid: posix.getppid,
    getpwnam: posix.getpwnam,
    getrlimit: posix.getrlimit,
    setrlimit: posix.setrlimit,
    setsid: posix.setsid,

    openlog: function(ident, option, facility) {
        return posix.openlog(ident, syslog_flags(option),
                             syslog_const(facility));
    },

    syslog: function(priority, message) {
        return posix.syslog(syslog_const(priority), message);
    },

    setlogmask: function(maskpri) {
        var bits = posix.setlogmask(syslog_flags(maskpri, "mask_"));
        flags = {};
        for(var key in syslog_constants) {
            if(key.match("^mask_")) {
                flags[key.substr(5, 10)] = (bits & syslog_constants[key]) ?
                    true : false;
            }
        }
        return flags;
    },

    // http://pubs.opengroup.org/onlinepubs/007904875/functions/getpgrp.html
    getpgrp: function() {
        return posix.getpgid(0);
    },

    seteuid: function(euid) {
        euid = (typeof(euid) == 'string') ? posix.getpwnam(euid).uid : euid;
        return posix.seteuid(euid);
    },

    setreuid: function(ruid, euid) {
        ruid = (typeof(ruid) == 'string') ? posix.getpwnam(ruid).uid : ruid;
        euid = (typeof(euid) == 'string') ? posix.getpwnam(euid).uid : euid;
        return posix.setreuid(ruid, euid);
    },

    setegid: function(egid) {
        egid = (typeof(egid) == 'string') ? posix.getgrnam(egid).gid : egid;
        return posix.setegid(egid);
    },

    setregid: function(rgid, egid) {
        rgid = (typeof(rgid) == 'string') ? posix.getgrnam(rgid).gid : rgid;
        egid = (typeof(egid) == 'string') ? posix.getgrnam(egid).gid : egid;
        return posix.setregid(rgid, egid);
    },

    gethostname: posix.gethostname,
    sethostname: posix.sethostname,
    getdomainname: posix.getdomainname,
    setdomainname: posix.setdomainname,
};
