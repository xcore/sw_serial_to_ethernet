#include <xs1.h>

/** =========================================================================
 *  Soft reset
 *
 **/
void chip_soft_reset(void)
{
    unsigned reg_value;
    read_sswitch_reg(get_local_tile_id(), 6, &reg_value);
    write_sswitch_reg((get_local_tile_id() ^ 0x4000), 6, reg_value);
    write_sswitch_reg(get_local_tile_id(), 6, reg_value);
}
