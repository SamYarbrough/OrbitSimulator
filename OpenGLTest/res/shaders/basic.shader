#shader vertex
#version 330 core

layout(location = 0) in vec4 position;

void main(){
    gl_Position = position;
}

#shader fragment
#version 330 core

layout(location = 0) out vec4 color;

uniform float iFrame;
uniform vec3 iMouse;
uniform vec4 iObj1;
uniform vec4 iObj2;
uniform vec4 iObj3;
uniform vec3 iObjMasses;
uniform float iPaused;
uniform float iShowVels;

float calcRadius(float mass, float mult) {
    return sqrt(mass / 3.141593) * mult;
}

bool circle(vec2 pos, float radius, vec2 testPos) {
    return (distance(pos, testPos) < radius);
}

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b - a;
    vec2 pa = p - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - h * ba);
}

void main() {
    vec3 c = vec3(0, 0, 0);

    vec3 masses = vec3(calcRadius(iObjMasses.x, 16), calcRadius(iObjMasses.y, 16), calcRadius(iObjMasses.z, 16));

    // render circles
    if (circle(iObj1.xy, masses.x, gl_FragCoord.xy)) {
        bool m = circle(iObj1.xy, masses.x, iMouse.xy);
        c += m ? vec3(1, 0.5, 0.5) : vec3(1, 0, 0);
    }
    if (circle(iObj2.xy, masses.y, gl_FragCoord.xy)) {
        bool m = circle(iObj2.xy, masses.y, iMouse.xy);
        c += m ? vec3(0.5, 1, 0.5) : vec3(0, 1, 0);
    }
    if (circle(iObj3.xy, masses.z, gl_FragCoord.xy)) {
        bool m = circle(iObj3.xy, masses.z, iMouse.xy);
        c += m?vec3(0.5, 0.5, 1):vec3(0, 0, 1);
    }

    // show velocities if button is toggled on or paused
    if (iPaused == 1 || iShowVels == 1) {
        float d = segment(gl_FragCoord.xy, iObj1.xy, iObj1.xy + iObj1.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
        d = segment(gl_FragCoord.xy, iObj2.xy, iObj2.xy + iObj2.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
        d = segment(gl_FragCoord.xy, iObj3.xy, iObj3.xy + iObj3.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
    }

    // show velocity editor thingies when paused
    if (iPaused == 1) {
        float d = segment(gl_FragCoord.xy, iObj1.xy, iObj1.xy + iObj1.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
        d = segment(gl_FragCoord.xy, iObj2.xy, iObj2.xy + iObj2.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
        d = segment(gl_FragCoord.xy, iObj3.xy, iObj3.xy + iObj3.zw * 30) - 1.5;
        if (d <= 0) {
            c = vec3(0.5, 0.7, 1.0);
        }
        if (circle(iObj1.xy+iObj1.zw * 30, 4, gl_FragCoord.xy)) {
            bool m = circle(iObj1.xy + iObj1.zw * 30, 4, iMouse.xy);
            c = vec3(0.5, 0.7, 1.0) * (m ? 1 : 0.5);
        }
        if (circle(iObj2.xy + iObj2.zw * 30, 4, gl_FragCoord.xy)) {
            bool m = circle(iObj2.xy + iObj2.zw * 30, 4, iMouse.xy);
            c = vec3(0.5, 0.7, 1.0) * (m ? 1 : 0.5);
        }
        if (circle(iObj3.xy + iObj3.zw * 30, 4, gl_FragCoord.xy)) {
            bool m = circle(iObj3.xy + iObj3.zw * 30, 4, iMouse.xy);
            c = vec3(0.5, 0.7, 1.0) * (m ? 1 : 0.5);
        }
    }

    // buttons
    if (gl_FragCoord.x >= 900 || gl_FragCoord.y > 700) {

        // pause/play
        bool brighten = distance(vec2(948.5, 710), iMouse.xy) < 14.0;

        if (iPaused == 0) {
            if (gl_FragCoord.x >= 944 && gl_FragCoord.x <= 948 && gl_FragCoord.y <= 717 && gl_FragCoord.y >= 703) {
                c = brighten ? vec3(1) : vec3(0.5);
            }
            if (gl_FragCoord.x >= 953 && gl_FragCoord.x <= 957 && gl_FragCoord.y <= 717 && gl_FragCoord.y >= 703) {
                c = brighten ? vec3(1) : vec3(0.5);
            }
        } else {
            if (gl_FragCoord.y >= (0.75 * gl_FragCoord.x - 7)) {
                if (gl_FragCoord.y <= (-0.75 * gl_FragCoord.x + 1427)) {
                    if (gl_FragCoord.x > 945) {
                        c = brighten ? vec3(1) : vec3(0.5);
                    }
                }
            }
        }

        // velocity
        brighten = distance(vec2(930, 710), iMouse.xy) < 14.0;
        float d = segment(gl_FragCoord.xy, vec2(930, 703), vec2(938, 717)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
        d = segment(gl_FragCoord.xy, vec2(930, 703), vec2(922, 717)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
        if (iShowVels == 0) {
            d = segment(gl_FragCoord.xy, vec2(923, 703), vec2(941, 717)) - 1.5;
            if (d <= 0) {
                c = brighten ? vec3(1) : vec3(0.5);
            }
        }

        // reset
        brighten = distance(vec2(910, 710), iMouse.xy) < 14.0;
        d = segment(gl_FragCoord.xy, vec2(916, 705), vec2(916, 715)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
        d = segment(gl_FragCoord.xy, vec2(916, 715), vec2(904, 715)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
        d = segment(gl_FragCoord.xy, vec2(904, 715), vec2(907, 717)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
        d = segment(gl_FragCoord.xy, vec2(904, 715), vec2(907, 713)) - 1.5;
        if (d <= 0) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
    }

    color = vec4(c, 1.0);
}
