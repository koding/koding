#include "dtrace_provider.h"
#include <v8.h>

#include <node.h>

#ifdef _HAVE_DTRACE

namespace node {
  
  using namespace v8;
  
  // --------------------------------------------------------------------
  // DOFFile

  static uint8_t dof_version(uint8_t header_version) {
    uint8_t dof_version;
    /* DOF versioning: Apple always needs version 3, but Solaris can use
       1 or 2 depending on whether is-enabled probes are needed. */
#ifdef __APPLE__
    dof_version = DOF_VERSION_3;
#else
    switch(header_version) {
    case 1:
      dof_version = DOF_VERSION_1;
      break;
    case 2:
      dof_version = DOF_VERSION_2;
      break;
    default:
      dof_version = DOF_VERSION;
    }
#endif
    return dof_version;
  } 

  void DOFFile::AppendSection(DOFSection *section) {
    if (this->sections == NULL)
      this->sections = section;
    else {
      DOFSection *s;
      for (s = this->sections; (s->next != NULL); s = s->next) ;
      s->next = section;
    }
  } 

  void DOFFile::Generate() {
    dof_hdr_t header;
    memset(&header, 0, sizeof(header));

    header.dofh_ident[DOF_ID_MAG0] = DOF_MAG_MAG0;
    header.dofh_ident[DOF_ID_MAG1] = DOF_MAG_MAG1;
    header.dofh_ident[DOF_ID_MAG2] = DOF_MAG_MAG2;
    header.dofh_ident[DOF_ID_MAG3] = DOF_MAG_MAG3;
	  
    header.dofh_ident[DOF_ID_MODEL]    = DOF_MODEL_NATIVE;
    header.dofh_ident[DOF_ID_ENCODING] = DOF_ENCODE_NATIVE;
    header.dofh_ident[DOF_ID_DIFVERS]  = DIF_VERSION;
    header.dofh_ident[DOF_ID_DIFIREG]  = DIF_DIR_NREGS;
    header.dofh_ident[DOF_ID_DIFTREG]  = DIF_DTR_NREGS;

    header.dofh_ident[DOF_ID_VERSION] = dof_version(2); /* default 2, will be 3 on OSX */
    header.dofh_hdrsize = sizeof(dof_hdr_t);
    header.dofh_secsize = sizeof(dof_sec_t);
    header.dofh_secoff = sizeof(dof_hdr_t);

    header.dofh_secnum = 6; // count of sections

    uint64_t filesz = sizeof(dof_hdr_t) + (sizeof(dof_sec_t) * header.dofh_secnum);
    uint64_t loadsz = filesz;

    for (DOFSection *section = this->sections; section != NULL; section = section->next) {
      size_t pad = 0;
      section->offset = filesz;

      if (section->align > 1) {
	size_t i = section->offset % section->align;
	if (i > 0) {
	  pad = section->align - i;
	  section->offset = (pad + section->offset);
	  section->pad = pad;
	}
      }

      filesz += section->size + pad;
      if (section->flags & 1)
	loadsz += section->size + pad;
    }

    header.dofh_loadsz = loadsz;
    header.dofh_filesz = filesz;
    memcpy(this->dof, &header, sizeof(dof_hdr_t));

    size_t offset = sizeof(dof_hdr_t);
    for (DOFSection *section = this->sections; section != NULL; section = section->next) {
      void *header = section->Header();
      (void) memcpy((this->dof + offset), header, sizeof(dof_sec_t));
      free(header);
      offset += sizeof(dof_sec_t);
    }

    for (DOFSection *section = this->sections; section != NULL; section = section->next) {
      if (section->pad > 0) {
	(void) memcpy((this->dof + offset), "\0", section->pad);
	offset += section->pad;
      }
      (void) memcpy((this->dof + offset), section->data, section->size);
      offset += section->size;
    }
  }

#ifdef __APPLE__
  static const char *helper = "/dev/dtracehelper";

  static int _loaddof(int fd, dof_helper_t *dh)
  {
    int ret;
    uint8_t buffer[sizeof(dof_ioctl_data_t) + sizeof(dof_helper_t)];
    dof_ioctl_data_t* ioctlData = (dof_ioctl_data_t*)buffer;
    user_addr_t val;

    ioctlData->dofiod_count = 1LL;
    memcpy(&ioctlData->dofiod_helpers[0], dh, sizeof(dof_helper_t));
    
    val = (user_addr_t)(unsigned long)ioctlData;
    ret = ioctl(fd, DTRACEHIOC_ADDDOF, &val);

    return ret;
  }

  static int _removedof(int fd, int gen)
  {
    return 0;
  }

#else /* Solaris */

  /* ignore Sol10 GA ... */
  static const char *helper = "/dev/dtrace/helper";

  static int _loaddof(int fd, dof_helper_t *dh)
  {
    return ioctl(fd, DTRACEHIOC_ADDDOF, dh);
  }

  static int _removedof(int fd, int gen)
  {
    return ioctl(fd, DTRACEHIOC_REMOVE, gen);
  }

#endif

  void DOFFile::Load() {
    dof_helper_t dh;
    int fd;
    dof_hdr_t *dof;
    dof = (dof_hdr_t *) this->dof;

    dh.dofhp_dof  = (uintptr_t)dof;
    dh.dofhp_addr = (uintptr_t)dof;
    (void) snprintf(dh.dofhp_mod, sizeof (dh.dofhp_mod), "module");

    fd = open(helper, O_RDWR);
    this->gen = _loaddof(fd, &dh);

    (void) close(fd);
  }

}; // namespace node

#endif // _HAVE_DTRACE
