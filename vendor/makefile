JSL_DIR=jsl-0.3.0
JSL_SRC=$(JSL_DIR)/src

# Load the SpiderMonkey config to find the OS define
# Also use this for the SO_SUFFIX
BUILD_OPT=1
DEPTH=$(JSL_SRC)
include $(JSL_SRC)/config.mk

BUILD_DIR=$(JSL_DIR)/bin

COPY_JSL=$(BUILD_DIR)/jsl
ORIG_JSL=$(JSL_SRC)/$(OBJDIR)/jsl

ALL_TARGETS=$(COPY_JSL) $(BUILD_DIR)

all: $(ALL_TARGETS)

install: all

clean:
	make -f Makefile.ref -C $(JSL_SRC) BUILD_OPT=$(BUILD_OPT) clean
	rm -rf $(JSL_SRC)/$(OBJDIR)
	rm -rf $(JSL_SRC)/editline/$(OBJDIR)
	rm -rf $(JSL_SRC)/fdlibm/$(OBJDIR)
	rm -rf $(BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(COPY_JSL): $(BUILD_DIR) $(ORIG_JSL)
	cp $(ORIG_JSL) $(COPY_JSL)

$(ORIG_JSL): 
	make -f Makefile.ref -C $(JSL_SRC) BUILD_OPT=$(BUILD_OPT)
