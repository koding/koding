// FileDescriptor.hh
// This file is part of libpbe; see http://anyterm.org/
// (C) 2006-2007 Philip Endecott

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#ifndef libpbe_FileDescriptor_hh
#define libpbe_FileDescriptor_hh

#include "Exception.hh"
#include "missing_syscalls.hh"
#include "compiler_magic.hh"

#include <boost/lexical_cast.hpp>
#include <boost/noncopyable.hpp>
#include <boost/scoped_array.hpp>

#include <cmath>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/uio.h>

#include <ext/stdio_filebuf.h>


namespace pbe {

class FileDescriptor: public boost::noncopyable {
// C++ wrapper around the traditional POSIX file descriptor.
// Some methods are simple wrappers around a standard POSIX library 
// function.  In addition there is a rich set of read/write methods and 
// an easy to use wrapper for select().
// In all cases, exceptions are used to report error conditions.

protected:
  const int fd;
  const std::string fn;
  const bool close_on_destr;

public:
  enum open_mode_t { read_only=O_RDONLY, read_write=O_RDWR, write_only=O_WRONLY,
                     create=O_WRONLY|O_CREAT };

  FileDescriptor(std::string fn_, open_mode_t open_mode):
  // Constructor that opens a file given a file name and an access mode.
  // The file will be closed when the FileDescriptor is destructed.
  // I set close-on-exec for all FileDescriptors, since this seems like the
  // sensible default for me.
    fd(open(fn_.c_str(),open_mode,0666)),
    fn('"'+fn_+'"'),
    close_on_destr(true)
  {
    if (fd==-1) {
      throw_ErrnoException("open("+fn+")");
    }
    // Set close-on-exec.
    // There is a race condition here: if another thread has forked
    // between the calls to open and fcntl, it will get the fd, which is
    // bad.  It may be fixable in the future if we get O_CLOEXEC.
    // See http://lwn.net/Articles/236486/.
    int rc = fcntl(fd,F_SETFD,FD_CLOEXEC);
    if (rc==-1) {
      throw_ErrnoException("fcntl("+fn+",F_SETFD,FD_CLOEXEC)");
    }
  }

  FileDescriptor(int fd_, bool close_on_destr_=true):
  // Constructor that takes an existing file descriptor.
  // The file will be closed when the FileDescriptor is destructed 
  // unless the optional close_on_destr_ parameter is false.
    fd(fd_),
    fn("fd"+boost::lexical_cast<std::string>(fd)),
    close_on_destr(close_on_destr_)
  {
  }

  FileDescriptor(int fd_, std::string fn_, bool close_on_destr_=true):
  // Constructor that takes an existing file descriptor.
  // A name, for use in error messages, is supplied.
  // The file will be closed when the FileDescriptor is destructed 
  // unless the optional close_on_destr_ parameter is false.
    fd(fd_),
    fn(fn_),
    close_on_destr(close_on_destr_)
  {
  }

  ~FileDescriptor() {
    if (close_on_destr) {
      int rc = ::close(fd);
      if (rc==-1) {
        //throw_ErrnoException("close("+fn+")");
        // Don't throw exceptions from destructors, in case the destructor is being 
        // called during exception processing.
        // TODO need a better fix for this.
      }
    }
  }


  void close() {
  // Call close.  This is only necessary if the user wants to close the fd before
  // it goes out of scope for some reason; further operations on it are obviously
  // not allowed.  It also has the benefit of checking the return value, which
  // the destructor does not do.
    int rc = ::close(fd);
    if (rc==-1) {
      throw_ErrnoException("close("+fn+")");
    }
  }


  //
  // Various implementation of READ:
  //

  size_t read(char* buf, size_t max_bytes) {
  // Directly provides almost the functionality of the read system call.
  // At most max_bytes are read into the buffer.  Fewer bytes may be
  // read at EOF, when a socket has less data waiting, etc.  The number 
  // of bytes actually read is returned.
  // If EINTR is returned, the call is retried.
    while (1) {
      ssize_t n = ::read(fd,buf,max_bytes);
      if (n==-1) {
        if (errno==EINTR) {
          continue;
        }
        throw_ErrnoException("read("+fn+")");
      }
      return n;
    }
  }

