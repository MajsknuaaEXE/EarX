#pragma once
#include <JuceHeader.h>

class EarxLookAndFeel : public juce::LookAndFeel_V4
{
public:
    EarxLookAndFeel()
    {
        // 全局 Slider 样式
        setColour(juce::Slider::thumbColourId, juce::Colours::skyblue);
        setColour(juce::Slider::trackColourId, juce::Colours::darkgrey);
        setColour(juce::Slider::backgroundColourId, juce::Colours::black);

        // ToggleButton 样式
        setColour(juce::ToggleButton::textColourId, juce::Colours::white);
    }

    // 自定义 ToggleButton 绘制
    void drawToggleButton(juce::Graphics& g, juce::ToggleButton& button,
                          bool shouldDrawButtonAsHighlighted,
                          bool shouldDrawButtonAsDown) override
    {
        auto bounds = button.getLocalBounds().toFloat();

        // 背景圆角矩形
        g.setColour(button.getToggleState() ? juce::Colours::skyblue : juce::Colours::darkgrey);
        g.fillRoundedRectangle(bounds, 6.0f);

        // 文字
        g.setColour(juce::Colours::white);
        g.setFont(juce::Font(14.0f, juce::Font::bold));
        g.drawText(button.getButtonText(), bounds, juce::Justification::centred);
    }

    // 自定义 Slider 绘制
    void drawLinearSlider(juce::Graphics& g, int x, int y, int width, int height,
                          float sliderPos, float minSliderPos, float maxSliderPos,
                          const juce::Slider::SliderStyle style, juce::Slider& slider) override
    {
        auto trackBounds = juce::Rectangle<float>(x, y + height / 2 - 3, width, 6);
        g.setColour(juce::Colours::darkgrey);
        g.fillRoundedRectangle(trackBounds, 3.0f);

        g.setColour(juce::Colours::skyblue);
        g.fillRoundedRectangle(trackBounds.withWidth(sliderPos - x), 3.0f);

        g.setColour(juce::Colours::white);
        g.fillEllipse(sliderPos - 6, y + height / 2 - 6, 12, 12);
    }
};
// ================= LightIndicator =================
class LightIndicator : public juce::Component
{
public:
    void setOn (bool shouldBeOn) { isOn = shouldBeOn; repaint(); }
    void paint (juce::Graphics& g) override
    {
        g.setColour (isOn ? juce::Colours::yellow : juce::Colours::darkgrey);
        g.fillEllipse (getLocalBounds().toFloat());
    }
private:
    bool isOn = false;
};

// ================= DummySound =================
class DummySound : public juce::SynthesiserSound
{
public:
    bool appliesToNote (int) override { return true; }
    bool appliesToChannel (int) override { return true; }
};

// ================= SineVoice =================
class SineVoice : public juce::SynthesiserVoice
{
public:
    bool canPlaySound (juce::SynthesiserSound* sound) override
    {
        return dynamic_cast<DummySound*> (sound) != nullptr;
    }
    
    void startNote (int midiNoteNumber, float velocity, juce::SynthesiserSound*, int) override
    {
        currentAngle = 0.0;
        angleDelta = juce::MathConstants<double>::twoPi *
                     juce::MidiMessage::getMidiNoteInHertz (midiNoteNumber) /
                     getSampleRate();
        level = velocity;
        tailOff = 0.0;
        isPlaying = true;
        sampleCount = 0;
    }
    
    void stopNote (float, bool allowTailOff) override
    {
        if (allowTailOff)
            tailOff = 1.0;
        else
            clearCurrentNote();
        
        isPlaying = false;
    }
    
    void renderNextBlock (juce::AudioBuffer<float>& buffer, int startSample, int numSamples) override
    {
        if (!isVoiceActive()) return;
        
        auto localLevel = level * volume;
        int attackSamples = int (0.01f * getSampleRate());
        
        while (--numSamples >= 0)
        {
            float envGain = (sampleCount < attackSamples)
                            ? (float) sampleCount / attackSamples : 1.0f;
            
            if (tailOff > 0.0f)
            {
                tailOff *= 0.99f;
                envGain *= tailOff;
                if (tailOff < 0.005f)
                {
                    clearCurrentNote();
                    break;
                }
            }
            
            float sample = std::sin (currentAngle) * localLevel * envGain;
            for (int ch = 0; ch < buffer.getNumChannels(); ++ch)
                buffer.addSample (ch, startSample, sample);
            
            currentAngle += angleDelta;
            ++startSample;
            ++sampleCount;
        }
    }
    
    void pitchWheelMoved (int) override {}
    void controllerMoved (int, int) override {}
    
    void setVolume (float newVolume) { volume = newVolume; }
    
private:
    double currentAngle = 0.0, angleDelta = 0.0;
    float level = 0.0f, tailOff = 0.0f, volume = 0.2f;
    int sampleCount = 0;
    bool isPlaying = false;
};

