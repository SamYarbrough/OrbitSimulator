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
uniform float iRaytracer;

#define maxDist 10000.
vec3 center;
vec3 ray;
float rdist;
vec3 tcolor;
vec3 normal;
vec3 temp;

float calcRadius(float mass, float mult) {
    return sqrt(mass / 3.141593) * mult;
}

vec3 masses = vec3(calcRadius(iObjMasses.x, 16), calcRadius(iObjMasses.y, 16), calcRadius(iObjMasses.z, 16));

void setVec(vec3 cP, vec3 cR) {
    center = cP;
    ray = normalize(cR);
}

void dirVec(vec2 cD) {
    temp.x = ray.z;
    ray.z = ray.z * cos(cD.y) - ray.y * sin(cD.y);
    ray.y = ray.y * cos(cD.y) + temp.x * sin(cD.y);
    temp.x = ray.z;
    ray.z = ray.z * cos(cD.x) - ray.x * sin(cD.x);
    ray.x = ray.x * cos(cD.x) + temp.x * sin(cD.x);
}

void sphere(vec4 posRad, vec3 sColor) {
    vec3 obj = posRad.xyz - center;
    vec3 temp = vec3(dot(obj, ray), dot(obj, obj), 0.);
    if ((temp.x > 0.0) && (posRad.w * posRad.w > (temp.y - temp.x * temp.x))) {
        temp.z = sqrt(posRad.w * posRad.w - (temp.y - temp.x * temp.x));
        if ((temp.y > posRad.w * posRad.w) && rdist > temp.x - temp.z) {
            rdist = temp.x - temp.z;
            normal = normalize(center + ray * rdist - posRad.xyz);
            tcolor = sColor;
        }
    }
}

void scene() {
    sphere(vec4(iObj1.x, 0, iObj1.y, masses.x), vec3(1, 0, 0));
    sphere(vec4(iObj2.x, 0, iObj2.y, masses.y), vec3(0, 1, 0));
    sphere(vec4(iObj3.x, 0, iObj3.y, masses.z), vec3(0, 0, 1));
    sphere(vec4(0, -10100, 0, 10000), vec3(0.25, 0.25, 0.25));
}

vec3 raytrace(vec2 uv) {
    vec3 CamPos = vec3(480.0, 540.0, 0);
    vec2 CamDir = vec2(0, -1.0);
    setVec(CamPos, vec3(uv, 1.0));
    dirVec(CamDir);
    rdist = maxDist;
    scene();
    if (rdist < maxDist) {
        vec3 light = vec3(480, 20, 360);
        vec3 lightVec = normalize(light - (center + rdist * ray));
        vec3 saveC = vec3(clamp(dot(lightVec, normal), 0., 1.));
        vec3 saveOC = tcolor;
        center = center + rdist * ray + normal / 100000.;
        ray = lightVec;
        rdist = maxDist;
        scene();
        if (rdist < maxDist) {
            return saveOC * 0.02;
        }
        return vec3((saveC + 0.02) * saveOC);
    }
    else {
        return vec3(0);
    }
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

    if (iPaused == 0 && iRaytracer == 1) {
        vec2 uv = (gl_FragCoord.xy - vec2(480, 360)) / vec2(720, 720);
        c = pow(raytrace(uv), vec3(0.4545));
    } else {
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
            c += m ? vec3(0.5, 0.5, 1) : vec3(0, 0, 1);
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
            if (circle(iObj1.xy + iObj1.zw * 30, 4, gl_FragCoord.xy)) {
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
    }

    // buttons
    if (gl_FragCoord.x >= 820 || gl_FragCoord.y > 700) {

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

        //raytracer button
        brighten = distance(vec2(890, 710), iMouse.xy) < 14.0;
        if (iRaytracer == 0) {
            d = segment(gl_FragCoord.xy, vec2(922-40, 703), vec2(938-40, 717)) - 1.5;
            if (d <= 0) {
                c = brighten ? vec3(1) : vec3(0.5);
            }
        }
        if (circle(vec2(890, 710), 8, gl_FragCoord.xy) && !circle(vec2(890, 710), 6, gl_FragCoord.xy)) {
            c = brighten ? vec3(1) : vec3(0.5);
        }
    }

    color = vec4(c, 1.0);
}