  std::string read(size_t max_bytes) {
  // Provides the functionality of the read sytem call, but returns 
  // the data in a std::string.  At most max_bytes are read and returned.  
  // Fewer bytes may be read at EOF, when a socket has less data waiting, 
  // etc.
    boost::scoped_array<char> buf(new char[max_bytes]);
    size_t bytes = read(buf.get(),max_bytes);
    return std::string(buf.get(),bytes);
  }

  class EndOfFile: public StrException {
   public:
    EndOfFile(): StrException("EOF") {};
  };

  void readall(char* buf, size_t bytes) {
  // Reads exactly bytes bytes into the buffer, making more than one 
  // call to read as necessary.  Throws EOF if end-of-file is reached 
  // before the required number of bytes has been read.
    while (bytes>0) {
      size_t n = read(buf,bytes);
      if (n==0) {
        throw EndOfFile();
      }
      buf += n;
      bytes -= n;
    }
  }

  std::string readall(size_t bytes) {
  // Reads exactly bytes bytes from the file descriptor and returns them 
  // as a std::string, making more than one call to read as necessary.  
  // Throws EOF if end-of-file is reached before the required number of 
  // bytes has been read.
    boost::scoped_array<char> buf(new char[bytes]);
    readall(buf.get(),bytes);
    return std::string(buf.get(),bytes);
  }

  size_t readmax(char* buf, size_t bytes) {
  // Reads exactly bytes bytes into the buffer, making more than one 
  // call to read as necessary, unless end-of-file is reached before
  // the required number of bytes has been read, in which case all the
  // available bytes are read.  The number of bytes read is returned.
    size_t bytes_read = 0;
    while (bytes>0) {
      size_t n = read(buf,bytes);
      if (n==0) {
        return bytes_read;
      }
      bytes_read += n;
      buf += n;
      bytes -= n;
    }
    return bytes_read;
  }

  std::string readmax(size_t bytes) {
  // Reads exactly bytes bytes from the file descriptor and returns them 
  // as a std::string, making more than one call to read as necessary,
  // unless end-of-file is reached before the required number of bytes
  // has been read, in which case all the available bytes are read.
    boost::scoped_array<char> buf(new char[bytes]);
    size_t bytes_read = readmax(buf.get(),bytes);
    return std::string(buf.get(),bytes_read);
  }

  std::string readsome(void) {
  // Reads an unspecified number of bytes from the file descriptor and 
  // returns them as a std::string.  Use this call if you want to 
  // process the contents of the file in chunks and don't care about 
  // the chunk size.
  // Currently returns an empty string at EOF; should it throw EndOfFile?
  // (No - readall() below relies on it returning an empty string.)
    char buf[BUFSIZ];
    int bytes = read(buf,BUFSIZ);
    return std::string(buf,bytes);
  }
 
  std::string readall() {
  // Reads everything from the file descriptor until no more data is available 
  // (i.e. end of file)
    std::string s;
    std::string some;
    while ((some=readsome()) != "") {
      s += some;
    }
    return s;
  }

  template <typename T>
  void binread(T& t) {
  // Read and return a thing of type T in binary format.
    char* ptr = reinterpret_cast<char*>(&t);
    readall(ptr,sizeof(t));
  }

  template <typename T>
  T binread(void) {
  // Read and return a thing of type T in binary format.
    T t;
    binread(t);
    return t;
  }

  template <typename T>
  void binread_at(off_t pos, T& t) {
  // Read and return a thing of type T in binary format at position pos in the file.
    seek(pos);
    binread(t);
  }

  std::string read_until_idle(float timeout) {
  // Read something, and then keep reading until nothing more has been 
  // read for at least timeout.
    std::string s = readsome();
    while (wait_until(readable(),timeout)) {
      s += readsome();
    }
    return s;
  }

  void set_nonblocking() {
  // Calls fcntl to make an open fd non-blocking on subsequent reads and writes.
    int flags = fcntl(fd,F_GETFL);
    flags |= O_NONBLOCK;
    int rc = fcntl(fd,F_SETFL,flags);
    if (rc==-1) {
      throw_ErrnoException("fcntl("+fn+",F_SETFL,|O_NONBLOCK)");
    }
  }

