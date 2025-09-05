#!/bin/sh
set -e
if test "$CONFIGURATION" = "Custom"; then :
  cd /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/External/JUCE/tools
  make -f /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/External/JUCE/tools/CMakeScripts/ReRunCMake.make
fi

