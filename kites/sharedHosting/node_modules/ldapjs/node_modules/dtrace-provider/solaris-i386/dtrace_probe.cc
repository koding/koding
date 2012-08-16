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

    p.dofpr_addr     = (uint32_t) this->addr;
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
    return (32 + 6 + (argc * 3));
  }

  uint32_t DTraceProbe::IsEnabledOffset(char *dof) {
    return (8);
  }

  void DTraceProbe::CreateTracepoints() {
    
    addr = (void *) memalign(PAGESIZE, FUNC_SIZE);
    (void)mprotect((void *)addr, FUNC_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC);

    uint8_t is_enabled[FUNC_SIZE] = {
      0x55, 0x89, 0xe5, 0x83,
      0xec, 0x08, 0x33, 0xc0,
      0x90, 0x90, 0x90, 0x89,
      0x45, 0xfc, 0x83, 0x7d,
      0xfc, 0x00, 0x0f, 0x95,
      0xc0, 0x0f, 0xb6, 0xc0,
      0x89, 0x45, 0xfc, 0x8b,
      0x45, 0xfc, 0xc9, 0xc3,
    };
    memcpy(addr, is_enabled, FUNC_SIZE);
    
    switch(nargc) {
    case 0:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0x90, 0x90,
	  0x90, 0x90, 0x90, 0x83,
	  0xc4, 0x00, 0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 1:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x08, 0x90, 0x90, 0x90,
	  0x90, 0x90, 0x83, 0xc4,
	  0x00, 0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 2:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x0c, 0xff, 0x75, 0x08,
	  0x90, 0x90, 0x90, 0x90,
	  0x90, 0x83, 0xc4, 0x00,
	  0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 3:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x10, 0xff, 0x75, 0x0c,
	  0xff, 0x75, 0x08, 0x90,
	  0x90, 0x90, 0x90, 0x90,
	  0x83, 0xc4, 0x00, 0xc9,
	  0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 4:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x14, 0xff, 0x75, 0x10,
	  0xff, 0x75, 0x0c, 0xff, 
	  0x75, 0x08, 0x90, 0x90,
	  0x90, 0x90, 0x90, 0x83,
	  0xc4, 0x00, 0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 5:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x18, 0xff, 0x75, 0x14,
	  0xff, 0x75, 0x10, 0xff,
	  0x75, 0x0c, 0xff, 0x75,
	  0x08, 0x90, 0x90, 0x90,
	  0x90, 0x90, 0x83, 0xc4,
	  0x00, 0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    case 6:
      {
	uint8_t probe[FUNC_SIZE] = {
	  0x55, 0x89, 0xe5, 0x83,
	  0xec, 0x08, 0xff, 0x75,
	  0x1c, 0xff, 0x75, 0x18,
	  0xff, 0x75, 0x14, 0xff,
	  0x75, 0x10, 0xff, 0x75,
	  0x0c, 0xff, 0x75, 0x08,
	  0x90, 0x90, 0x90, 0x90,
	  0x90, 0x83, 0xc4, 0x00,
	  0xc9, 0xc3
	};
	memcpy((uint8_t *)addr + 32, probe, FUNC_SIZE - 32);
      }
      break;
    }
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
	argv[i] = (void *)(int)a->Get(i)->ToInteger()->Value();
      }
    }

    switch (nargc) {
    case 0:
      func0 = (void (*)())((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func0)();
      break;
    case 1:
      func1 = (void (*)(void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func1)(argv[0]);
      break;
    case 2:
      func2 = (void (*)(void *, void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func2)(argv[0], argv[1]);
      break;
    case 3:
      func3 = (void (*)(void *, void *, void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func3)(argv[0], argv[1], argv[2]);
      break;
    case 4:
      func4 = (void (*)(void *, void *, void *, void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func4)(argv[0], argv[1], argv[2], argv[3]);
      break;
    case 5:
      func5 = (void (*)(void *, void *, void *, void *, void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func5)(argv[0], argv[1], argv[2], argv[3], argv[4]);
      break;
    case 6:
      func6 = (void (*)(void *, void *, void *, void *, void *, void *))((uint32_t)addr + IS_ENABLED_FUNC_LEN); 
      (void)(*func6)(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
      break;
    }

    for (int i = 0; i < nargc; i++)
      if (types[i] == ARGTYPE_CHAR)
	free(argv[i]);

  }
  
} // namespace node
