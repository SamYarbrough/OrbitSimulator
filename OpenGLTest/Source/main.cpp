#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <chrono>
#include <thread>
#include <cmath>

const float windowX = 960;
const float windowY = 720;

const float G = 20.0; // gravitational constant for this specific simulation

float obj1_x; float obj1_y;
float obj1_x_vel; float obj1_y_vel;
float obj1_mass;

float obj2_x; float obj2_y;
float obj2_x_vel; float obj2_y_vel;
float obj2_mass;

float obj3_x; float obj3_y;
float obj3_x_vel; float obj3_y_vel;
float obj3_mass;

double xpos, ypos; // mouse positions
float mouseDown = 0;

float frameCount = 0;

float calcRadius(float mass, float mult) {
    return (float)sqrt(mass / 3.141593) * mult;
}

float distance(float x1, float y1, float x2, float y2) {
    return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
    if (distance(obj1_x, obj1_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj1_mass, 16)) {
        obj1_mass += (float)yoffset / 10;
        obj1_mass = (float)fmax((double)obj1_mass, 0.5);
    }
    else if (distance(obj2_x, obj2_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj2_mass, 16)) {
        obj2_mass += (float)yoffset / 10;
        obj2_mass = (float)fmax((double)obj2_mass, 0.5);
    }
    else if (distance(obj3_x, obj3_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj3_mass, 16)) {
        obj3_mass += (float)yoffset / 10;
        obj3_mass = (float)fmax((double)obj3_mass, 0.5);
    }
}

void resetObjects() {
    obj1_x = 480; obj1_y = 360;
    obj1_x_vel = -0.5; obj1_y_vel = 0;
    obj1_mass = 1;

    obj2_x = 240 + 480; obj2_y = 120 + 360;
    obj2_x_vel = 0; obj2_y_vel = 0;
    obj2_mass = 5;

    obj3_x = -360 + 480; obj3_y = -120 + 360;
    obj3_x_vel = 0; obj3_y_vel = 0;
    obj3_mass = 2;
}

// 3 body physics simulation
void ApplyPhysics() {
    float d12 = distance(obj1_x, obj1_y, obj2_x, obj2_y);
    float d23 = distance(obj2_x, obj2_y, obj3_x, obj3_y);
    float d31 = distance(obj3_x, obj3_y, obj1_x, obj1_y);

    float F12 = G * (obj1_mass * obj2_mass) / (d12 * d12);
    float F23 = G * (obj2_mass * obj3_mass) / (d23 * d23);
    float F31 = G * (obj3_mass * obj1_mass) / (d31 * d31);


    float vec1_x = F12 * ((obj2_x - obj1_x) / d12) + F31 * ((obj3_x - obj1_x) / d31);
    float vec2_x = F12 * ((obj1_x - obj2_x) / d12) + F23 * ((obj3_x - obj2_x) / d23);
    float vec3_x = F31 * ((obj1_x - obj3_x) / d31) + F23 * ((obj2_x - obj3_x) / d23);

    float vec1_y = F12 * ((obj2_y - obj1_y) / d12) + F31 * ((obj3_y - obj1_y) / d31);
    float vec2_y = F12 * ((obj1_y - obj2_y) / d12) + F23 * ((obj3_y - obj2_y) / d23);
    float vec3_y = F31 * ((obj1_y - obj3_y) / d31) + F23 * ((obj2_y - obj3_y) / d23);

    obj1_x_vel += vec1_x;
    obj1_y_vel += vec1_y;
    obj2_x_vel += vec2_x;
    obj2_y_vel += vec2_y;
    obj3_x_vel += vec3_x;
    obj3_y_vel += vec3_y;

    obj1_x += obj1_x_vel;
    obj1_y += obj1_y_vel;
    obj2_x += obj2_x_vel;
    obj2_y += obj2_y_vel;
    obj3_x += obj3_x_vel;
    obj3_y += obj3_y_vel;

    //std::cout << obj3_x << "\n";
    //std::cout << obj3_y << "\n";
}

struct ShaderProgramSource {
    std::string VertexSource;
    std::string FragmentSource;
};

