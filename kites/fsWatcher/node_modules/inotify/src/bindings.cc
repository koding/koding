// Copyright 2010, Camilo Aguilar. Cloudescape, LLC.
#include "bindings.h"

/* size of the event structure, not counting name */
#define EVENT_SIZE  (sizeof (struct inotify_event))

/* reasonable guess as to size of 1024 events */
#define BUF_LEN        (1024 * (EVENT_SIZE + 16))

namespace NodeInotify {
    static Persistent<String> path_sym;
    static Persistent<String> watch_for_sym;
    static Persistent<String> callback_sym;
    static Persistent<String> persistent_sym;
    static Persistent<String> watch_sym;
    static Persistent<String> mask_sym;
    static Persistent<String> cookie_sym;
    static Persistent<String> name_sym;

    void Inotify::Initialize(Handle<Object> target) {
        Local<FunctionTemplate> t = FunctionTemplate::New(Inotify::New);

        t->InstanceTemplate()->SetInternalFieldCount(1);

        NODE_SET_PROTOTYPE_METHOD(t, "addWatch",
                                      Inotify::AddWatch);
        NODE_SET_PROTOTYPE_METHOD(t, "removeWatch",
                                      Inotify::RemoveWatch);
        NODE_SET_PROTOTYPE_METHOD(t, "close",
                                      Inotify::Close);

        //Constants initialization
        NODE_DEFINE_CONSTANT(t, IN_ACCESS); //File was accessed (read)
        NODE_DEFINE_CONSTANT(t, IN_ATTRIB); //Metadata changed, e.g., permissions, timestamps,
                                                      //extended attributes, link count (since Linux 2.6.25),
                                                      //UID, GID, etc.
        NODE_DEFINE_CONSTANT(t, IN_CLOSE_WRITE); //File opened for writing was closed
        NODE_DEFINE_CONSTANT(t, IN_CLOSE_NOWRITE); //File not opened for writing was closed
        NODE_DEFINE_CONSTANT(t, IN_CREATE); //File/directory created in watched directory
        NODE_DEFINE_CONSTANT(t, IN_DELETE); //File/directory deleted from watched directory
        NODE_DEFINE_CONSTANT(t, IN_DELETE_SELF); //Watched file/directory was itself deleted
        NODE_DEFINE_CONSTANT(t, IN_MODIFY); //File was modified
        NODE_DEFINE_CONSTANT(t, IN_MOVE_SELF); //Watched file/directory was itself moved
        NODE_DEFINE_CONSTANT(t, IN_MOVED_FROM); //File moved out of watched directory
        NODE_DEFINE_CONSTANT(t, IN_MOVED_TO); //File moved into watched directory
        NODE_DEFINE_CONSTANT(t, IN_OPEN); //File was opened
        NODE_DEFINE_CONSTANT(t, IN_IGNORED); // Watch was removed explicitly (inotify.watch.rm) or
                                                       //automatically (file was deleted, or file system was
                                                        //unmounted)
        NODE_DEFINE_CONSTANT(t, IN_ISDIR); //Subject of this event is a directory
        NODE_DEFINE_CONSTANT(t, IN_Q_OVERFLOW); //Event queue overflowed (wd is -1 for this event)
        NODE_DEFINE_CONSTANT(t, IN_UNMOUNT); //File system containing watched object was unmounted
        NODE_DEFINE_CONSTANT(t, IN_ALL_EVENTS);

        NODE_DEFINE_CONSTANT(t, IN_ONLYDIR); // Only watch the path if it is a directory.
        NODE_DEFINE_CONSTANT(t, IN_DONT_FOLLOW); // Do not follow a sym link
        NODE_DEFINE_CONSTANT(t, IN_ONESHOT); // Only send event once
        NODE_DEFINE_CONSTANT(t, IN_MASK_ADD); //Add (OR) events to watch mask for this pathname if it
                                                        //already exists (instead of replacing mask).

        NODE_DEFINE_CONSTANT(t, IN_CLOSE); // (IN_CLOSE_WRITE | IN_CLOSE_NOWRITE)  Close
        NODE_DEFINE_CONSTANT(t, IN_MOVE);  //  (IN_MOVED_FROM | IN_MOVED_TO)  Moves

        path_sym        = NODE_PSYMBOL("path");
        watch_for_sym   = NODE_PSYMBOL("watch_for");
        callback_sym    = NODE_PSYMBOL("callback");
        persistent_sym  = NODE_PSYMBOL("persistent");

        watch_sym       = NODE_PSYMBOL("watch");
        mask_sym        = NODE_PSYMBOL("mask");
        cookie_sym      = NODE_PSYMBOL("cookie");
        name_sym        = NODE_PSYMBOL("name");

        Local<ObjectTemplate> object_tmpl = t->InstanceTemplate();
        object_tmpl->SetAccessor(persistent_sym, Inotify::GetPersistent);

        t->SetClassName(String::NewSymbol("Inotify"));
        target->Set(String::NewSymbol("Inotify"), t->GetFunction());
    }