  void set_blocking() {
  // Calls fcntl to make an open fd blocking on subsequent reads and writes.
    int flags = fcntl(fd,F_GETFL);
    flags &=~ O_NONBLOCK;
    int rc = fcntl(fd,F_SETFL,flags);
    if (rc==-1) {
      throw_ErrnoException("fcntl("+fn+",F_SETFL,&~O_NONBLOCK)");
    }
  }

  class scoped_nonblocking {
    FileDescriptor& fd;
  public:
    scoped_nonblocking(FileDescriptor& fd_): fd(fd_) {
      fd.set_nonblocking();
    }
    ~scoped_nonblocking() {
      fd.set_blocking();  // FIXME maybe it was already nonblocking!
    }
  };

  size_t try_read(char* buf, size_t max_bytes, bool& readable) {
  // Directly provides the functionality of the read system call.
  // At most max_bytes are read into the buffer.  Fewer bytes may be
  // read at EOF, when a socket has less data waiting, etc.  Zero bytes
  // will be read if no data is waiting and the operation would block.
  // The number of bytes actually read is returned, and readable is
  // set to indicate whether the file was readable.  (If the return
  // value is zero and readable is true, we're at EOF.)
    scoped_nonblocking nb(*this);
    ssize_t n = ::read(fd,buf,max_bytes);
    // FIXME what about EINTR?
    if (n==-1) {
      if (errno==EAGAIN) {
        readable = false;
        return 0;
      }
      throw_ErrnoException("read("+fn+")");
    }
    readable = true;
    return n;
  }

  bool try_readall(char* buf, size_t bytes) {
  // Try to read exactly bytes bytes into the buffer, making more than one 
  // call to read as necessary.  Throws EOF if end-of-file is reached 
  // before the required number of bytes has been read.  Returns false if
  // the operation would block.  (Hmm, data will be discarded if a partial
  // read completes but a subsequent full read would block.)
    while (bytes>0) {
      bool readable;
      size_t n = try_read(buf,bytes,readable);
      if (!readable) {
        return false;
      }
      if (n==0) {
        throw EndOfFile();
      }
      buf += n;
      bytes -= n;
    }
    return true;
  }

  template <typename T>
  bool try_binread(T& t) {
  // Try to read a thing of type T in binary format.  If the operation would block
  // (e.g. a serial port or socket with insifficient data currently available)
  // return false immediately.
    char* ptr = reinterpret_cast<char*>(&t);
    return try_readall(ptr,sizeof(t));
  }

  std::string try_readsome(void) {
  // Tries to reads an unspecified number of bytes from the file descriptor and 
  // returns them as a std::string.  If nothing can be read at present, returns an
  // empty string.
    char buf[BUFSIZ];
    bool readable;
    int bytes = try_read(buf,BUFSIZ,readable);
    return std::string(buf,bytes);
  }

  //
  // Various implementations of WRITE:
  //

  size_t write(const char* buf, size_t max_bytes) PBE_WARN_RESULT_IGNORED {
  // Directly provides the functionality of the write system call.
  // At most max_bytes are written from the buffer.  Fewer bytes may be
  // written under various circumstances.  The number of bytes actually
  // written is returned.
    ssize_t n = ::write(fd,buf,max_bytes);
    if (n==-1) {
      throw_ErrnoException("write("+fn+")");
    }
    return n;
  }
 
  size_t write(std::string s) PBE_WARN_RESULT_IGNORED {
  // Provides the functionality of the write system call, but with the data 
  // coming from a std::string.  Not all of the data may be written under 
  // various circumstances.  The number of bytes actually written is 
  // returned.
    return write(s.data(),s.length());
  }

  void writeall(const char* buf, size_t bytes) {
  // Write all bytes bytes from buf, making repeated calls to write
  // as necessary.
    while (bytes>0) {
      ssize_t n = write(buf,bytes);
      if (n==-1) {
	throw_ErrnoException("write("+fn+")");
      }
      // What happens if 0 bytes are written?
      buf += n;
      bytes -= n;
    }
  }

  void writeall(std::string s) {
  // Write all of string s, making repeated calls to write as necessary.
    writeall(s.data(),s.length());
  }

  template <typename T>
  void binwrite(const T& t) {
  // Write a thing of type T in binary format.
    const char* ptr = reinterpret_cast<const char*>(&t);
    writeall(ptr,sizeof(T));
  }

