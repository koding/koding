// Copyright 2010, Camilo Aguilar. Cloudescape, LLC.
#ifndef SRC_BINDINGS_H_
#define SRC_BINDINGS_H_
#include "node_inotify.h"

namespace NodeInotify {

    class Inotify : public ObjectWrap {
        public:
            static void Initialize(Handle<Object> target);

            Inotify();
            Inotify(bool nonpersistent);
            virtual ~Inotify();
        protected:
            static Handle<Value> New(const Arguments& args);
            static Handle<Value> AddWatch(const Arguments& args);
            static Handle<Value> RemoveWatch(const Arguments& args);
            static Handle<Value> Close(const Arguments& args);
            static Handle<Value> GetPersistent(Local<String> property,
                                             const AccessorInfo& info);

        private:
            int fd;
            ev_io read_watcher;
            bool persistent;
            static void Callback(EV_P_ ev_io *watcher, int revents);
    };

}  //namespace NodeInotify

#endif  // SRC_BINDINGS_H

