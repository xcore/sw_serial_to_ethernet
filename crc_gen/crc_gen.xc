#include <xs1.h>
#include <print.h>
#include <xclib.h>

int main( void )
{

	unsigned vals[16] = {
	0x00000000,
    0x00000001,
    0x00000100,
    0x00000101,
    0x00010000,
	0x00010001,
    0x00010100,
    0x00010101,
    0x01000000,
    0x01000001,
    0x01000100,
    0x01000101,
    0x01010000,
    0x01010001,
    0x01010100,
    0x01010101,
	};

	for (int i = 0; i < 16; i++)
	{
		crc32(vals[i], 0xf, 0xf);
		printstr("fourBitLookup["); printint( vals[i] ); printchar(']'); printstr(" = "); printint(i); printstr(";\n"); 
	}

	return 0;
}
