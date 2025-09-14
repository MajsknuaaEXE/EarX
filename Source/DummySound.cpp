#include "DummySound.h"

bool DummySound::appliesToNote (int) { return enabled.load(); }
bool DummySound::appliesToChannel (int) { return enabled.load(); } 
