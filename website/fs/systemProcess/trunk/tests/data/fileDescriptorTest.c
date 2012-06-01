#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


int main( int argc, char** argv ) 
{
    // We will be reading from custom descriptor 4 and writing to custom descriptor 5
    int rfd = 4;
    int wfd = 5;
    int readBytes = 0;

    void* buffer;

    buffer = malloc( 4096 * sizeof( char ) );
    memset( buffer, 0, 4096 );
    while( ( readBytes = read( rfd, buffer, 4096 ) ) > 0 ) 
    {
        write( wfd, buffer, readBytes );
    }
    close( rfd );
    close( wfd );
    free( buffer );
    return 0;
}
