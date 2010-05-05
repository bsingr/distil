# -*- Mode: makefile -*-
#
# Hacked together by Adam Rogers [adam (at) jargon (dot) ca] from
# Linux_All.mk and WINNT5.1.mk to enable building using GNU tools
# under MinGW on a Win32 platform. [September 6 2008]
#


#
# Config for all versions of Linux
#

CC = gcc
CCC = g++
LD = g++
CFLAGS += -Wall -Wno-format

OS_CFLAGS = -D_X86_=1 -DXP_WIN -DXP_WIN32 -DWIN32 -D_WINDOWS -D_WIN32 -DWINVER=0x500 -D_WIN32_WINNT=0x500 -D_MINGW -DEXPORT_JS_API

ifdef BUILD_IDG
OS_CFLAGS += -DBUILD_IDG
endif

ifdef BUILD_OPT
OS_CFLAGS += -s
endif

JSDLL_CFLAGS = -DEXPORT_JS_API
PREBUILT_CPUCFG = 1

LIB_LINK_FLAGS= --add-stdcall-alias -L./fdlibm/$(OBJDIR) -lfdm
EXE_LINK_FLAGS= 

# LIB_LINK_FLAGS=-lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid -lwinmm
# EXE_LINK_FLAGS=-lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid

DEFFILE=$(OBJDIR)/libjs.def
STATICLIB=$(OBJDIR)/libjs_implib.a
XMKSHLIBOPTS += -Wl,--output-def=$(DEFFILE) -Wl,--out-implib=$(STATICLIB)


RANLIB = ranlib
MKSHLIB = $(LD) -shared $(XMKSHLIBOPTS)

#.c.o:
#      $(CC) -c -MD $*.d $(CFLAGS) $<

CPU_ARCH = $(shell uname -m)
# don't filter in x86-64 architecture
ifneq (x86_64,$(CPU_ARCH))
ifeq (86,$(findstring 86,$(CPU_ARCH)))
CPU_ARCH = x86
# OS_CFLAGS+= -DX86_WINDOWS

ifeq (gcc, $(CC))
# if using gcc on x86, check version for opt bug 
# (http://bugzilla.mozilla.org/show_bug.cgi?id=24892)
GCC_VERSION := $(shell gcc -v 2>&1 | grep version | awk '{ print $$3 }')
GCC_LIST:=$(sort 2.91.66 $(GCC_VERSION) )

ifeq (2.91.66, $(firstword $(GCC_LIST)))
CFLAGS+= -DGCC_OPT_BUG
endif
endif
endif
endif

GFX_ARCH = win32

OS_LIBS = -lm -lc

ASFLAGS += -x assembler-with-cpp


ifeq ($(CPU_ARCH),alpha)

# Ask the C compiler on alpha linux to let us work with denormalized
# double values, which are required by the ECMA spec.

OS_CFLAGS += -mieee
endif

# Use the editline library to provide line-editing support.
ifdef JS_EDITLINE
JS_EDITLINE = 1
endif

ifeq ($(CPU_ARCH),x86_64)
# Use VA_COPY() standard macro on x86-64
# FIXME: better use it everywhere
OS_CFLAGS += -DHAVE_VA_COPY -DVA_COPY=va_copy
endif

ifeq ($(CPU_ARCH),x86_64)
# We need PIC code for shared libraries
# FIXME: better patch rules.mk & fdlibm/Makefile*
OS_CFLAGS += -DPIC -fPIC
endif
