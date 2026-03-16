# zmac

This was imported from (48k.ca)[http://48k.ca/zmac.html]

To build on a Linux system, just type `make` in this directory.

If experiencing errors running `make`, try removing the comment in the `Makefile` so that `YACC` is defined.
```
# Some systems like CentOS may require this
YACC=bison -y
```
