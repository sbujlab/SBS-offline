#------------------------------------------------------------------------------
# Core library
SRC = MPDModule.cxx SBSBigBite.cxx SBSGEMStand.cxx SBSGEMPlane.cxx SBSBBShowerCluster.cxx\
      SBSBBShower.cxx SBSBBTotalShower.cxx SBSCDet.cxx\
      SBSScintHit.cxx SBSScintPMT.cxx SBSShowerBlock.cxx SBSTimingHodoscope.cxx\
      SBSScintBar.cxx SBSTdcHit.cxx SBSAdcHit.cxx SBSScintPartialHit.cxx \
      SBSGRINCH.cxx SBSGRINCH_ClusterList.cxx SBSScintPlane.cxx \
      SBSECal.cxx SBSECalCluster.cxx SBSEArm.cxx  SBSHCal.cxx \
      SBSDecodeF1TDCModule.cxx \
      SBSCalorimeter.cxx SBSCalorimeterBlock.cxx SBSCalorimeterBlockData.cxx

EXTRAHDR = MPDModule.h SBSBigBite.h SBSGEMStand.h SBSGEMPlane.h SBSBBShowerCluster.h\
	   SBSBBShower.h SBSBBTotalShower.h SBSCDet.h\
	   SBSScintHit.h SBSScintPMT.h SBSShowerBlock.h SBSTimingHodoscope.h SBSScintBar.h\
           SBSTdcHit.h SBSAdcHit.h SBSScintPartialHit.h \
	   SBSGRINCH.h SBSGRINCH_ClusterList.h SBSScintPlane.h \
           SBSECal.h SBSECalCluster.h SBSEArm.h SBSHCal.h \
     SBSDecodeF1TDCModule.h \
     SBSCalorimeter.h SBSCalorimeterBlock.h SBSCalorimeterBlockData.h

CORE = sbs
CORELIB  = lib$(CORE).so
COREDICT = $(CORE)Dict

LINKDEF = $(CORE)_LinkDef.h

#------------------------------------------------------------------------------
# Compile debug version (for gdb)
export DEBUG = 1
# Compile extra code for printing verbose messages (enabled with fDebug)
export VERBOSE = 1
# Compile extra diagnostic code (extra computations and global variables)
export TESTCODE = 1
# Compile support code for MC input data
export MCDATA = 1

#export I387MATH = 1
export EXTRAWARN = 1

# Architecture to compile for
ARCH          = linux
#ARCH          = solarisCC5

#------------------------------------------------------------------------------
# Directory locations. All we need to know is INCDIRS.
# INCDIRS lists the location(s) of the C++ Analyzer header (.h) files

ifndef ANALYZER
  $(error $$ANALYZER environment variable not defined)
endif

INCDIRS  = $(wildcard $(addprefix $(ANALYZER)/, include src hana_decode hana_scaler))

ifdef EVIO_INCDIR
  INCDIRS += ${EVIO_INCDIR}
else ifdef EVIO
  INCDIRS += ${EVIO}/include
endif

#------------------------------------------------------------------------------
# Do not change anything  below here unless you know what you are doing

ifeq ($(strip $(INCDIRS)),)
  $(error No Analyzer header files found. Check $$ANALYZER)
endif

ROOTVERMAJOR := $(shell root-config --version | cut -d. -f1)
ROOTVERMINOR := $(shell root-config --version | cut -d. -f1 | cut -d/ -f1)
ROOTVERPATCH := $(shell root-config --version | cut -d. -f1 | cut -d/ -f2)
ROOTCFLAGS   := $(shell root-config --cflags)
ROOTLIBS     := $(shell root-config --libs)
ROOTGLIBS    := $(shell root-config --glibs)
ROOTBIN      := $(shell root-config --bindir)
CXX          := $(shell root-config --cxx)
LD           := $(shell root-config --ld)

## ROOT5 and under used rootcint to make dictionaries
ifeq ($(ROOTVERMAJOR),5)
	ROOTDICT_CMD = $(ROOTBIN)/rootcint
	ROOTDICT_CMD_FLAGS = 
else
	## ROOT6 uses rootcling
	ROOTDICT_CMD = $(ROOTBIN)/rootcling
	ROOTDICT_CMD_FLAGS = -rmf $(COREDICT).rootmap
endif

PKGINCLUDES  = $(addprefix -I, $(INCDIRS) ) -I$(shell pwd)
INCLUDES     = -I$(shell root-config --incdir) $(PKGINCLUDES)

LIBS          = 
GLIBS         = 

ifeq ($(ARCH),linux)
# Linux with gcc (RedHat)
ifdef DEBUG
  CXXFLAGS    = -g -O0
  LDFLAGS     = -g -O0
  DEFINES     =
else
  CXXFLAGS    = -O2 -g #-march=pentium4
  LDFLAGS     = -O -g
  DEFINES     = -DNDEBUG