// ================= MainComponent =================
class MainComponent : public juce::AudioAppComponent, private juce::Timer
{
public:
    struct ActiveNote
    {
        int note;
        int semitone;
        double endTime; // 高精度结束时间（毫秒）
    };
    
    MainComponent()
    {
        static const char* noteNames[] = { "C", "C#", "D", "D#", "E", "F", "F#",
                                           "G", "G#", "A", "A#", "B" };
        
        for (int i = 0; i < 12; ++i)
        {
            auto* tb = new juce::ToggleButton (noteNames[i]);
            toggles.add (tb);
            addAndMakeVisible (tb);
            
            auto* li = new LightIndicator();
            lights.add (li);
            addAndMakeVisible (li);
        }
        
        DBG("[MainComponent] Constructor start.");

        addAndMakeVisible (bpmSlider);
        DBG("[UI] bpmSlider created & visible.");
        bpmSlider.setRange (30.0, 300.0, 0.1);
        bpmSlider.setValue (120.0);

        addAndMakeVisible (volumeSlider);
        DBG("[UI] volumeSlider created & visible.");
        volumeSlider.setRange (0.0, 1.0, 0.01);
        volumeSlider.setValue (0.2);

        addAndMakeVisible (noteDurationSlider);
        DBG("[UI] noteDurationSlider created & visible.");
        noteDurationSlider.setRange (10, 100, 1);
        noteDurationSlider.setValue (100);
        noteDurationSlider.setTextValueSuffix (" %");

        DBG("[MainComponent] Constructor end.");
        
        addAndMakeVisible (bpmSlider);
        bpmSlider.setRange (30.0, 300.0, 0.1);
        bpmSlider.setValue (120.0);

        DBG("[UI] Creating shutdownToggle...");
        addAndMakeVisible(shutdownToggle);
        shutdownToggle.setButtonText("Shutdown 30min");
        DBG("[UI] shutdownToggle created & visible.");

        shutdownToggle.onClick = [this]
        {
            DBG("[shutdownToggle] Clicked. State = " << (shutdownToggle.getToggleState() ? "ON" : "OFF"));

            if (shutdownToggle.getToggleState())
            {
                shutdownEndTime = juce::Time::getMillisecondCounterHiRes() + (30.0 * 60.0 * 1000.0);
                stopTrigger = false;
                DBG("[shutdownToggle] Timer set to 30 minutes.");
            }
            else
            {
                shutdownEndTime = 0;
                stopTrigger = false;
                DBG("[shutdownToggle] Timer canceled.");
            }
        };
        
        addAndMakeVisible (volumeSlider);
        volumeSlider.setRange (0.0, 1.0, 0.01);
        volumeSlider.setValue (0.2);
        volumeSlider.onValueChange = [this] {
            for (int i = 0; i < synth.getNumVoices(); ++i)
                if (auto* sv = dynamic_cast<SineVoice*> (synth.getVoice (i)))
                    sv->setVolume ((float) volumeSlider.getValue());
        };
        
        
        addAndMakeVisible (noteDurationSlider);
        noteDurationSlider.setRange (10, 100, 1);
        noteDurationSlider.setValue (100);
        noteDurationSlider.setTextValueSuffix (" %");
        
        for (int i = 0; i < 8; ++i)
            synth.addVoice (new SineVoice());
        synth.addSound (new DummySound());
        
        setAudioChannels (0, 2);
        
        earxLookAndFeel = std::make_unique<EarxLookAndFeel>();
        setLookAndFeel(earxLookAndFeel.get());

     
        startTimer (10);
        setSize (400, 1000);
    }
    
    ~MainComponent() override { shutdownAudio(); setLookAndFeel(nullptr);}
    
    void prepareToPlay (int, double sampleRate) override
    {
        synth.setCurrentPlaybackSampleRate (sampleRate);
    }
    
    void getNextAudioBlock (const juce::AudioSourceChannelInfo& bufferToFill) override
    {
        bufferToFill.clearActiveBufferRegion();
        juce::MidiBuffer dummyMidi;
        synth.renderNextBlock (*bufferToFill.buffer, dummyMidi,
                              bufferToFill.startSample, bufferToFill.numSamples);
    }
    
    void releaseResources() override {}
    
    void timerCallback() override
    {
        auto now = juce::Time::getMillisecondCounterHiRes();

        if (shutdownEndTime > 0 && now >= shutdownEndTime)
            stopTrigger = true;

        double bpm = bpmSlider.getValue();
        double intervalMs = 60000.0 / bpm;

        if (!stopTrigger && now - lastTriggerTime >= intervalMs)
        {
            playNextNote();
            lastTriggerTime = now;
        }

        // 🔹 检查 NoteOff 队列
        for (int i = activeNotes.size() - 1; i >= 0; --i)
        {
            if (now >= activeNotes[i].endTime)
            {
                int semitone = activeNotes[i].semitone;
                synth.noteOff(1, activeNotes[i].note, 0.0f, true);
                activeNotes.remove(i);

                // 🔹 检查该 semitone 是否还有正在播放的 note
                bool stillActive = false;
                for (auto& n : activeNotes)
                    if (n.semitone == semitone)
                        stillActive = true;

                if (!stillActive)
                    lights[semitone]->setOn(false);
            }
        }
    }
    
