
ZMAC=../zmac/zmac

all: zout/readtrk.mhex

ZFLAGS=--oo lst,hex,cim
ZFLAGS+=-s

zout/readtrk.cim: readtrk.asm
	$(ZMAC) $(ZFLAGS) $^

zout/readtrk.mhex: zout/readtrk.cim
	hexdump -v -e '1/1 "%02X "' $^ > $@
	echo "" >> $@

clean:
	rm -rf zout 

world: clean all
