# Assembling MOSS 2.2

This is an attempt to verifiably re-create the MOSS 2.2 ROM binary image on the CCS 2422 FDC card
using the source-code in the 2422 manual.

The rationale for this is to certify that porting the source from the CP/M `MAC.COM` to `ZMAC` 
has been performed properly.

## Modus operandi

- Dump the ROM on the FDC using the `D` command.  (Saved in [ROM.dump.txt](./ROM.dump.txt))
- Port any `zmac`-incompatible instruction mnemonics to Z80. (See [ccsfdco.asm](./ccsfdco.asm))
- Compare the `zmac` output to the dumped ROM image.

## Source code alterations

- remove `MACLIB`
- fix labels on and use of `ORG`
- 8080 `JMP PO` is parity-odd so the label `PO` is problematic
- zmac does not seem to like `CPI`, change to Z80's `CP`
- need to find/xlate 8080 `JP` insns to `JP P,` before xlating things into Z80 `JP` insns
