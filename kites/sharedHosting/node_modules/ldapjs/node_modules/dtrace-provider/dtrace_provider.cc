#include "dtrace_provider.h"
#include <v8.h>

#include <node.h>

#ifdef _HAVE_DTRACE

namespace node {
  
  using namespace v8;
  
  void DTraceProvider::Initialize(Handle<Object> target) {
    HandleScope scope;

    Local<FunctionTemplate> t = FunctionTemplate::New(DTraceProvider::New);
    t->InstanceTemplate()->SetInternalFieldCount(1);
    t->SetClassName(String::NewSymbol("DTraceProvider"));

    NODE_SET_PROTOTYPE_METHOD(t, "addProbe", DTraceProvider::AddProbe);
    NODE_SET_PROTOTYPE_METHOD(t, "enable", DTraceProvider::Enable);
    NODE_SET_PROTOTYPE_METHOD(t, "fire", DTraceProvider::Fire);

    target->Set(String::NewSymbol("DTraceProvider"), t->GetFunction());
  }
  
  Handle<Value> DTraceProvider::New(const Arguments& args) {
    HandleScope scope;
    DTraceProvider *p = new DTraceProvider();

    if (args.Length() != 1 || !args[0]->IsString()) {
      return ThrowException(Exception::Error(String::New(
        "Must give provider name as argument")));
    }
    
    String::AsciiValue name(args[0]->ToString());
    p->name = strdup(*name);

    p->Wrap(args.Holder());
    return args.This();
  }

  Handle<Value> DTraceProvider::AddProbe(const Arguments& args) {
    HandleScope scope;
    DTraceProvider *provider = ObjectWrap::Unwrap<DTraceProvider>(args.Holder());

    if (!args[0]->IsString()) {
      return ThrowException(Exception::Error(String::New(
        "Must give probe name as first argument")));
    }

    DTraceProbeDef *probe = new DTraceProbeDef();
    probe->next = NULL;

    // init argument types
    int i;
    for (i = 0; (args[i+1]->IsString() && i < 6); i++) {
      String::AsciiValue type(args[i+1]->ToString());
      probe->types[i] = strdup(*type);
    }
    probe->types[i] = NULL;

    // init name and function
    String::AsciiValue name(args[0]->ToString());
    probe->name = strdup(*name);
    probe->function = (char *) "func";

    // append to probe list
    if (provider->probe_defs == NULL)
      provider->probe_defs = probe;
    else {
      DTraceProbeDef *p;
      for (p = provider->probe_defs; (p->next != NULL); p = p->next) ;
      p->next = probe;
    }

    return Undefined();
  }

