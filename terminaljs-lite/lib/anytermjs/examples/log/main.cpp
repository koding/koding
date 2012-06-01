#define _KFM_LOG_ENABLED_ 1
#include "log.hpp"

class FooBar
{
public:
    FooBar()
    {
        KFM_LOG_DBG("new FooBar object created");
    }
    void Foo()
    {
        KFM_LOG_DBG("processing something");
    }
};

int main()
{
    //KFM_LOG_CTX("TEST");

    KFM_LOG_INIT_FILE("test.log");
    FooBar foo;
    foo.Foo();
    KFM_LOG_DBG("here is a debug message");
    KFM_LOG_INF("here is a information message");
    KFM_LOG_WRN("here is a warning message");
    KFM_LOG_ERR("here is a error message");
    return 0;
}
