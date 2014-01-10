#include <node.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/resource.h> // setrlimit, getrlimit
#include <limits.h> // PATH_MAX
#include <pwd.h> // getpwnam, passwd
#include <grp.h> // getgrnam, group
#include <syslog.h> // openlog, closelog, syslog, setlogmask

#define EXCEPTION(msg) ThrowException(Exception::Error(String::New(msg)))

using namespace v8;
using namespace node;

static Handle<Value> node_getppid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("getppid: takes no arguments");
    }

    return scope.Close(Integer::New(getppid()));
}

static Handle<Value> node_getpgid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("getpgid: takes exactly one argument");
    }

    if (!args[0]->IsNumber()) {
        return EXCEPTION("getpgid: first argument must be a integer");
    }

    return scope.Close(Integer::New(getpgid(args[0]->IntegerValue())));
}

static Handle<Value> node_geteuid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("geteuid: takes no arguments");
    }

    return scope.Close(Integer::New(geteuid()));
}

static Handle<Value> node_getegid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("getegid: takes no arguments");
    }

    return scope.Close(Integer::New(getegid()));
}

static Handle<Value> node_setsid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("setsid: takes no arguments");
    }

    pid_t sid = setsid();
    if(sid == -1) {
        return ThrowException(ErrnoException(errno, "setsid"));
    }

    return scope.Close(Integer::New(sid));
}

static Handle<Value> node_chroot(const Arguments& args) {
    if(args.Length() != 1) {
        return EXCEPTION("chroot: takes exactly one argument");
    }

    if (!args[0]->IsString()) {
        return EXCEPTION("chroot: first argument must be a string");
    }

    String::Utf8Value dir_path(args[0]->ToString());

    // proper order is to first chdir() and then chroot()
    if(chdir(*dir_path)) {
        return ThrowException(ErrnoException(errno, "chroot: chdir: "));
    }

    if(chroot(*dir_path)) {
        return ThrowException(ErrnoException(errno, "chroot"));
    }

    return Undefined();
}

struct name_to_int_t {
  const char* name;
  int resource;
};

static const name_to_int_t rlimit_name_to_res[] = {
  { "core", RLIMIT_CORE },
  { "cpu", RLIMIT_CPU },
  { "data", RLIMIT_DATA },
  { "fsize", RLIMIT_FSIZE },
  { "nofile", RLIMIT_NOFILE },
  { "stack", RLIMIT_STACK },
  { "as", RLIMIT_AS },
  { 0, 0 }
};

// return null if value is RLIM_INFINITY, otherwise the uint value
static Handle<Value> rlimit_value(rlim_t limit) {
    if(limit == RLIM_INFINITY) {
        return Null();
    } else {
        return Number::New((double)limit);
    }
}

static Handle<Value> node_getrlimit(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("getrlimit: requires exactly 1 argument");
    }

    struct rlimit limit;
    if (!args[0]->IsString()) {
        return EXCEPTION("getrlimit: argument must be a string");
    }

    String::Utf8Value rlimit_name(args[0]->ToString());
    int resource = -1;
    for(const name_to_int_t* item = rlimit_name_to_res;
        item->name; ++item) {
        if(!strcmp(*rlimit_name, item->name)) {
            resource = item->resource;
            break;
        }
    }
    if(resource < 0)
    {
        return EXCEPTION("getrlimit: unknown resource name");
    }

    if(getrlimit(resource, &limit)) {
        return ThrowException(ErrnoException(errno, "getrlimit"));
    }

    Local<Object> info = Object::New();
    info->Set(String::New("soft"), rlimit_value(limit.rlim_cur));
    info->Set(String::New("hard"), rlimit_value(limit.rlim_max));

    return scope.Close(info);
}