    void playNextNote()
    {
        juce::Array<int> onIndices;
        for (int i = 0; i < toggles.size(); ++i)
            if (toggles[i]->getToggleState())
                onIndices.add (i);
        
        if (onIndices.isEmpty()) return;
        
        int semitone, note;
        do
        {
            semitone = onIndices[juce::Random::getSystemRandom().nextInt (onIndices.size())];
            int baseOctave = juce::Random::getSystemRandom().nextInt ({4, 7});
            note = baseOctave * 12 + semitone;
        }
        while (note == lastMidiNote && onIndices.size() * 4 > 1);
        
        lastMidiNote = note;
        
        for (int i = 0; i < lights.size(); ++i)
            lights[i]->setOn (i == semitone);
        
        synth.noteOn (1, note, 0.8f);
        
        // 根据当前 BPM 和百分比实时计算结束时间
        double durationMs = (60000.0 / bpmSlider.getValue()) *
                            (noteDurationSlider.getValue() / 100.0);
        double endTime = juce::Time::getMillisecondCounterHiRes() + durationMs;
        
        activeNotes.add ({ note, semitone, endTime });
    }
    
    void resized() override
    {
        DBG("[UI] resized() start.");
        auto r = getLocalBounds().reduced (10);
        r.removeFromTop (300);
        
        int sliderHeight = 35;
        bpmSlider.setBounds (r.removeFromTop (sliderHeight).reduced (0, 5));
        DBG("[UI] bpmSlider bounds set.");
        volumeSlider.setBounds (r.removeFromTop (sliderHeight).reduced (0, 5));
        DBG("[UI] volumeSlider bounds set.");
        noteDurationSlider.setBounds (r.removeFromTop (sliderHeight).reduced (0, 5));
        DBG("[UI] noteDurationSlider bounds set.");
        shutdownToggle.setBounds(r.removeFromTop(sliderHeight).reduced(0, 5));
        DBG("[UI] shutdownToggle bounds set.");
        
        int rowHeight = 30;
        int spacing = 6;
        int labelWidth = 100;
        int lightSize = 20;
        
        for (int i = 0; i < toggles.size(); ++i)
        {
            auto row = r.removeFromTop (rowHeight).reduced (0, spacing);
            toggles[i]->setBounds (row.removeFromLeft (labelWidth));
            lights[i]->setBounds (row.removeFromLeft (lightSize)
                                 .withSizeKeepingCentre (lightSize, lightSize));
        }
        DBG("[UI] resized() end.");
    }
    
private:
    std::unique_ptr<EarxLookAndFeel> earxLookAndFeel;
    
    
    double shutdownEndTime = 0; // 到期时间（毫秒），0 表示不启用
        bool stopTrigger = false;   // 到点后阻止播放
    double lastTriggerTime = 0;
    int lastMidiNote = -1;
    int lastSemitone = -1;

    
    juce::OwnedArray<juce::ToggleButton> toggles;
    juce::OwnedArray<LightIndicator> lights;
    juce::Slider bpmSlider, volumeSlider, noteDurationSlider;
    juce::Synthesiser synth;
    juce::ToggleButton shutdownToggle;
    
    juce::Array<ActiveNote> activeNotes;
};

// ================= MainWindow =================
class MainWindow : public juce::DocumentWindow
{
public:
    MainWindow (juce::String name)
        : juce::DocumentWindow (name, juce::Colours::black, DocumentWindow::allButtons)
    {
        setUsingNativeTitleBar (true);
        setContentOwned (new MainComponent(), true);
        setResizable (true, false);
        centreWithSize (getWidth(), getHeight());
        setVisible (true);
    }
    
    void closeButtonPressed() override
    {
        juce::JUCEApplication::getInstance()->systemRequestedQuit();
    }
};

// ================= IOSApp =================
class IOSApp : public juce::JUCEApplication
{
public:
    const juce::String getApplicationName() override { return "Earx"; }
    const juce::String getApplicationVersion() override { return "0.2.0"; }
    bool moreThanOneInstanceAllowed() override { return false; }
    
    void initialise (const juce::String&) override
    {
        mainWindow.reset (new MainWindow (getApplicationName()));
    }
    
    void shutdown() override
    {
        mainWindow = nullptr;
    }
    
private:
    std::unique_ptr<MainWindow> mainWindow;
};

START_JUCE_APPLICATION (IOSApp)
