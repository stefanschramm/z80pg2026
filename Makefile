ASM = z80asm
ASM_FLAGS_COMMON = --list=$@.listing.txt --label=$@.labels.txt

PROGRAMS_SRC = $(wildcard src/programs/*.asm)
PROGRAMS_BIN = $(patsubst src/programs/%.asm,build_programs/%.bin,$(PROGRAMS_SRC))

MONITOR_SRC = $(wildcard src/monitor/*.asm)

.PHONY: load_monitor

all: monitor programs

# Note:
# Loading the monitor into RAM is only safe when using the monitor from ROM because otherwise it's overwriting running code.
# Furthermore the monitor must have been edited to use another memory location (for example 0x8000 instead od 0x0000).
load_monitor: monitor
	./load.sh build_monitor/monitor.bin 8000 8000

monitor: build_monitor/monitor.bin

programs: $(PROGRAMS_BIN)

build_programs/%.bin: src/programs/%.asm
	$(ASM) $(ASM_FLAGS_COMMON) -o $@ -I src/include $<

build_monitor/monitor.bin: $(MONITOR_SRC)
	echo -n "$$(date -u '+%Y%m%d%H%M%S')" > build_monitor/version.inc.bin
	$(ASM) $(ASM_FLAGS_COMMON) -o $@ -I src/include -I src/monitor -I build_monitor src/monitor/monitor.asm

clean:
	rm -f build_programs/* build_monitor/*

