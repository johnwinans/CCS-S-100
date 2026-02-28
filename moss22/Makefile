
ZMAC=../zmac/zmac

all: zout/ccsfdco.mhex

ZFLAGS=--oo lst,hex,cim
ZFLAGS+=-s

zout/ccsfdco.hex: ccsfdco.asm
	$(ZMAC) $(ZFLAGS) $^

zout/ccsfdco.cim: zout/ccsfdco.hex

zout/ccsfdco.mhex: zout/ccsfdco.cim
	hexdump -v -e '1/1 "%02X "' $^ > $@

ccsfdco.dump.txt: zout/ccsfdco.cim
	hexdump -v -C $^ | cut -c1-58 | sed -e 's/^00000/f/' | head -n -1 > $@

diff: ccsfdco.dump.txt ROM.dump.txt
	diff -i -w ccsfdco.dump.txt ROM.dump.txt

clean:
	rm -rf zout ccsfdco.dump.txt

world: clean all
