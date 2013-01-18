// Copyright 2010, Camilo Aguilar. Cloudescape, LLC.
#include "bindings.h"

namespace NodeInotify {
    void InitializeInotify(Handle<Object> target) {
        HandleScope scope;

        Inotify::Initialize(target);

        target->Set(String::NewSymbol("version"),
                    String::New(NODE_INOTIFY_VERSION));

        Handle<ObjectTemplate> global = ObjectTemplate::New();
        Handle<Context> context = Context::New(NULL, global);
        Context::Scope context_scope(context);

        context->Global()->Set(String::NewSymbol("Inotify"), target);
    }

    extern "C" void init (Handle<Object> target) {
        HandleScope scope;
        InitializeInotify(target);
    }
} //namespace NodeInotify

