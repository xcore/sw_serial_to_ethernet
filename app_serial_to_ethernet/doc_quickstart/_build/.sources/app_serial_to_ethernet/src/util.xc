#include <xs1.h>
#include <platform.h>

/** =========================================================================
 *  Soft reset
 *
 **/
void chip_soft_reset(void)
{
    unsigned int pll_val;
    unsigned int local_tile_id = get_local_tile_id();
    unsigned int tile_id;
    unsigned int tile_array_length;

    asm volatile ("ldc %0, tile.globound":"=r"(tile_array_length));

    /* Reset all remote tiles */
    for(int i = 0; i < tile_array_length; i++)
    {
        /* Cannot cast tileref to unsigned */
        tile_id = get_tile_id(tile[i]);

        /* Do not reboot local tile yet */
        if (local_tile_id != tile_id)
        {
            read_sswitch_reg(tile_id, 6, pll_val);
            write_sswitch_reg_no_ack(tile_id, 6, pll_val);
        }
    }

    /* Finally reboot this tile */
    read_sswitch_reg(local_tile_id, 6, pll_val);
    write_sswitch_reg_no_ack(local_tile_id, 6, pll_val);
}
