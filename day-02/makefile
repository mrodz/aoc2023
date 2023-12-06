BINNAME=day2.exe
BINDIR=bin
IDIR=include
CC=gcc
CFLAGS=-std=c99 -ggdb -Wall -I$(IDIR)

ODIR=obj
LDIR=lib

_DEPS = game_reader.h game.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJ = game_reader.o game.o main.o 
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))

$(OBJ): $(ODIR)/%.o: src/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

all: $(OBJ)
	gcc -o $(patsubst %,%/$(BINNAME),$(BINDIR)) $^ $(CFLAGS)

run: all
	$(BINDIR)/$(BINNAME)

.PHONY: clean

clean:
	del /f /q $(ODIR)\*.o 