  template <typename T>
  void binwrite_at(off_t pos, const T& t) {
  // Write a thing of type T in binary format at position pos in the file.
    seek(pos);
    binwrite(t);
  }

  void writeallv2(const char* buf1, size_t bytes1, const char* buf2, size_t bytes2) {
  // Writes all bytes from buf1 and all bytes from buf2 using the writev system call.
    iovec v[2];
    v[0].iov_base = const_cast<char*>(buf1);
    v[0].iov_len = bytes1;
    v[1].iov_base = const_cast<char*>(buf2);
    v[1].iov_len = bytes2;
    size_t bytes_written = 0;
    while (1) {
      int rc = writev(fd,v,2);
      if (rc==-1) {
        throw_ErrnoException("writev("+fn+")");
      }
      bytes_written += rc;
      if (bytes_written == bytes1+bytes2) {
        return;
      }
      if (bytes_written >= bytes1) {
        break;
      }
      v[0].iov_base = static_cast<char*>(v[0].iov_base)+rc;
      v[0].iov_len -= rc;
    }
    writeall(buf2+bytes_written-bytes1, bytes1+bytes2-bytes_written);
  }
  

  int dup() {
  // Directly provides the functionality of the dup() system call.
  // The duplicate file descriptor is returned as an int, not as a FileDesriptor 
  // object.  A FileDescriptor object can of course be constructed from the int.
    int d = ::dup(fd);
    if (d==-1) {
      throw_ErrnoException("dup("+fn+")");
    }
    return d;
  }

// The following code allows a C++ stream to be created from a
// file descriptor.  This relies on a non-standard extension in
// GNU libstdc++.  Not only is this non-standard, but it has
// changed slightly in different versions of the library.
// The following is known to work with g++ 3.4.4, and hopefully
// newer versions.  If you have an earlier version that works
// with this please let me know.
#if __GLIBCXX__ >= 20050421
#define LIBPBE_HAS_FILEDESCRIPTOR_STREAMS

  class istream: public std::istream {
  private:
    __gnu_cxx::stdio_filebuf<char> fbuf;
  public:
    istream(FileDescriptor& fd, int bufsize=BUFSIZ):
      fbuf(fd.dup(), std::ios::in, bufsize)
    {
      rdbuf(&fbuf);
    }
  };

  class ostream: public std::ostream {
  private:
    __gnu_cxx::stdio_filebuf<char> fbuf;
  public:
    ostream(FileDescriptor& fd, int bufsize=BUFSIZ):
      fbuf(fd.dup(), std::ios::out, bufsize)
    {
      rdbuf(&fbuf);
    }
  };

// The following should work with gcc 3.3.
// Note that the libstdc++ version symbol has changed from __GLIBCPP__
// to __GLIBCXX__ at some point.
// If you have an earlier or later version that works with this
// please let me know.
#elif (__GLIBCPP__ >= 20040214) && (__GLIBCPP__ <= 20050503)
#define LIBPBE_HAS_FILEDESCRIPTOR_STREAMS

  class istream: public std::istream {
  private:
    __gnu_cxx::stdio_filebuf<char> fbuf;
  public:
    istream(FileDescriptor& fd, int bufsize=BUFSIZ):
      std::istream(&fbuf),
      fbuf(fd.dup(), std::ios::in, true, bufsize)
      // (I'm concerned about the order of construction here)
    {}
  };

  class ostream: public std::ostream {
  private:
    __gnu_cxx::stdio_filebuf<char> fbuf;
  public:
    ostream(FileDescriptor& fd, int bufsize=BUFSIZ):
      std::ostream(&fbuf),
      fbuf(fd.dup(), std::ios::out, true, bufsize)
      // ditto
    {}
  };

#endif
// Information about and/or patches for other versions of g++ are welcome.


  void set_nodelay() {
  // Calls setscokopt to disable Nagle's algorithm for this socket.
    int flag = 1;
    int rc = setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
    if (rc==-1) {
      throw_ErrnoException("setsockopt("+fn+",TCP_NODELAY)");
    }
  }