static ShaderProgramSource ParseShader(const std::string& filepath) {
    std::ifstream stream(filepath);

    enum class ShaderType {
        NONE = -1, VERTEX = 0, FRAGMENT = 1
    };

    std::string line;
    std::stringstream ss[2];
    ShaderType type = ShaderType::NONE;
    while (getline(stream, line)) {
        if (line.find("shader") != std::string::npos) {
            if (line.find("vertex") != std::string::npos) {
                type = ShaderType::VERTEX;
            }
            else if (line.find("fragment") != std::string::npos) {
                type = ShaderType::FRAGMENT;
            }
        }
        else {
            ss[(int)type] << line << "\n";
        }
    }
    return { ss[0].str(), ss[1].str() };
}

static unsigned int CompileShader(unsigned int type, const std::string& source) {
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE) {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)_malloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);
        std::cout << (type == GL_VERTEX_SHADER ? "Vertex" : "fragment") << " shader compilation failed:\n";
        std::cout << message << "\n";
        glDeleteShader(id);
        return 0;
    }

    return id;
}

static unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader) {
    unsigned int program = glCreateProgram();
    unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
    unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glValidateProgram(program);

    glDeleteShader(vs);
    glDeleteShader(fs);

    return program;
}

int main(void)
{
    using namespace std::chrono_literals;

    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow((int)windowX, (int)windowY, "Trigophers' 2D Orbit Simulator", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    GLenum err = glewInit();
    if (GLEW_OK != err)
    {
        /* Problem: glewInit failed, something is seriously wrong. */
        fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
    }
    fprintf(stdout, "Status: Using GLEW %s\n", glewGetString(GLEW_VERSION));

    // -----------------------------

    float positions[8] = {
        -1.0, -1.0,
         1.0, -1.0,
         1.0,  1.0,
        -1.0,  1.0
    };

    unsigned int indices[6] = {
        0, 1, 2,
        2, 3, 0
    };

    unsigned int buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, 8 * sizeof(float), positions, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);

    unsigned int ibo;
    glGenBuffers(1, &ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(unsigned int), indices, GL_STATIC_DRAW);

    ShaderProgramSource source = ParseShader("res/shaders/basic.shader");
    unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
    glUseProgram(shader);

    bool mouseWentDown = false;
    float paused = 1; // pause the simulation
    float showVels = 0;
    float raytracerMode = 0;
    int dragObjNum = 0;
    int dragVelNum = 0;

    resetObjects();

    glfwSetScrollCallback(window, scroll_callback);

    //loop
    while (!glfwWindowShouldClose(window))
    {
        auto start_timer = std::chrono::high_resolution_clock::now(); //limit framerate

        glClear(GL_COLOR_BUFFER_BIT); // clear screen for following shader render


        glfwGetCursorPos(window, &xpos, &ypos); // cursor position

        // cursor state
        int mState = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);
        if (mState == GLFW_PRESS) {
            if (mouseDown == 1) {
                mouseWentDown = false; // check if the mouse went down the current frame
            } else {
                mouseWentDown = true; // if mouse went down, see if it was clicking any of the circles or their velocities
                if (paused == 1) {
                    if (distance(obj1_x + obj1_x_vel * 30, obj1_y + obj1_y_vel * 30, (float)xpos, 720 - (float)ypos) < 4) {
                        dragVelNum = 1;
                    } else if (distance(obj2_x + obj2_x_vel * 30, obj2_y + obj2_y_vel * 30, (float)xpos, 720 - (float)ypos) < 4) {
                        dragVelNum = 2;
                    } else if (distance(obj3_x + obj3_x_vel * 30, obj3_y + obj3_y_vel * 30, (float)xpos, 720 - (float)ypos) < 4) {
                        dragVelNum = 3;
                    } else {
                        dragVelNum = 0;

                        if (distance(obj1_x, obj1_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj1_mass, 16)) {
                            dragObjNum = 1;
                        } else if (distance(obj2_x, obj2_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj2_mass, 16)) {
                            dragObjNum = 2;
                        } else if (distance(obj3_x, obj3_y, (float)xpos, 720 - (float)ypos) < calcRadius(obj3_mass, 16)) {
                            dragObjNum = 3;
                        } else {
                            dragObjNum = 0;
                        }
                    }
                }
            }

            mouseDown = 1;
        } else {
            mouseDown = 0;
            mouseWentDown = false;
            dragObjNum = 0;
            dragVelNum = 0;
        }

        // change object velocities based on mouse position
        if (dragVelNum == 1) {
            obj1_x_vel = ((float)xpos - obj1_x) / 30;
            obj1_y_vel = (720 - (float)ypos - obj1_y) / 30;
        }
        if (dragVelNum == 2) {
            obj2_x_vel = ((float)xpos - obj2_x) / 30;
            obj2_y_vel = (720 - (float)ypos - obj2_y) / 30;
        }
        if (dragVelNum == 3) {
            obj3_x_vel = ((float)xpos - obj3_x) / 30;
            obj3_y_vel = (720 - (float)ypos - obj3_y) / 30;
        }

        // change object positions based on mouse position
        if (dragObjNum == 1) {
            obj1_x = (float)xpos;
            obj1_y = 720 - (float)ypos;
        }
        if (dragObjNum == 2) {
            obj2_x = (float)xpos;
            obj2_y = 720 - (float)ypos;
        }
        if (dragObjNum == 3) {
            obj3_x = (float)xpos;
            obj3_y = 720 - (float)ypos;
        }

        if (mouseWentDown && distance(950, 10, (float)xpos, (float)ypos) < 10.0) {
            paused = abs(paused - 1); // toggle pause button
        }
        if (mouseWentDown && distance(950-20, 10, (float)xpos, (float)ypos) < 10.0) {
            showVels = abs(showVels - 1); // toggle pause button
        }
        if (mouseWentDown && distance(950 - 40, 10, (float)xpos, (float)ypos) < 10.0) {
            resetObjects(); // reset all objects
        }
        if (mouseWentDown && distance(950 - 60, 10, (float)xpos, (float)ypos) < 10.0) {
            raytracerMode = abs(raytracerMode - 1);
        }

        // frame number input
        GLint UniformLocation = glGetUniformLocation(shader, "iFrame");
        glProgramUniform1f(shader, UniformLocation, frameCount);

        // mouse position/click input
        UniformLocation = glGetUniformLocation(shader, "iMouse");
        glProgramUniform3f(shader, UniformLocation, (float)xpos, (float)(720.0-ypos), mouseDown);

        if (paused == 0) {
            ApplyPhysics();
        }

        UniformLocation = glGetUniformLocation(shader, "iPaused");
        glProgramUniform1f(shader, UniformLocation, paused);
        UniformLocation = glGetUniformLocation(shader, "iShowVels");
        glProgramUniform1f(shader, UniformLocation, showVels);

        // object locations
        UniformLocation = glGetUniformLocation(shader, "iObj1");
        glProgramUniform4f(shader, UniformLocation, obj1_x, obj1_y, obj1_x_vel, obj1_y_vel);
        UniformLocation = glGetUniformLocation(shader, "iObj2");
        glProgramUniform4f(shader, UniformLocation, obj2_x, obj2_y, obj2_x_vel, obj2_y_vel);
        UniformLocation = glGetUniformLocation(shader, "iObj3");
        glProgramUniform4f(shader, UniformLocation, obj3_x, obj3_y, obj3_x_vel, obj3_y_vel);

        UniformLocation = glGetUniformLocation(shader, "iObjMasses");
        glProgramUniform3f(shader, UniformLocation, obj1_mass, obj2_mass, obj3_mass);

        UniformLocation = glGetUniformLocation(shader, "iRaytracer");
        glProgramUniform1f(shader, UniformLocation, raytracerMode);



        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);

        glfwSwapBuffers(window);
        glfwPollEvents();

        // limit framerate
        auto end_timer = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> elapsed = end_timer - start_timer;
        int millisecs = (int)((1.0 / 60.0 - elapsed.count())*1000);
        std::this_thread::sleep_for(std::chrono::milliseconds(millisecs));

        frameCount++;
    }

    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}
