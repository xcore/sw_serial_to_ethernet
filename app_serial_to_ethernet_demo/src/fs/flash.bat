:: Run makeFlash.pl to generate webpage image
:: makeFlash.pl wpage
del *.xe
copy ..\..\bin\release\s2e_demo.xe
xflash --id 0 --target-file xp-skc-l2-single.xn --erase-all
xflash --id 0 --target-file xp-skc-l2-single.xn --boot-partition-size 0x20000 --data webpage_bin.img s2e_demo.xe