static Handle<Value> node_setrlimit(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 2) {
        return EXCEPTION("setrlimit: requires exactly 2 arguments");
    }

    String::Utf8Value rlimit_name(args[0]->ToString());
    int resource = -1;
    for(const name_to_int_t* item = rlimit_name_to_res;
        item->name; ++item) {
        if(!strcmp(*rlimit_name, item->name)) {
            resource = item->resource;
            break;
        }
    }

    if(resource < 0)
    {
        return EXCEPTION("setrlimit: unknown resource name");
    }

    if (!args[1]->IsObject()) {
        return EXCEPTION("getrlimit: second argument must be an object");
    }

    Local<Object> limit_in = args[1]->ToObject(); // Cast
    Local<String> soft_key = String::New("soft");
    Local<String> hard_key = String::New("hard");
    struct rlimit limit;
    bool get_soft = false, get_hard = false;
    if (limit_in->Has(soft_key)) {
        if(limit_in->Get(soft_key)->IsNull()) {
            limit.rlim_cur = RLIM_INFINITY;
        }
        else {
            limit.rlim_cur = limit_in->Get(soft_key)->IntegerValue();
        }
    }
    else {
        get_soft = true;
    }

    if (limit_in->Has(hard_key)) {
        if(limit_in->Get(hard_key)->IsNull()) {
            limit.rlim_max = RLIM_INFINITY;
        }
        else {
            limit.rlim_max = limit_in->Get(hard_key)->IntegerValue();
        }
    }
    else {
        get_hard = true;
    }

    if(get_soft || get_hard) {
        // current values for the limits are needed
        struct rlimit current;
        if(getrlimit(resource, &current)) {
            return ThrowException(ErrnoException(errno, "getrlimit"));
        }
        if(get_soft) { limit.rlim_cur = current.rlim_cur; }
        if(get_hard) { limit.rlim_max = current.rlim_max; }
    }

    if(setrlimit(resource, &limit)) {
        return ThrowException(ErrnoException(errno, "setrlimit"));
    }

    return Undefined();
}

static Handle<Value> node_getpwnam(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("getpwnam: requires exactly 1 argument");
    }

    struct passwd* pwd;
    errno = 0; // reset errno before the call
    if(args[0]->IsNumber()) {
        pwd = getpwuid(args[0]->Int32Value());
        if(errno) {
            return ThrowException(ErrnoException(errno, "getpwuid"));
        }
    }
    else if (args[0]->IsString()) {
        String::Utf8Value pwnam(args[0]->ToString());
        pwd = getpwnam(*pwnam);
        if(errno) {
            return ThrowException(ErrnoException(errno, "getpwnam"));
        }
    }
    else {
        return EXCEPTION("argument must be a number or a string");
    }

    if(!pwd) {
        return EXCEPTION("user id does not exist");
    }

    Local<Object> obj = Object::New();
    obj->Set(String::New("name"), String::New(pwd->pw_name));
    obj->Set(String::New("passwd"), String::New(pwd->pw_passwd));
    obj->Set(String::New("uid"), Number::New(pwd->pw_uid));
    obj->Set(String::New("gid"), Number::New(pwd->pw_gid));
    obj->Set(String::New("gecos"), String::New(pwd->pw_gecos));
    obj->Set(String::New("shell"), String::New(pwd->pw_shell));
    obj->Set(String::New("dir"), String::New(pwd->pw_dir));

    return scope.Close(obj);
}

static Handle<Value> node_getgrnam(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("getgrnam: requires exactly 1 argument");
    }

    struct group* grp;
    errno = 0; // reset errno before the call
    if(args[0]->IsNumber()) {
        grp = getgrgid(args[0]->Int32Value());
        if(errno) {
            return ThrowException(ErrnoException(errno, "getgrgid"));
        }
    }
    else if (args[0]->IsString()) {
        String::Utf8Value pwnam(args[0]->ToString());
        grp = getgrnam(*pwnam);
        if(errno) {
            return ThrowException(ErrnoException(errno, "getgrnam"));
        }
    }
    else {
        return EXCEPTION("argument must be a number or a string");
    }

    if(!grp) {
        return EXCEPTION("group id does not exist");
    }

    Local<Object> obj = Object::New();
    obj->Set(String::New("name"), String::New(grp->gr_name));
    obj->Set(String::New("passwd"), String::New(grp->gr_passwd));
    obj->Set(String::New("gid"), Number::New(grp->gr_gid));

    Local<Array> members = Array::New();
    char** cur = grp->gr_mem;
    for(size_t i=0; *cur; ++i, ++cur) {
        (*members)->Set(i, String::New(*cur));
    }
    obj->Set(String::New("members"), members);

    return scope.Close(obj);
}

static Handle<Value> node_seteuid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("seteuid: requires exactly 1 argument");
    }

    if(seteuid(args[0]->Int32Value())) {
        return ThrowException(ErrnoException(errno, "seteuid"));
    }

    return Undefined();
}

static Handle<Value> node_setegid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("setegid: requires exactly 1 argument");
    }

    if(setegid(args[0]->Int32Value())) {
        return ThrowException(ErrnoException(errno, "setegid"));
    }

    return Undefined();
}

static Handle<Value> node_setregid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 2) {
        return EXCEPTION("setregid: requires exactly 2 arguments");
    }

    if(setregid(args[0]->Int32Value(), args[1]->Int32Value())) {
        return ThrowException(ErrnoException(errno, "setregid"));
    }

    return Undefined();
}

