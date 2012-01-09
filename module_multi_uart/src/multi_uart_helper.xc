#include <xs1.h>


unsigned get_time( timer t )
{
    unsigned ts;
    
    t :> ts;
    return ts;
}

unsigned wait_for( timer t, unsigned delta )
{
    unsigned ts;
    
    t :> ts;
    t when timerafter(ts+delta) :> ts;
    return ts;
}

unsigned wait_until( timer t, unsigned ts )
{
    unsigned done_ts;
    t when timerafter(ts) :> done_ts;
    return done_ts;
}

void send_streaming_int( streaming chanend c, int i )
{
    c <: i;
}

unsigned get_streaming_uint( streaming chanend c )
{
    unsigned i;
    
    c :> i;
    
    return i;
}

