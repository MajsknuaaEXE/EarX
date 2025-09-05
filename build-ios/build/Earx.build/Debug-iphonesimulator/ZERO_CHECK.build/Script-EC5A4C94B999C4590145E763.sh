#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios
  make -f /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios
  make -f /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios
  make -f /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios
  make -f /Users/arminjay/Desktop/me/JUCE/Earx/Earx/build-ios/CMakeScripts/ReRunCMake.make
fi