endif
DEFINES      += -DLINUXVERS -DHAS_SSTREAM
CXXFLAGS     += -Wall -Woverloaded-virtual -fPIC
DICTCXXFLG   :=
ifdef EXTRAWARN
#FIXME: should be configure'd:
CXXVER       := $(shell g++ --version | head -1 | sed 's/.* \([0-9]\)\..*/\1/')
ifeq ($(CXXVER),4)
CXXFLAGS     += -Wextra -Wno-missing-field-initializers
DICTCXXFLG   := -Wno-strict-aliasing 
endif
endif
SOFLAGS       = -shared
ifdef I387MATH
CXXFLAGS     += -mfpmath=387
else
CXXFLAGS     += -march=core2 -mfpmath=sse
endif
endif

ifeq ($(ARCH),solarisCC5)
# Solaris CC 5.0
ifdef DEBUG
  CXXFLAGS    = -g
  LDFLAGS     = -g
  DEFINES     =
else
  CXXFLAGS    = -O
  LDFLAGS     = -O
  DEFINES     = -DNDEBUG
endif
DEFINES      += -DSUNVERS -DHAS_SSTREAM
CXXFLAGS     += -KPIC
SOFLAGS       = -G
DICTCXXFLG   :=
endif

ifdef VERBOSE
DEFINES      += -DVERBOSE
endif
ifdef TESTCODE
DEFINES      += -DTESTCODE
endif
ifdef MCDATA
DEFINES      += -DMCDATA
endif

CXXFLAGS     += $(DEFINES) $(ROOTCFLAGS) $(ROOTCFLAGS) $(PKGINCLUDES)
LIBS         += $(ROOTLIBS) $(SYSLIBS)
GLIBS        += $(ROOTGLIBS) $(SYSLIBS)

## ROOT6 requires c++11 enabled in gcc
ifeq ($(shell root-config --has-cxx11),yes)
MAKEDEPEND    = gcc --std=c++11
else
MAKEDEPEND    = gcc
endif

ifndef PKG
PKG           = lib$(CORE)
LOGMSG        = "$(PKG) source files"
else
LOGMSG        = "$(PKG) Software Development Kit"
endif
DISTFILE      = $(PKG).tar

#------------------------------------------------------------------------------
OBJ           = $(SRC:.cxx=.o) $(COREDICT).o
HDR           = $(SRC:.cxx=.h) $(EXTRAHDR)
DEP           = $(SRC:.cxx=.d)

all:		$(CORELIB)

$(CORELIB):	$(OBJ)
		$(LD) $(LDFLAGS) $(SOFLAGS) -o $@ $^
		@echo "$@ done"


ifeq ($(ARCH),linux)
$(COREDICT).o:	$(COREDICT).cxx
	$(CXX) $(CXXFLAGS) $(DICTCXXFLG) -o $@ -c $^
endif

$(COREDICT).cxx: $(HDR) $(LINKDEF)
	@echo "Generating dictionary $(COREDICT)..."
	#$(ROOTDICT_CMD) -f $@ -c $(INCLUDES) $(DEFINES) $^ ;
	$(ROOTDICT_CMD) -f $@ $(ROOTDICT_CMD_FLAGS) -c $(INCLUDES) $(DEFINES) $^ ;

install:	all
		cp *.so $(SBS_LIBDIR)
#		$(error Please define install yourself)
# for example:
#		cp $(USERLIB) $(LIBDIR)

clean:
		rm -f *.o *~ $(CORELIB) $(COREDICT).*

realclean:	clean
		rm -f *.d *.pcm *.rootmap

srcdist:
		rm -f $(DISTFILE).gz
		rm -rf $(PKG)
		mkdir $(PKG)
		cp -p $(SRC) $(HDR) $(LINKDEF) db*.dat Makefile $(PKG)
		gtar czvf $(DISTFILE) --ignore-failed-read \
		 -V $(LOGMSG)" `date -I`" $(PKG)
		rm -rf $(PKG)

develdist:	srcdist
		mkdir $(PKG)
		ln -s ../.git $(PKG)
		cp -p .gitignore $(PKG)
		gunzip -f $(DISTFILE).gz
		gtar rhvf $(DISTFILE) --exclude=*~ $(PKG)
		xz -f $(DISTFILE)
		rm -rf $(PKG)

.PHONY: all clean realclean srcdist

.SUFFIXES:
.SUFFIXES: .c .cc .cpp .cxx .C .o .d

%.o:	%.cxx
	$(CXX) $(CXXFLAGS) -o $@ -c $<

# FIXME: this only works with gcc
%.d:	%.cxx
	@echo Creating dependencies for $<
	@$(SHELL) -ec '$(MAKEDEPEND) -MM $(INCLUDES) -c $< \
		| sed '\''s%^.*\.o%$*\.o%g'\'' \
		| sed '\''s%\($*\)\.o[ :]*%\1.o $@ : %g'\'' > $@; \
		[ -s $@ ] || rm -f $@'

###

-include $(DEP)