static Handle<Value> node_setreuid(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 2) {
        return EXCEPTION("setreuid: requires exactly 2 arguments");
    }

    if(setreuid(args[0]->Int32Value(), args[1]->Int32Value())) {
        return ThrowException(ErrnoException(errno, "setreuid"));
    }

    return Undefined();
}

// openlog() first argument (const char* ident) is not guaranteed to be
// copied within the openlog() call so we need to keep it in a safe location
static const size_t MAX_SYSLOG_IDENT=100;
static char syslog_ident[MAX_SYSLOG_IDENT+1] = {0};

static Handle<Value> node_openlog(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 3) {
        return EXCEPTION("openlog: requires exactly 3 arguments");
    }

    String::Utf8Value ident(args[0]->ToString());
    strncpy(syslog_ident, *ident, MAX_SYSLOG_IDENT);
    syslog_ident[MAX_SYSLOG_IDENT] = 0;
    if(!args[1]->IsNumber() || !args[2]->IsNumber()) {
        return EXCEPTION("openlog: invalid argument values");
    }
    // note: openlog does not ever fail, no return value
    openlog(syslog_ident, args[1]->Int32Value(), args[2]->Int32Value());

    return Undefined();
}

static Handle<Value> node_closelog(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("closelog: does not take any arguments");
    }

    // note: closelog does not ever fail, no return value
    closelog();

    return Undefined();
}

static Handle<Value> node_syslog(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 2) {
        return EXCEPTION("syslog: requires exactly 2 arguments");
    }

    String::Utf8Value message(args[1]->ToString());
    // note: syslog does not ever fail, no return value
    syslog(args[0]->Int32Value(), "%s", *message);

    return Undefined();
}

static Handle<Value> node_setlogmask(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 1) {
        return EXCEPTION("setlogmask: takes exactly 1 argument");
    }

    return scope.Close(Integer::New(setlogmask(args[0]->Int32Value())));
}

#define ADD_MASK_FLAG(name, flag) \
    obj->Set(String::New(name), Integer::New(flag)); \
    obj->Set(String::New("mask_" name), Integer::New(LOG_MASK(flag)));

static Handle<Value> node_update_syslog_constants(const Arguments& args) {
    HandleScope scope;

    if((args.Length() != 1) || (!args[0]->IsObject())) {
        return EXCEPTION("invalid arguments");
    }

    Local<Object> obj = args[0]->ToObject();
    ADD_MASK_FLAG("emerg", LOG_EMERG);
    ADD_MASK_FLAG("alert", LOG_ALERT);
    ADD_MASK_FLAG("crit", LOG_CRIT);
    ADD_MASK_FLAG("err", LOG_ERR);
    ADD_MASK_FLAG("warning", LOG_WARNING);
    ADD_MASK_FLAG("notice", LOG_NOTICE);
    ADD_MASK_FLAG("info", LOG_INFO);
    ADD_MASK_FLAG("debug", LOG_DEBUG);

    // facility constants
    obj->Set(String::New("auth"), Integer::New(LOG_AUTH));
#ifdef LOG_AUTHPRIV
    obj->Set(String::New("authpriv"), Integer::New(LOG_AUTHPRIV));
#endif
    obj->Set(String::New("cron"), Integer::New(LOG_CRON));
    obj->Set(String::New("daemon"), Integer::New(LOG_DAEMON));
#ifdef LOG_FTP
    obj->Set(String::New("ftp"), Integer::New(LOG_FTP));
#endif
    obj->Set(String::New("kern"), Integer::New(LOG_KERN));
    obj->Set(String::New("lpr"), Integer::New(LOG_LPR));
    obj->Set(String::New("mail"), Integer::New(LOG_MAIL));
    obj->Set(String::New("news"), Integer::New(LOG_NEWS));
    obj->Set(String::New("syslog"), Integer::New(LOG_SYSLOG));
    obj->Set(String::New("user"), Integer::New(LOG_USER));
    obj->Set(String::New("uucp"), Integer::New(LOG_UUCP));
    obj->Set(String::New("local0"), Integer::New(LOG_LOCAL0));
    obj->Set(String::New("local1"), Integer::New(LOG_LOCAL1));
    obj->Set(String::New("local2"), Integer::New(LOG_LOCAL2));
    obj->Set(String::New("local3"), Integer::New(LOG_LOCAL3));
    obj->Set(String::New("local4"), Integer::New(LOG_LOCAL4));
    obj->Set(String::New("local5"), Integer::New(LOG_LOCAL5));
    obj->Set(String::New("local6"), Integer::New(LOG_LOCAL6));
    obj->Set(String::New("local7"), Integer::New(LOG_LOCAL7));

    // option constants
    obj->Set(String::New("pid"), Integer::New(LOG_PID));
    obj->Set(String::New("cons"), Integer::New(LOG_CONS));
    obj->Set(String::New("ndelay"), Integer::New(LOG_NDELAY));
    obj->Set(String::New("odelay"), Integer::New(LOG_ODELAY));
    obj->Set(String::New("nowait"), Integer::New(LOG_NOWAIT));

    return Undefined();
}

