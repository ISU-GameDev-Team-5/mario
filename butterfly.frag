extern vec2 screenSize;
extern float time;

vec4 color(vec2 uv)
{
    // Генерация случайного цвета для мотылька
    float r = sin(uv.x * 10.0 + time) * 0.5 + 0.5;
    float g = sin(uv.y * 10.0 + time) * 0.5 + 0.5;
    float b = sin((uv.x + uv.y) * 5.0 + time) * 0.5 + 0.5;

    // Делаем мотылька более прозрачным
    float alpha = 0.5 + 0.5 * sin(time * 2.0 + uv.x * 20.0);
    
    return vec4(r, g, b, alpha);
}
