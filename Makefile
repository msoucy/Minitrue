#!/usr/bin/make

# The subdirectory where intermediate files (.o, etc.) will be stored
OBJDIR = bin

# The doxygen config file name
DOXYFILE=Doxyfile

C_LIBS=-lzmq
D_LIBS=${addprefix -L, $(C_LIBS)}
D_FLAGS=-property -wi -od"$(OBJDIR)" $(D_LIBS)
D_PREFIX=src
DBLD=rdmd --build-only $(D_FLAGS)


$(OBJDIR)/%: $(D_PREFIX)/%.d
	@echo "$<"
	@if [ ! -d $(OBJDIR) ] ; then mkdir -p $(OBJDIR) ; fi
	$(DBLD) "$<"

minitrue: $(patsubst $(D_PREFIX)/%,$(OBJDIR)/%,$(patsubst %.d,%,$(wildcard $(D_PREFIX)/*.d)))

docs:
	doxygen $(DOXYFILE)

clean:
	rm -rf bin docs &> /dev/null
