#include <node.h>
#include <node_object_wrap.h>
#include <v8.h>

#ifdef _HAVE_DTRACE

#include <sys/dtrace.h>
#include <sys/types.h>
#include <sys/mman.h>

#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#ifndef __APPLE__
#include <stdlib.h>
#include <malloc.h>
#endif
    
#ifdef __APPLE__	
#define FUNC_SIZE 32
#define IS_ENABLED_FUNC_LEN 12
#else
#define FUNC_SIZE 96
#define IS_ENABLED_FUNC_LEN 32
#endif

#define ARGTYPE_INT  1
#define ARGTYPE_CHAR 2

namespace node {

  using namespace v8;

  class DTraceProbe {
    
  public:
    dof_stridx_t name;
    dof_stridx_t func;
    dof_stridx_t nargv;
    dof_stridx_t xargv;
    uint16_t noffs;
    uint32_t enoffidx;
    uint32_t argidx;
    uint16_t nenoffs;
    uint32_t offidx;
    uint8_t nargc;
    uint8_t xargc;
    void *addr;
    DTraceProbe *next;
    int types[6];

    DTraceProbe() {
      next = NULL;
    }
    
    ~DTraceProbe() {
      free(addr);
    }

    void *Dof();
    uint32_t ProbeOffset(char *dof, uint8_t argc);
    uint32_t IsEnabledOffset(char *dof);
    void CreateTracepoints();
    void Fire(Local<Array> a);
  };

  class DTraceProbeDef {

  public:
    char *function;
    char *types[7];
    char *name;
    DTraceProbe *probe;
    DTraceProbeDef *next;

    DTraceProbeDef() {
      next     = NULL;
      name     = NULL;
      function = NULL;
      probe    = NULL;
    }
    
    uint8_t Argc();

    ~DTraceProbeDef() {
      delete probe;
      delete next;
      free(name);
      for (int i = 0; (types[i] != NULL && i < 7); i++)
        free(types[i]);
    }

  private:
  };
  
  class DOFSection {
    
  public:
    dof_secidx_t index;
    uint32_t type;
    uint32_t flags;
    uint32_t align;
    uint64_t offset;
    uint64_t size;
    uint32_t entsize;    
    size_t pad;
    DOFSection *next;
    
    char *data;

    DOFSection(uint32_t type, dof_secidx_t index) {
      this->type    = type;
      this->index   = index;
      this->flags   = DOF_SECF_LOAD;
      this->offset  = 0;
      this->size    = 0;
      this->entsize = 0;
      this->pad	    = 0;
      this->next    = NULL;
      this->data    = NULL;
      
      switch(type) {
      case DOF_SECT_COMMENTS: this->align = 1; break;
      case DOF_SECT_STRTAB:   this->align = 1; break;
      case DOF_SECT_PROBES:   this->align = 8; break;
      case DOF_SECT_PRARGS:   this->align = 1; break;
      case DOF_SECT_PROFFS:   this->align = 4; break;
      case DOF_SECT_PRENOFFS: this->align = 4; break;
      case DOF_SECT_PROVIDER: this->align = 4; break;
      case DOF_SECT_UTSNAME:  this->align = 1; break;
      }
    }
    
    void AddData(void *data, size_t length);
    void *Header();
    
    ~DOFSection() {
      free(data);
      delete(next);
    }
    
  private:
  };

  class DOFFile {
    
  public:
    char *dof;
    
    DOFFile(size_t size) {
      sections = NULL;
      this->size = size;
      dof = (char *) malloc(size);
    }

    void AppendSection(DOFSection *);
    void Generate();
    void Load();

    ~DOFFile() {
      free(dof);
      delete(sections);
    }
    
  private:
    int gen;
    size_t size;
    DOFSection *sections;
  };

  class DOFStrtab : public DOFSection {

  public:

    DOFStrtab(int index) : DOFSection(DOF_SECT_STRTAB, index) {
      data = NULL;
    }

    int Add(char *string);
    
    ~DOFStrtab() {
      // data freed by superclass
    }
    
  private:
    int strindex;
  };

  class DTraceProvider : ObjectWrap {

  public:
    static void Initialize(v8::Handle<v8::Object> target);
    char *name;
    DTraceProbeDef *probe_defs;
    DTraceProbe *probes;
    DOFFile *file;

    static v8::Handle<v8::Value> New(const v8::Arguments& args);
    static v8::Handle<v8::Value> AddProbe(const v8::Arguments& args);
    static v8::Handle<v8::Value> Enable(const v8::Arguments& args);
    static v8::Handle<v8::Value> Fire(const v8::Arguments& args);
    
  DTraceProvider() : ObjectWrap() {
      name = NULL;
      probe_defs = NULL;
      probes = NULL;
      file = NULL;
    }

    ~DTraceProvider() {
      // disable provider first!

      free(name);
      delete(file);
      delete(probe_defs);
    }
    
  private:
    void AppendProbe(DTraceProbe *);
    size_t DofSize(DOFStrtab *);
  };  
  
  void InitDTraceProvider(v8::Handle<v8::Object> target);
}

#endif // _HAVE_DTRACE