static Handle<Value> node_gethostname(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("gethostname: takes no arguments");
    }
#ifndef HOST_NAME_MAX
# define HOST_NAME_MAX 255
#endif

    char hostname[HOST_NAME_MAX];

    int rc = gethostname(hostname, HOST_NAME_MAX);
    if (rc != 0) {
        return ThrowException(ErrnoException(errno, "gethostname"));
    }

    return scope.Close(String::New(hostname));
}

static Handle<Value> node_getdomainname(const Arguments& args) {
    HandleScope scope;

    if(args.Length() != 0) {
        return EXCEPTION("getdomainname: takes no arguments");
    }
#ifndef DOMAIN_NAME_MAX
# define DOMAIN_NAME_MAX 64
#endif

    char domainname[DOMAIN_NAME_MAX];

    int rc = getdomainname(domainname, DOMAIN_NAME_MAX);
    if (rc != 0) {
        return ThrowException(ErrnoException(errno, "getdomainname"));
    }

    return scope.Close(String::New(domainname));
}

static Handle<Value> node_sethostname(const Arguments& args) {
    HandleScope scope;

    if (args.Length() != 1) {
        return EXCEPTION("sethostname: takes exactly 1 argument");
    }

    if (!args[0]->IsString()) {
        return EXCEPTION("sethostname: first argument must be a string");
    }

    String::Utf8Value str(args[0]);
    const char * hostname = *str;

    int rc = sethostname(hostname, str.length());
    if (rc != 0) {
        return ThrowException(ErrnoException(errno, "sethostname"));
    }

    return scope.Close(Undefined());
}

static Handle<Value> node_setdomainname(const Arguments& args) {
    HandleScope scope;

    if (args.Length() != 1) {
        return EXCEPTION("setdomainname: takes exactly 1 argument");
    }

    if (!args[0]->IsString()) {
        return EXCEPTION("setdomainname: first argument must be a string");
    }

    String::Utf8Value str(args[0]);
    const char * domainname = *str;

    int rc = setdomainname(domainname, str.length());
    if (rc != 0) {
        return ThrowException(ErrnoException(errno, "setdomainname"));
    }

    return scope.Close(Undefined());
}


extern "C" void init(Handle<Object> target)
{
    HandleScope scope;
    NODE_SET_METHOD(target, "chroot", node_chroot);
    NODE_SET_METHOD(target, "closelog", node_closelog);
    NODE_SET_METHOD(target, "getegid", node_getegid);
    NODE_SET_METHOD(target, "geteuid", node_geteuid);
    NODE_SET_METHOD(target, "getpgid", node_getpgid);
    NODE_SET_METHOD(target, "getppid", node_getppid);
    NODE_SET_METHOD(target, "getpwnam", node_getpwnam);
    NODE_SET_METHOD(target, "getgrnam", node_getgrnam);
    NODE_SET_METHOD(target, "getrlimit", node_getrlimit);
    NODE_SET_METHOD(target, "openlog", node_openlog);
    NODE_SET_METHOD(target, "setegid", node_setegid);
    NODE_SET_METHOD(target, "seteuid", node_seteuid);
    NODE_SET_METHOD(target, "setlogmask", node_setlogmask);
    NODE_SET_METHOD(target, "setregid", node_setregid);
    NODE_SET_METHOD(target, "setreuid", node_setreuid);
    NODE_SET_METHOD(target, "setrlimit", node_setrlimit);
    NODE_SET_METHOD(target, "setsid", node_setsid);
    NODE_SET_METHOD(target, "syslog", node_syslog);
    NODE_SET_METHOD(target, "update_syslog_constants",
                    node_update_syslog_constants);
    NODE_SET_METHOD(target, "gethostname", node_gethostname);
    NODE_SET_METHOD(target, "getdomainname", node_getdomainname);
    NODE_SET_METHOD(target, "sethostname", node_sethostname);
    NODE_SET_METHOD(target, "setdomainname", node_setdomainname);
}
