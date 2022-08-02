%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -Wall -M $*


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
FORMS=$(patsubst %.per,%.42f,$(wildcard *.per))

all:: $(MODS) $(FORMS)

run: all
	fglrun input

fglwebrun:
	git clone https://github.com/FourjsGenero/tool_fglwebrun.git fglwebrun

webrun: all fglwebrun
	~/w/fglwebrun/fglwebrun input

clean:
	rm -f *.42?
	rm -rf fglwebrun 
