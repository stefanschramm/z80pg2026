all: z80pg2026.pdf z80pg2026.png

z80pg2026.pdf: z80pg2026.kicad_sch
	kicad-cli sch export pdf --output "$@" "$<"

z80pg2026.png: z80pg2026.pdf
	convert "$<" -resize 400x "$@"