  Handle<Value> DTraceProvider::Enable(const Arguments& args) {
    HandleScope scope;
    DTraceProvider *provider = ObjectWrap::Unwrap<DTraceProvider>(args.Holder());

    DOFStrtab *strtab = new DOFStrtab(0);
    dof_stridx_t pv_name = strtab->Add(provider->name);

    uint32_t argidx = 0;
    uint32_t offidx = 0;

    if (provider->probe_defs == NULL) {
      return Undefined();
    }

    DOFSection *probes = new DOFSection(DOF_SECT_PROBES, 1);

    // PROBES SECTION
    for (DTraceProbeDef *d = provider->probe_defs; d != NULL; d = d->next) {
      uint8_t argc = 0;
      dof_stridx_t argv = 0;
      DTraceProbe *p = new DTraceProbe();

      for (int i = 0; d->types[i] != NULL && i < 6; i++) {
	dof_stridx_t type = strtab->Add(d->types[i]);
	argc++;
	if (argv == 0)
	  argv = type;
	
	if (!strcmp("char *", d->types[i])) {
	  p->types[i] = ARGTYPE_CHAR;
	}
	else {
	  p->types[i] = ARGTYPE_INT;
	}
      }

      p->name	    = strtab->Add(d->name);
      p->func	    = strtab->Add(d->function);
      p->noffs    = 1;
      p->enoffidx = offidx;
      p->argidx   = argidx;
      p->nenoffs  = 1;
      p->offidx   = offidx;
      p->nargc    = argc;
      p->xargc    = argc;
      p->nargv    = argv;
      p->xargv    = argv;
      p->CreateTracepoints();

      argidx += argc;
      offidx++;
      
      d->probe = p;

      provider->AppendProbe(p);

      void *dof = p->Dof();
      probes->AddData(dof, sizeof(dof_probe_t));
      free(dof);

      probes->entsize = sizeof(dof_probe_t);
    }

    // PRARGS SECTION
    DOFSection *prargs = new DOFSection(DOF_SECT_PRARGS, 2);
    for (DTraceProbeDef *d = provider->probe_defs; d != NULL; d = d->next) {
      for (uint8_t i = 0; i < d->Argc(); i++) {
	prargs->AddData(&i, 1);
	prargs->entsize = 1;
      }
    }

    // estimate DOF size here, allocate
    size_t dof_size = provider->DofSize(strtab);

    DOFFile *file = new DOFFile(dof_size);
    file->AppendSection(strtab);
    file->AppendSection(probes);
    file->AppendSection(prargs);

    // PROFFS SECTION
    DOFSection *proffs = new DOFSection(DOF_SECT_PROFFS, 3);
    for (DTraceProbeDef *d = provider->probe_defs; d != NULL; d = d->next) {
      uint32_t off = d->probe->ProbeOffset(file->dof, d->Argc());
      proffs->AddData(&off, 4);
      proffs->entsize = 4;
    }
    file->AppendSection(proffs);

    // PRENOFFS SECTION
    DOFSection *prenoffs = new DOFSection(DOF_SECT_PRENOFFS, 4);
    for (DTraceProbeDef *d = provider->probe_defs; d != NULL; d = d->next) {
      uint32_t off = d->probe->IsEnabledOffset(file->dof);
      prenoffs->AddData(&off, 4);
      prenoffs->entsize = 4;
    }
    file->AppendSection(prenoffs);
    
    // PROVIDER SECTION
    DOFSection *provider_s = new DOFSection(DOF_SECT_PROVIDER, 5);
    dof_provider_t p;
    memset(&p, 0, sizeof(p));
    
    p.dofpv_strtab   = 0;
    p.dofpv_probes   = 1;
    p.dofpv_prargs   = 2;
    p.dofpv_proffs   = 3;
    p.dofpv_prenoffs = 4;
    p.dofpv_name     = pv_name;
    p.dofpv_provattr = DOF_ATTR(DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING);
    p.dofpv_modattr  = DOF_ATTR(DTRACE_STABILITY_PRIVATE,  DTRACE_STABILITY_PRIVATE,  DTRACE_STABILITY_EVOLVING);
    p.dofpv_funcattr = DOF_ATTR(DTRACE_STABILITY_PRIVATE,  DTRACE_STABILITY_PRIVATE,  DTRACE_STABILITY_EVOLVING);
    p.dofpv_nameattr = DOF_ATTR(DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING);
    p.dofpv_argsattr = DOF_ATTR(DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING, DTRACE_STABILITY_EVOLVING);
    provider_s->AddData(&p, sizeof(p));
    file->AppendSection(provider_s);

    file->Generate();
    file->Load();

    provider->file = file;

    return Undefined();
  }

