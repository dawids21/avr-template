# simple AVR Makefile
#
# written by michael cousins (http://github.com/mcous)
# released to the public domain

# Makefile
#
# targets:
#   all:    compiles the source code
#   test:   tests the isp connection to the mcu
#   flash:  writes compiled hex file to the mcu's flash memory
#   fuse:   writes the fuse bytes to the MCU
#   disasm: disassembles the code for debugging
#   clean:  removes all .hex, .elf, and .o files in the source code and library directories

# parameters (change this stuff accordingly)
# project name
PRJ = blink
# avr mcu
MCU = atmega168pb
# mcu clock frequency
CLK = 16000000
# avr programmer (and port if necessary)
# e.g. PRG = usbtiny -or- PRG = arduino -P /dev/tty.usbmodem411
PRG = xplainedmini
# fuse values for avr: low, high, and extended
LFU = 0xE0
HFU = 0x97
EFU = 0xFF
# program source files (not including external libraries)
SRC = $(PRJ).cpp
SDIR = src
ODIR = out
# where to look for external libraries (consisting of .c/.cpp files and .h files)
# e.g. EXT = ../../EyeToSee ../../YouSART
EXT =

# MODE = DEBUG/RELEASE
MODE = DEBUG


#################################################################################################
# \/ stuff nobody needs to worry about until such time that worrying about it is appropriate \/ #
#################################################################################################

# include path
INCLUDE := $(foreach dir, $(EXT), -I$(dir))
# c flags
CFLAGS    		= -Wall -Os -DF_CPU=$(CLK) -mmcu=$(MCU) $(INCLUDE)

ifeq ($(MODE), DEBUG)
CFLAGS += -ggdb
endif

# any aditional flags for c++
CPPFLAGS 		=

# executables
AVRDUDE = avrdude -c $(PRG) -p $(MCU)
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE    = avr-size --format=avr --mcu=$(MCU)
CC      = avr-g++

# generate list of objects
CFILES    	= $(filter %.c, $(SDIR)/$(SRC))
EXTC     	:= $(foreach dir, $(EXT), $(wildcard $(dir)/*.c))
CPPFILES  	= $(filter %.cpp, $(SDIR)/$(SRC))
EXTCPP   	:= $(foreach dir, $(EXT), $(wildcard $(dir)/*.cpp))
_OBJ		= $(notdir $(CFILES:.c=.o)) $(notdir $(EXTC:.c=.o)) $(notdir $(CPPFILES:.cpp=.o)) $(notdir $(EXTCPP:.cpp=.o))
OBJ 		= $(patsubst %,$(ODIR)/%,$(_OBJ))

# user targets
# compile all files
all: $(ODIR)/$(PRJ).hex

debug: $(ODIR)/$(PRJ).elf


# test programmer connectivity
test:
	$(AVRDUDE) -v

# flash program to mcu
flash: all
	$(AVRDUDE) -U flash:w:$(ODIR)/$(PRJ).hex:i

# write fuses to mcu
fuse:
	$(AVRDUDE) -U lfuse:w:$(LFU):m -U hfuse:w:$(HFU):m -U efuse:w:$(EFU):m

# generate disassembly files for debugging
disasm: $(ODIR)/$(PRJ).elf
	$(OBJDUMP) -d $(ODIR)/$(PRJ).elf

# remove compiled files
.PHONY: clean
clean:
	rm -rf $(ODIR)
	$(foreach dir, $(EXT), rm -f $(dir)/*.o;)

# other targets
# objects from c files
$(ODIR)/%.o: $(SDIR)/%.c 
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

# objects from c++ files
$(ODIR)/%.o: $(SDIR)/%.cpp 
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@ 

# elf file
$(ODIR)/$(PRJ).elf: $(OBJ)
	$(CC) $(CFLAGS) -o $(ODIR)/$(PRJ).elf $(OBJ)

# hex file
$(ODIR)/$(PRJ).hex: $(ODIR)/$(PRJ).elf
	rm -f $(ODIR)/$(PRJ).hex
	$(OBJCOPY) -j .text -j .data -O ihex $(ODIR)/$(PRJ).elf $(ODIR)/$(PRJ).hex
	$(SIZE) $(ODIR)/$(PRJ).elf