#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT([Nodejs terminal], [0.1], [support@kodingen.com])

# Checks for programs.
AC_PROG_AWK
AC_PROG_CXX
AC_PROG_CC
AC_PROG_MAKE_SET
AC_PROG_CPP

# Checks for libraries.
AC_CHECK_LIB([pthread], [main])
AC_CHECK_LIB([util], [main])
AC_CHECK_LIB([zip],[main])
AC_CHECK_LIB([bz2], [main],[],[AC_MSG_ERROR([Cannot locate libbz2])])
AC_CHECK_HEADER([bzlib.h],[],[AC_MSG_ERROR([Cannot locate bzip2 header; please install bzip2-devel ;ex: yum install bzip2-devel])])

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([arpa/inet.h fcntl.h malloc.h netdb.h netinet/in.h stdint.h stdlib.h string.h strings.h sys/ioctl.h sys/socket.h sys/time.h syslog.h termios.h unistd.h utmp.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_C_INLINE
AC_TYPE_MODE_T
AC_TYPE_OFF_T
AC_TYPE_PID_T
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_STRUCT_TM
AC_C_VOLATILE
AC_CHECK_TYPES([ptrdiff_t])

# Checks for library functions.
AC_FUNC_CLOSEDIR_VOID
AC_FUNC_ERROR_AT_LINE
AC_FUNC_FORK
AC_PROG_GCC_TRADITIONAL
AC_FUNC_LSTAT
AC_FUNC_LSTAT_FOLLOWS_SLASHED_SYMLINK
AC_FUNC_MEMCMP
AC_FUNC_MKTIME
AC_FUNC_MMAP
AC_FUNC_SELECT_ARGTYPES
AC_TYPE_SIGNAL
AC_FUNC_STAT
AC_FUNC_STRFTIME
AC_FUNC_STRTOD
AC_CHECK_FUNCS([fdatasync ftruncate gethostname gettimeofday localtime_r memset mkdir modf munmap regcomp select setenv socket sqrt strerror strncasecmp strtol])
AC_CHECK_PROG(GIT, git, yes,no)
if test $GIT = no; then
        AC_MSG_ERROR([Cannot locate git, please make sure that git is installed])
        exit;
fi



AC_CHECK_PROG(NODEJS, node, yes,no)
if test $NODEJS = no; then
	AC_MSG_ERROR([Cannot locate nodejs, please make sure that nodejs is installed, see http://nodejs.org/ ])
	exit;
fi
AC_CHECK_PROG(NODEWAF, node-waf, yes,no)
if test $NODEWAF = no; then
	AC_MSG_ERROR([Cannot locate node-waf, please make sure that nodejs is installed, see http://nodejs.org/ ])
	exit;
fi
AC_CHECK_PROG(NPM, npm, yes,no)
if test $NPM = no; then
	AC_MSG_ERROR([Cannot locate npm, please make sure that npm is installed, see http://npmjs.org/ ])
	exit;
fi
AC_CHECK_PROG(COFFEE, coffee, yes,no)
if test $COFFEE = no; then
	AC_MSG_ERROR([Cannot locate coffee, please make sure that coffeescript is installed, see http://jashkenas.github.com/coffee-script/ ])
	exit;
fi


AC_OUTPUT
