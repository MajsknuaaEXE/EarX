#include "EarxLookAndFeel.h"

EarxLookAndFeel::EarxLookAndFeel()
{
    setColour(juce::Slider::textBoxTextColourId, juce::Colours::white);
    setColour(juce::ToggleButton::textColourId, juce::Colours::white);
}

void EarxLookAndFeel::drawBackground(juce::Graphics& g, juce::Component& component)
{
    auto area = component.getLocalBounds().toFloat();
    
    // 🎨 高级紫色渐变背景（与启动界面融合）
    juce::ColourGradient mainGradient(
        juce::Colour::fromRGB(75, 44, 146),    // 深紫（与启动界面一致）
        area.getCentreX(), 0,
        juce::Colour::fromRGB(45, 25, 85),     // 更深的紫色
        area.getCentreX(), area.getHeight(),
        false
    );
    g.setGradientFill(mainGradient);
    g.fillAll();
    
    // ✨ 径向渐变光晕效果（从中心向外）
    juce::ColourGradient centerGlow(
        juce::Colour::fromRGB(120, 80, 180).withAlpha(0.3f),  // 中心亮紫色
        area.getCentreX(), area.getCentreY(),
        juce::Colours::transparentBlack,                       // 边缘透明
        area.getCentreX(), area.getCentreY(),
        true  // 径向渐变
    );
    centerGlow.addColour(0.6, juce::Colour::fromRGB(90, 60, 150).withAlpha(0.2f));
    g.setGradientFill(centerGlow);
    g.fillEllipse(area.getCentreX() - area.getWidth() * 0.4f, 
                  area.getCentreY() - area.getHeight() * 0.4f,
                  area.getWidth() * 0.8f, area.getHeight() * 0.8f);
    
    // 🌟 精致的装饰元素
    // 左上角装饰
    g.setColour(juce::Colour::fromRGB(180, 50, 130).withAlpha(0.15f));
    juce::Path decoration1;
    decoration1.startNewSubPath(0, 0);
    decoration1.cubicTo(area.getWidth() * 0.3f, area.getHeight() * 0.1f,
                        area.getWidth() * 0.2f, area.getHeight() * 0.3f,
                        area.getWidth() * 0.1f, area.getHeight() * 0.4f);
    decoration1.lineTo(0, area.getHeight() * 0.2f);
    decoration1.closeSubPath();
    g.fillPath(decoration1);
    
    // 右下角装饰
    g.setColour(juce::Colour::fromRGB(64, 224, 208).withAlpha(0.1f));
    juce::Path decoration2;
    decoration2.startNewSubPath(area.getWidth(), area.getHeight());
    decoration2.cubicTo(area.getWidth() * 0.7f, area.getHeight() * 0.9f,
                        area.getWidth() * 0.8f, area.getHeight() * 0.7f,
                        area.getWidth() * 0.9f, area.getHeight() * 0.6f);
    decoration2.lineTo(area.getWidth(), area.getHeight() * 0.8f);
    decoration2.closeSubPath();
    g.fillPath(decoration2);
    
    // 🔮 微妙的几何图案
    g.setColour(juce::Colours::white.withAlpha(0.03f));
    for (int i = 0; i < 5; ++i)
    {
        float radius = (i + 1) * area.getWidth() * 0.15f;
        g.drawEllipse(area.getCentreX() - radius/2, area.getCentreY() - radius/2, 
                      radius, radius, 1.0f);
    }
}

void EarxLookAndFeel::drawLinearSlider(juce::Graphics& g, int x, int y, int width, int height,
                                       float sliderPos, float, float,
                                       const juce::Slider::SliderStyle, juce::Slider& slider)
{
    auto trackBounds = juce::Rectangle<float>(x, y + height / 2 - 4, width, 8);
    g.setColour(juce::Colour::fromRGB(50, 30, 100));
    g.fillRoundedRectangle(trackBounds, 4.0f);
    g.setColour(juce::Colour::fromRGB(255, 200, 50));
    g.fillRoundedRectangle(trackBounds.withWidth(sliderPos - x), 4.0f);
    g.fillEllipse(sliderPos - 10, y + height / 2 - 10, 20, 20);
}