  Handle<Value> DTraceProvider::Fire(const Arguments& args) {
    HandleScope scope;
    DTraceProvider *provider = ObjectWrap::Unwrap<DTraceProvider>(args.Holder());

    if (!args[0]->IsString()) {
      return ThrowException(Exception::Error(String::New(
        "Must give probe name as first argument")));
    }

    if (!args[1]->IsFunction()) {
      return ThrowException(Exception::Error(String::New(
        "Must give probe value callback as second argument")));
    }

    String::AsciiValue probe_name(args[0]->ToString());

    // find the probe we should be firing
    DTraceProbeDef *pd;
    for (pd = provider->probe_defs; pd != NULL; pd = pd->next) {
      // XXX eliminate this search
      if (!strcmp(pd->name, *probe_name)) {
	break;
      }
    }
    if (pd == NULL) {
      return Undefined();
    }

    // perform is-enabled check
    DTraceProbe *p = pd->probe;
    void *(*isfunc)() = (void* (*)())(p->addr); 
    long isenabled = (long)(*isfunc)();
    if (isenabled == 0) {
      return Undefined();
    }

    // invoke fire callback
    TryCatch try_catch;

    Local<Function> cb = Local<Function>::Cast(args[1]);
    Local<Value> probe_args = cb->Call(provider->handle_, 0, NULL);

    // exception in args callback?
    if (try_catch.HasCaught()) {
      FatalException(try_catch);
      return Undefined();
    }

    // check return
    if (!probe_args->IsArray()) {
      return Undefined();
    }

    Local<Array> a = Local<Array>::Cast(probe_args);
    p->Fire(a);

    return Undefined();
  }

  void DTraceProvider::AppendProbe(DTraceProbe *probe) {
    if (this->probes == NULL)
      this->probes = probe;
    else {
      DTraceProbe *p;
      for (p = this->probes; (p->next != NULL); p = p->next) ;
      p->next = probe;
    }
  } 

  size_t DTraceProvider::DofSize(DOFStrtab *strtab) {
    int args = 0;
    int probes = 0;
    size_t size = 0;

    for (DTraceProbeDef *d = this->probe_defs; d != NULL; d = d->next) {
      args += d->Argc();
      probes++;
    }
    
    size_t sections[8] = {
      sizeof(dof_hdr_t),
      sizeof(dof_sec_t) * 6,
      strtab->size,
      sizeof(dof_probe_t) * probes,
      sizeof(uint8_t) * args,
      sizeof(uint32_t) * probes,
      sizeof(uint32_t) * probes,
      sizeof(dof_provider_t),
    };

    for (int i = 0; i < 8; i++) {
      size += sections[i];
      size_t i = size % 8;
      if (i > 0) {
	size += (8 - i);
      }
    }

    return size;
  }

  // --------------------------------------------------------------------
  // DOFStrtab

  int DOFStrtab::Add(char *string) {
    size_t length = strlen(string);

    if (this->data == NULL) {
      this->strindex = 1;
      this->data = (char *) malloc(1);
      memcpy((void *) this->data, "\0", 1);
    }

    int i = this->strindex;
    this->strindex += (length + 1);
    this->data = (char *) realloc(this->data, this->strindex);
    (void) memcpy((void *) (this->data + i), (void *)string, length + 1);
    this->size = i + length + 1;

    return i;
  }

  // --------------------------------------------------------------------
  // DOFSection

  void DOFSection::AddData(void *data, size_t length) {
    if (this->data == NULL) {
      this->data = (char *) malloc(1);
    }
    this->data = (char *) realloc((void *)this->data, this->size + length);
    (void) memcpy(this->data + this->size, data, length);
    this->size += length;
  }

  void *DOFSection::Header() {
    dof_sec_t header;
    memset(&header, 0, sizeof(header));
    
    header.dofs_flags	= this->flags;
    header.dofs_type	= this->type;
    header.dofs_offset	= this->offset;
    header.dofs_size	= this->size;
    header.dofs_entsize = this->entsize;
    header.dofs_align	= this->align;

    void *dof = malloc(sizeof(dof_sec_t));
    memcpy(dof, &header, sizeof(dof_sec_t));
    
    return dof;
  }

  // --------------------------------------------------------------------
  // DTraceProbeDef
  
  uint8_t DTraceProbeDef::Argc() {
    uint8_t argc = 0;
    for (int i = 0; this->types[i] != NULL && i < 6; i++)
      argc++;
    return argc;
  }

  extern "C" void
  init(Handle<Object> target) {
    DTraceProvider::Initialize(target);
  }
  
} // namespace node

#endif // _HAVE_DTRACE
