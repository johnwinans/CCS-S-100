
ZMAC=../zmac/zmac

all: zout/step.mhex

ZFLAGS=--oo lst,hex,cim
ZFLAGS+=-s

zout/step.cim: step.asm
	$(ZMAC) $(ZFLAGS) $^

zout/step.mhex: zout/step.cim
	hexdump -v -e '1/1 "%02X "' $^ > $@

clean:
	rm -rf zout 

world: clean all
