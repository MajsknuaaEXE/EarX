#include "SplashScreen.h"

EarxSplashScreen::EarxSplashScreen(std::function<void()> onFinishedCallback)
    : onFinished(onFinishedCallback)
{
    startTimerHz(60);
}

void EarxSplashScreen::paint (juce::Graphics& g)
{
    auto area = getLocalBounds().toFloat();
    
    // 🎨 简洁的紫色渐变背景
    juce::ColourGradient gradient(
        juce::Colour::fromRGB(75, 44, 146),    // 深紫
        area.getCentreX(), 0,
        juce::Colour::fromRGB(120, 80, 180),   // 浅紫
        area.getCentreX(), area.getHeight(),
        false
    );
    g.setGradientFill(gradient);
    g.fillAll();
    
    // ✨ 简单的装饰圆圈（半透明）
    g.setColour(juce::Colours::white.withAlpha(0.1f));
    g.fillEllipse(area.getWidth() * 0.7f, area.getHeight() * 0.2f, 
                  area.getWidth() * 0.3f, area.getWidth() * 0.3f);
    
    g.setColour(juce::Colours::white.withAlpha(0.05f));
    g.fillEllipse(area.getWidth() * 0.1f, area.getHeight() * 0.6f, 
                  area.getWidth() * 0.25f, area.getWidth() * 0.25f);
    
    // 🎯 主标题 "Earx"
    g.setColour(juce::Colours::white.withAlpha(alpha));
    g.setFont(juce::Font("Arial", area.getWidth() * 0.2f, juce::Font::bold));
    g.drawText("Earx", area, juce::Justification::centred, true);
    
    // 🏷️ 副标题 "YEEYAUDIO"
    g.setColour(juce::Colours::white.withAlpha(alpha * 0.7f));
    g.setFont(juce::Font("Arial", area.getWidth() * 0.04f, juce::Font::plain));
    juce::Rectangle<float> subtitleArea(0, area.getHeight() * 0.65f, 
                                       area.getWidth(), area.getHeight() * 0.1f);
    g.drawText("YEEYAUDIO", subtitleArea, juce::Justification::centred, true);
}

void EarxSplashScreen::timerCallback()
{
    alpha = 1.0f;
    waitCounter++;
    repaint();
    if (waitCounter > 60)
    {
        stopTimer();
        if (onFinished) onFinished();
    }
} 