#include "pty_process.hpp"

#include <sys/types.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <pty.h>  /* for openpty and forkpty */ 
#include <utmp.h> /* for login_tty */
#include <sys/wait.h>

#include "log/log.hpp"

namespace KFM
{
    namespace Terminal
    {

        CPtyProcess::CPtyProcess(const char *cmd, size_t rows, size_t cols)
        {
            fork(cmd, rows, cols);
        }

        CPtyProcess::~CPtyProcess()
        {
            kill();
            wait();
        }

        void CPtyProcess::fork(const char *cmd, size_t rows, size_t cols)
        {
            int pid = 0, fd = 0;
            struct winsize ws;
            ws.ws_row = rows;
            ws.ws_col = cols;
            ws.ws_xpixel = 0;
            ws.ws_ypixel = 0;
            pid = forkpty(&fd, NULL, NULL, &ws);

            if (pid < 0)
            {
                KFM_LOG_ERR("failed to fork new pty process");
                throw std::runtime_error("forkpty()");
            }
            if (pid == 0)
            {
                setenv("TERM","linux",1);
                struct termios t;
                tcgetattr(0,&t);  // Could fail, but where would we send the error?
                t.c_cc[VERASE]=8; // Make ctrl-H (backspace) the erase character.
                tcsetattr(0,TCSANOW,&t); // ditto.
                int res = execl("/bin/sh", "/bin/sh", "-c", cmd, NULL);
                if (res < 0)
                {
                    KFM_LOG_ERR("failed to execl : /bin/sh -c "<<cmd);
                    throw std::runtime_error("execlp /bin/sh ");
                }
                exit(0);
            } else
            {
                mFd = fd;
                mPid = pid;
            }
        }

        bool CPtyProcess::kill(int signal)
        {
            if (::kill(mPid, signal) < 0)
            {
                return false;
            }
            return true;
        }

        bool CPtyProcess::setWindowSize(size_t rows, size_t cols)
        {
            struct winsize sz={0};
            sz.ws_row = rows;
            sz.ws_col = cols;
            int ret = ioctl(mFd, TIOCSWINSZ, &sz);
            if (ret < 0)
            {
                return false;
            }

            return true;
        }

        std::pair<int, int> CPtyProcess::getWindowSize()
        {
            struct winsize sz;
            int ret = ioctl(mFd, TIOCGWINSZ, &sz);
            if (ret < 0)
            {
                throw std::runtime_error("TIOCGWINSZ failed");
            }
            return std::make_pair(sz.ws_row, sz.ws_col);
        }

        bool CPtyProcess::wait()
        {
            if (waitpid(mPid, NULL, WUNTRACED | WCONTINUED) < 0)
            {
                return false;
            }
            return true;
        }

        int CPtyProcess::getPid()
        {
            return mPid;
        }

        int CPtyProcess::getFd()
        {
            return mFd;
        }

    }
} //end of namespace KFM::Terminal