    Inotify::Inotify() : ObjectWrap() {
        ev_init(&read_watcher, Inotify::Callback);
        read_watcher.data = this;  //preserving my reference to use it inside Inotify::Callback
        persistent = true;
    }

    Inotify::Inotify(bool nonpersistent) : ObjectWrap() {
        ev_init(&read_watcher, Inotify::Callback);
        read_watcher.data = this;  //preserving my reference to use it inside Inotify::Callback
        persistent = nonpersistent;
    }

    Inotify::~Inotify() {
        if(!persistent) {
            ev_ref(EV_DEFAULT_UC);
        }
        ev_io_stop(EV_DEFAULT_UC_ &read_watcher);
        assert(!ev_is_active(&read_watcher));
        assert(!ev_is_pending(&read_watcher));
    }

    Handle<Value> Inotify::New(const Arguments& args) {
        HandleScope scope;

        Inotify *inotify = NULL;
        if(args.Length() == 1 && args[0]->IsBoolean()) {
            inotify = new Inotify(args[0]->IsTrue());
        } else {
            inotify = new Inotify();
        }

 	inotify->fd = inotify_init();

        if(inotify->fd == -1) {
            ThrowException(String::New(strerror(errno)));
            return Null();
        }
	
	int flags = fcntl(inotify->fd, F_GETFL);
	if(flags == -1) {
	    flags = 0;
	}

	fcntl(inotify->fd, F_SETFL, flags | O_NONBLOCK);

        ev_io_set(&inotify->read_watcher, inotify->fd, EV_READ);
        ev_io_start(EV_DEFAULT_UC_ &inotify->read_watcher);

        Local<Object> obj = args.This();
        inotify->Wrap(obj);

        if(!inotify->persistent) {
            ev_unref(EV_DEFAULT_UC);
        }
        /*Increment object references to avoid be GCed while
         I'm waiting for inotify events in th ev_pool.
         Also, the object is not weak anymore */
        inotify->Ref();

        return scope.Close(obj);
    }

    Handle<Value> Inotify::AddWatch(const Arguments& args) {
        HandleScope scope;
        uint32_t mask = 0;
        int watch_descriptor = 0;

        if(args.Length() < 1 || !args[0]->IsObject()) {
            return ThrowException(Exception::TypeError(
            String::New("You must specify an object as first argument")));
        }

        Local<Object> args_ = args[0]->ToObject();

        if(!args_->Has(path_sym)) {
            return ThrowException(Exception::TypeError(
            String::New("You must specify a path to watch for events")));
        }

        if(!args_->Has(callback_sym) ||
            !args_->Get(callback_sym)->IsFunction()) {
            return ThrowException(Exception::TypeError(
            String::New("You must specify a callback function")));
        }

        if(!args_->Has(watch_for_sym)) {
            mask |= IN_ALL_EVENTS;
        } else {
            if(!args_->Get(watch_for_sym)->IsInt32()) {
                return ThrowException(Exception::TypeError(
                String::New("You must specify OR'ed set of events")));
            }
            mask |= args_->Get(watch_for_sym)->Int32Value();
            if(mask == 0) {
                return ThrowException(Exception::TypeError(
                String::New("You must specify OR'ed set of events")));
            }
       }

        String::Utf8Value path(args_->Get(path_sym));

        Inotify *inotify = ObjectWrap::Unwrap<Inotify>(args.This());

        /* add watch */
        watch_descriptor = inotify_add_watch(inotify->fd, (const char *) *path, mask);

        Local<Integer> descriptor = Integer::New(watch_descriptor);

        //Local<Function> callback = Local<Function>::Cast(args_->Get(callback_sym));
        inotify->handle_->Set(descriptor, args_->Get(callback_sym));

        return scope.Close(descriptor);
    }

