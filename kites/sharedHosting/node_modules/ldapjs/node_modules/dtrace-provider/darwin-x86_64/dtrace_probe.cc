#include "../dtrace_provider.h"
#include <v8.h>

#include <node.h>

namespace node {
  
  using namespace v8;
  
  // --------------------------------------------------------------------
  // DTraceProbe

  void *DTraceProbe::Dof() {
    dof_probe_t p;
    memset(&p, 0, sizeof(p));

    p.dofpr_addr     = (uint64_t) this->addr;
    p.dofpr_func     = this->func;
    p.dofpr_name     = this->name;
    p.dofpr_nargv    = this->nargv;
    p.dofpr_xargv    = this->xargv;
    p.dofpr_argidx   = this->argidx;
    p.dofpr_offidx   = this->offidx;
    p.dofpr_nargc    = this->nargc;
    p.dofpr_xargc    = this->xargc;
    p.dofpr_noffs    = this->noffs;
    p.dofpr_enoffidx = this->enoffidx;
    p.dofpr_nenoffs  = this->nenoffs;

    void *dof = malloc(sizeof(dof_probe_t));
    memcpy(dof, &p, sizeof(dof_probe_t));

    return dof;
  }

  uint32_t DTraceProbe::ProbeOffset(char *dof, uint8_t argc) {
    return (uint32_t) ((uint64_t) this->addr - (uint64_t) dof + 18);
  }

  uint32_t DTraceProbe::IsEnabledOffset(char *dof) {
    return (uint32_t) ((uint64_t) this->addr - (uint64_t) dof + 6);
  }

  void DTraceProbe::CreateTracepoints() {
    
    addr = (void *) valloc(FUNC_SIZE);
    (void)mprotect((void *)addr, FUNC_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC);

    uint8_t tracepoints[FUNC_SIZE] = {
      0x55, 0x48, 0x89, 0xe5, 
      0x48, 0x33, 0xc0, 0x90, 
      0x90, 0xc9, 0xc3, 0x00,
      0x55, 0x48, 0x89, 0xe5, 
      0x90, 0x0f, 0x1f, 0x40, 
      0x00, 0xc9, 0xc3, 0x0f, 
      0x1f, 0x44, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00
    };

    memcpy(addr, tracepoints, FUNC_SIZE);
  }

  void DTraceProbe::Fire(Local<Array> a) {
    void *argv[6];

    void (*func0)();
    void (*func1)(void *);
    void (*func2)(void *, void *);
    void (*func3)(void *, void *, void *);
    void (*func4)(void *, void *, void *, void *);
    void (*func5)(void *, void *, void *, void *, void *);
    void (*func6)(void *, void *, void *, void *, void *, void *);
   
    for (int i = 0; i < nargc; i++) {
      if (types[i] == ARGTYPE_CHAR) {
	// char *
	String::AsciiValue str(a->Get(i)->ToString());
	argv[i] = (void *) strdup(*str);
      }
      else {
	// int
	argv[i] = (void *)(int) a->Get(i)->ToInteger()->Value();
      }
    }

    switch (nargc) {
    case 0:
      func0 = (void (*)())((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func0)();
      break;
    case 1:
      func1 = (void (*)(void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func1)(argv[0]);
      break;
    case 2:
      func2 = (void (*)(void *, void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func2)(argv[0], argv[1]);
      break;
    case 3:
      func3 = (void (*)(void *, void *, void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func3)(argv[0], argv[1], argv[2]);
      break;
    case 4:
      func4 = (void (*)(void *, void *, void *, void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func4)(argv[0], argv[1], argv[2], argv[3]);
      break;
    case 5:
      func5 = (void (*)(void *, void *, void *, void *, void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func5)(argv[0], argv[1], argv[2], argv[3], argv[4]);
      break;
    case 6:
      func6 = (void (*)(void *, void *, void *, void *, void *, void *))((uint64_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func6)(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
      break;
    }

    for (int i = 0; i < nargc; i++)
      if (types[i] == ARGTYPE_CHAR)
	free(argv[i]);

  }

} // namespace node