void EarxLookAndFeel::drawToggleButton(juce::Graphics& g, juce::ToggleButton& button,
                                       bool shouldDrawButtonAsHighlighted, bool shouldDrawButtonAsDown)
{
    auto bounds = button.getLocalBounds().toFloat();
    
    // 检查按钮类型 - 通过按钮文本识别功能性开关
    juce::String buttonText = button.getButtonText();
    bool isShutdownButton = buttonText.containsIgnoreCase("Shutdown");
    bool isModeButton = buttonText.containsIgnoreCase("Piano Mode");
    
    // 如果是功能性开关，使用特殊样式
    if (isShutdownButton)
    {
        // === Shutdown 开关样式 ===
        juce::Colour shutdownColour = button.getToggleState() ? 
            juce::Colour::fromRGB(255, 70, 70) :    // 开启时：亮红色
            juce::Colour::fromRGB(120, 40, 40);     // 关闭时：暗红色
        
        if (shouldDrawButtonAsHighlighted)
        {
            shutdownColour = shutdownColour.brighter(0.3f);
        }
        
        // 绘制圆角矩形背景
        g.setColour(shutdownColour);
        g.fillRoundedRectangle(bounds, bounds.getHeight() * 0.3f);
        
        // 添加内阴影效果
        if (button.getToggleState())
        {
            g.setColour(juce::Colours::black.withAlpha(0.2f));
            g.fillRoundedRectangle(bounds.reduced(2.0f), bounds.getHeight() * 0.25f);
        }
        
        // 边框
        g.setColour(juce::Colour::fromRGB(80, 30, 30));
        g.drawRoundedRectangle(bounds, bounds.getHeight() * 0.3f, 2.0f);
        
        // 文字
        g.setColour(juce::Colours::white);
        g.setFont(juce::Font("Arial", bounds.getHeight() * 0.35f, juce::Font::bold));
        g.drawText(buttonText, bounds, juce::Justification::centred);
        
        return; // 提前返回，不执行音符按钮的绘制逻辑
    }
    else if (isModeButton)
    {
        // === Mode 开关样式（胶囊形状） ===
        float cornerRadius = bounds.getHeight() * 0.5f; // 胶囊形状
        
        // 根据状态设置渐变色
        juce::ColourGradient modeGradient;
        if (button.getToggleState())
        {
            // Piano Mode - 金色渐变
            modeGradient = juce::ColourGradient(
                juce::Colour::fromRGB(255, 215, 0),     // 金色
                bounds.getCentreX(), bounds.getY(),
                juce::Colour::fromRGB(218, 165, 32),    // 深金色
                bounds.getCentreX(), bounds.getBottom(),
                false
            );
        }
        else
        {
            // Sine Mode - 蓝紫色渐变
            modeGradient = juce::ColourGradient(
                juce::Colour::fromRGB(100, 149, 237),   // 矢车菊蓝
                bounds.getCentreX(), bounds.getY(),
                juce::Colour::fromRGB(72, 61, 139),     // 深蓝紫
                bounds.getCentreX(), bounds.getBottom(),
                false
            );
        }
        
        if (shouldDrawButtonAsHighlighted)
        {
            // 高亮时增加亮度
            modeGradient = juce::ColourGradient(
                modeGradient.getColour(0).brighter(0.2f),
                bounds.getCentreX(), bounds.getY(),
                modeGradient.getColour(1).brighter(0.2f),
                bounds.getCentreX(), bounds.getBottom(),
                false
            );
        }
        
        // 绘制胶囊形状背景
        g.setGradientFill(modeGradient);
        g.fillRoundedRectangle(bounds, cornerRadius);
        
        // 添加发光效果
        if (button.getToggleState())
        {
            g.setColour(modeGradient.getColour(0).withAlpha(0.4f));
            g.fillRoundedRectangle(bounds.expanded(3.0f), cornerRadius + 3.0f);
        }
        
        // 边框
        g.setColour(button.getToggleState() ? 
            juce::Colour::fromRGB(160, 120, 50) :     // 金色边框
            juce::Colour::fromRGB(50, 50, 100));      // 蓝色边框
        g.drawRoundedRectangle(bounds, cornerRadius, 2.0f);
        
        // 绘制模式指示器（左右两侧的小圆点）
        float dotRadius = bounds.getHeight() * 0.15f;
        float dotY = bounds.getCentreY();
        
        // Sine模式指示器（左侧）
        g.setColour(button.getToggleState() ? 
            juce::Colours::white.withAlpha(0.3f) : 
            juce::Colours::white);
        g.fillEllipse(bounds.getX() + dotRadius, dotY - dotRadius, dotRadius * 2, dotRadius * 2);
        
        // Piano模式指示器（右侧）
        g.setColour(button.getToggleState() ? 
            juce::Colours::white : 
            juce::Colours::white.withAlpha(0.3f));
        g.fillEllipse(bounds.getRight() - dotRadius * 3, dotY - dotRadius, dotRadius * 2, dotRadius * 2);
        
        // 文字
        g.setColour(juce::Colours::white);
        g.setFont(juce::Font("Arial", bounds.getHeight() * 0.28f, juce::Font::bold));
        juce::String displayText = button.getToggleState() ? "PIANO" : "SINE";
        g.drawText(displayText, bounds, juce::Justification::centred);
        
        return; // 提前返回，不执行音符按钮的绘制逻辑
    }
    
    // === 以下是原有的音符按钮绘制逻辑 ===
    // 检查按钮状态
    bool isLongPressed = button.getProperties().getWithDefault("longPressed", false);
    bool isPlaying = button.getProperties().getWithDefault("isPlaying", false);
    
    // 根据音符名称判断是黑键还是白键
    // 明确定义黑键（只有这5个是黑键）
    bool isBlackKey = (buttonText == "C#/Db" || 
                       buttonText == "D#/Eb" || 
                       buttonText == "F#/Gb" || 
                       buttonText == "G#/Ab" || 
                       buttonText == "A#/Bb");
    
    // 其他都是白键：C, D, E/Fb, #E/F, G, A, B/Cb
    
    // 设置基础颜色（钢琴键颜色）
    juce::Colour baseColour;
    if (isBlackKey)
    {
        baseColour = juce::Colours::black;  // 黑键
    }
    else
    {
        baseColour = juce::Colours::white;  // 白键
    }
    
    // 根据状态设置颜色
    if (isLongPressed)
    {
        // 长按发光效果 - 金黄色发光
        baseColour = juce::Colour::fromRGB(255, 215, 0);
        
        // 添加圆形发光效果（确保不超出边界）
        g.setColour(baseColour.withAlpha(0.3f));
        g.fillEllipse(bounds.reduced(1.0f));
        g.setColour(baseColour.withAlpha(0.6f));
        g.fillEllipse(bounds.reduced(3.0f));
    }
    else if (isPlaying)
    {
        // 播放状态 - 明亮的青绿色发光（替代原来的指示灯功能）
        baseColour = juce::Colour::fromRGB(0, 255, 200);
        
        // 添加播放发光效果（确保不超出边界）
        g.setColour(baseColour.withAlpha(0.4f));
        g.fillEllipse(bounds.reduced(1.0f));
        g.setColour(baseColour.withAlpha(0.7f));
        g.fillEllipse(bounds.reduced(2.5f));
    }
    else if (button.getToggleState())
    {
        // 开启状态：黑键变深灰，白键变浅灰
        if (isBlackKey)
        {
            baseColour = juce::Colour::fromRGB(60, 60, 60);  // 深灰
        }
        else
        {
            baseColour = juce::Colour::fromRGB(200, 200, 200);  // 浅灰
        }
    }
    
    // 绘制圆形按钮
    g.setColour(baseColour);
    g.fillEllipse(bounds);
    
    // 添加边框
    g.setColour(juce::Colour::fromRGB(100, 100, 100));
    g.drawEllipse(bounds, 1.5f);
    
    // 绘制文字（根据背景色选择文字颜色）
    if (isLongPressed)
    {
        g.setColour(juce::Colours::black);  // 金色背景用黑字
    }
    else if (isPlaying)
    {
        g.setColour(juce::Colours::black);  // 青绿色背景用黑字
    }
    else if (isBlackKey)
    {
        g.setColour(juce::Colours::white);  // 黑键用白字
    }
    else
    {
        g.setColour(juce::Colours::black);  // 白键用黑字
    }
    
    g.setFont(juce::Font("Arial", bounds.getHeight() * 0.25f, juce::Font::bold));
    g.drawText(button.getButtonText(), bounds, juce::Justification::centred);
}

void EarxLookAndFeel::drawLight(juce::Graphics& g, juce::Rectangle<float> bounds, bool isOn)
{
    g.setColour(isOn ? juce::Colour::fromRGB(255, 200, 50) : juce::Colours::black);
    g.fillEllipse(bounds);
} 