    Handle<Value> Inotify::RemoveWatch(const Arguments& args) {
        HandleScope scope;
        uint32_t watch = 0;
        int ret = -1;

        if(args.Length() == 0 || !args[0]->IsInt32()) {
            return ThrowException(Exception::TypeError(
            String::New("You must specify a valid watcher descriptor as argument")));
        }
        watch = args[0]->Int32Value();

        Inotify *inotify = ObjectWrap::Unwrap<Inotify>(args.This());

        ret = inotify_rm_watch(inotify->fd, watch);
        if(ret == -1) {
            ThrowException(String::New(strerror(errno)));
            return False();
        }

        return True();
    }

    Handle<Value> Inotify::Close(const Arguments& args) {
        HandleScope scope;
        int ret = -1;

        Inotify *inotify = ObjectWrap::Unwrap<Inotify>(args.This());
        ret = close(inotify->fd);

        if(ret == -1) {
            ThrowException(String::New(strerror(errno)));
            return False();
        }

        if(!inotify->persistent) {
            ev_ref(EV_DEFAULT_UC);
        }

        ev_io_stop(EV_DEFAULT_UC_ &inotify->read_watcher);

        /*Eliminating reference created inside of Inotify::New.
        The object is also weak again.
        Now v8 can do its stuff and GC the object.
        */
        inotify->Unref();

        return True();
    }

    void Inotify::Callback(EV_P_ ev_io *watcher, int revents) {
        HandleScope scope;

        Inotify *inotify = static_cast<Inotify*>(watcher->data);
        assert(watcher == &inotify->read_watcher);

        char buffer[BUF_LEN];

        //int length = read(inotify->fd, buffer, BUF_LEN);

        Local<Value> argv[1];
        TryCatch try_catch;

        int i = 0;
	int sz = 0;
        while ((sz = read(inotify->fd, buffer, BUF_LEN)) > 0) {
	  struct inotify_event *event;
	  for (i = 0; i <= (sz-EVENT_SIZE); i += (EVENT_SIZE + event->len)) {
            event = (struct inotify_event *) &buffer[i];

            Local<Object> obj = Object::New();
            obj->Set(watch_sym, Integer::New(event->wd));
            obj->Set(mask_sym, Integer::New(event->mask));
            obj->Set(cookie_sym, Integer::New(event->cookie));

            if(event->len) {
                obj->Set(name_sym, String::New(event->name));
            }
            argv[0] = obj;

            inotify->Ref();
            Local<Value> callback_ = inotify->handle_->Get(Integer::New(event->wd));
            Local<Function> callback = Local<Function>::Cast(callback_);

            callback->Call(inotify->handle_, 1, argv);
            inotify->Unref();

            if(event->mask & IN_IGNORED) {
                //deleting callback because the watch was removed
                Local<Value> wd = Integer::New(event->wd);
                inotify->handle_->Delete(wd->ToString());
            }

            if (try_catch.HasCaught()) {
                FatalException(try_catch);
            }
	  }
	}
    }

    Handle<Value> Inotify::GetPersistent(Local<String> property,
                                        const AccessorInfo& info) {
        Inotify *inotify = ObjectWrap::Unwrap<Inotify>(info.This());

        return inotify->persistent ? True() : False();
     }
}//namespace NodeInotify