  struct in_addr get_peer_ip_addr() {
  // For an fd that is a socket, finds the IP address of the other end of the 
  // connection.
  // For a non-socket, returns the loopback address.
    struct sockaddr_in client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    int rc = getpeername(fd, (struct sockaddr*)&client_addr,
                         &client_addr_len);
    if (rc==-1) {
      if (errno==ENOTSOCK) {
        struct in_addr a;
        a.s_addr = htonl(INADDR_LOOPBACK);
        return a;
      } else {
        throw_ErrnoException("getpeername("+fn+")");
      }
    }
    if (client_addr.sin_family!=AF_INET) {
      throw "socket is not an AF_INET socket";
    }
    return client_addr.sin_addr;
  }


  template <typename T>
  int ioctl(int request, T* argp) {
  // Directly provides the functionality of the ioctl system call.
    int rc = ::ioctl(fd, request, reinterpret_cast<char*>(argp));
    if (rc==-1) {
      throw_ErrnoException("ioctl("+boost::lexical_cast<std::string>(request)+","+fn+")");
    }
    return rc;
  }

  template <typename T>
  int ioctl(int request, T& arg) {
    return ioctl(request,&arg);
  }

  int ioctl(int request) {
  // ioctl with no data.
    return ioctl<void>(request,NULL);
  }


  template <typename T>
  int try_ioctl(int request, T* argp, bool& done) {
  // Directly provides the functionality of the ioctl system call, non-blocking;
  // done is false if the ioctl would block.
    int rc = ::ioctl(fd, request, reinterpret_cast<char*>(argp));
    if (rc==-1) {
      if (errno==EAGAIN) {
        done = false;
        return 0;
      }
      throw_ErrnoException("ioctl("+boost::lexical_cast<std::string>(request)+","+fn+")");
    }
    done = true;
    return rc;
  }

  template <typename T>
  int try_ioctl(int request, T& arg, bool& done) {
    return try_ioctl(request,&arg,done);
  }

  int try_ioctl(int request, bool& done) {
  // try_ioctl with no data.
    return try_ioctl<void>(request,NULL,done);
  }


  void get_sigio(void)
  // Ask the kernel to send this process or thread SIGIO when this fd becomes
  // readable or writable.
  {
    int r = fcntl(fd,F_SETOWN,getpid());  // should be gettid
    if (r==-1) {
      throw_ErrnoException("fcntl("+fn+",F_SETOWN)");
    }
    r = fcntl(fd,F_SETFL,O_ASYNC);
    if (r==-1) {
      throw_ErrnoException("fnctl("+fn+",F_SETFL,O_ASYNC)");
    }
  }


  enum whence_t {seek_set=SEEK_SET, seek_cur=SEEK_CUR, seek_end=SEEK_END};

  off_t seek(off_t offset, whence_t whence = seek_set) {
  // Directly provides the functionality of the lseek() system call.
  // By default the offset is interpretted relative to the start of the file.
    off_t r = lseek(fd,offset,whence);
    if (r==(off_t)-1) {
      throw_ErrnoException("lseek("+fn+")");
    }
    return r;
  }


  off_t getpos() {
    return seek(0,seek_cur);
  }

  off_t file_length() {
    // Returns the length of the file.  This is done by seeking to the end.
    off_t pos = getpos();
    off_t len = seek(0,seek_end);
    seek(pos);
    return len;
  }


  void* mmap(size_t length, open_mode_t open_mode, off_t offset = 0, bool copy_on_write=false) {
    int prot = 0;
    if (open_mode == read_only || open_mode == read_write) {
      prot |= PROT_READ;
    }
    if (open_mode == write_only || open_mode == read_write) {
      prot |= PROT_WRITE;
    }
    void* ptr = ::mmap(0, length, prot, copy_on_write ? MAP_PRIVATE : MAP_SHARED, fd, offset);
    if (ptr==MAP_FAILED) {
      throw_ErrnoException("mmap("+fn+")");
    }
    return ptr;
  }


  void truncate(off_t length) {
    int rc = ftruncate(fd,length);
    if (rc==-1) {
      throw_ErrnoException("truncate("+fn+")");
    }
  }


  void sync() {
    int rc = ::fsync(fd);
    if (rc==-1) {
      throw_ErrnoException("fsync("+fn+")");
    }
  }

#if ! (defined __FreeBSD__ || defined __OpenBSD__ || defined __APPLE__)
// These systems don't have fdatasync
  void datasync() {
    int rc = ::fdatasync(fd);
    if (rc==-1) {
      throw_ErrnoException("fdatasync("+fn+")");
    }
  }
#endif


private:

  struct select_item_readable {
    const int fd;
    select_item_readable(int fd_): fd(fd_) {}
  };

  struct select_item_writeable {
    const int fd;
    select_item_writeable(int fd_): fd(fd_) {}
  };

  struct select_item_exception {
    const int fd;
    select_item_exception(int fd_): fd(fd_) {}
  };

  class select_info {
  private:
    fd_set readfds;
    fd_set writefds;
    fd_set exceptfds;
    int max_fd;

  public:
    void clear() {
      FD_ZERO(&readfds);
      FD_ZERO(&writefds);
      FD_ZERO(&exceptfds);
      max_fd=0;
    }

    void set_readable(int fd) {
      FD_SET(fd,&readfds);
      max_fd=std::max(max_fd,fd);
    }

    void set_writeable(int fd) {
      FD_SET(fd,&writefds);
      max_fd=std::max(max_fd,fd);
    }

    void set_exception(int fd) {
      FD_SET(fd,&exceptfds);
      max_fd=std::max(max_fd,fd);
    }

    select_info(select_item_readable i) {
      clear();
      set_readable(i.fd);
    }

    select_info(select_item_writeable i) {
      clear();
      set_writeable(i.fd);
    }

    select_info(select_item_exception i) {
      clear();
      set_exception(i.fd);
    }

    friend int wait_until_(FileDescriptor::select_info, struct timeval*);
  };


public:

  select_item_readable readable() const {
    return select_item_readable(fd);
  }
  select_item_writeable writeable() const {
    return select_item_writeable(fd);
  }
  select_item_exception exception() const {
    return select_item_exception(fd);
  }

  friend select_info operator||(select_info, select_item_readable);
  friend select_info operator||(select_info, select_item_writeable);
  friend select_info operator||(select_info, select_item_exception);
  friend int wait_until_(FileDescriptor::select_info, struct timeval*);
  friend int wait_until(FileDescriptor::select_info);
  friend int wait_until(FileDescriptor::select_info, float);


  bool operator==(int rhs) const {
    return fd==rhs;
  }

  bool operator==(const FileDescriptor& rhs) const {
    return fd==rhs.fd;
  }


};


inline FileDescriptor::select_info
operator||(FileDescriptor::select_info lhs,
           FileDescriptor::select_item_readable rhs)  {
  FileDescriptor::select_info i = lhs;
  i.set_readable(rhs.fd);
  return i;
}

inline FileDescriptor::select_info
operator||(FileDescriptor::select_info lhs,
           FileDescriptor::select_item_writeable rhs)  {
  FileDescriptor::select_info i = lhs;
  i.set_writeable(rhs.fd);
  return i;
}

inline FileDescriptor::select_info
operator||(FileDescriptor::select_info lhs,
           FileDescriptor::select_item_exception rhs)  {
  FileDescriptor::select_info i = lhs;
  i.set_exception(rhs.fd);
  return i;
}


inline int wait_until_(FileDescriptor::select_info i, struct timeval* tv) {
  int rc;
  do {
    rc = select(i.max_fd+1, &i.readfds, &i.writefds, &i.exceptfds, tv);
    if (rc==-1) {
      if (errno==EINTR) {
        continue;
      }
      throw_ErrnoException("select()");
    }
  } while (0);

  if (rc==0) {
    return -1;
  }
  for (int n=0; n<=i.max_fd; n++) {
    if (FD_ISSET(n,&i.readfds) || FD_ISSET(n,&i.writefds)
        || FD_ISSET(n,&i.exceptfds)) {
      return n;
    }
  }
  throw "not reached";
}

inline int wait_until(FileDescriptor::select_info i) {
  // Returns a file descriptor number that changed.
  return wait_until_(i,NULL);
}

inline int wait_until(FileDescriptor::select_info i,
                      float timeout) {
  // Returns -1 if timed out, else a file descriptor number that changed.
  struct timeval tv;
  float timeout_whole;
  float timeout_frac;
  timeout_frac = modff(timeout, &timeout_whole);
  tv.tv_sec = static_cast<int>(timeout_whole);
  tv.tv_usec = static_cast<int>(1000000.0*timeout_frac);
  return wait_until_(i,&tv);
}

};


#endif
