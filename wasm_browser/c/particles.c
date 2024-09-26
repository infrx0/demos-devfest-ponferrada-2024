#include <emscripten.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define MAX_PARTICLES 2000
#define SHAPE_CIRCLE 1
#define SHAPE_SQUARE 2
#define SHAPE_TRIANGLE 3
#define PARTICLE_SCALE 0.05

typedef struct {
    float x, y;
    float vx, vy;
    int shape;
    float size;
    char color[7];
} Particle;

Particle particles[MAX_PARTICLES];
int canvas_width, canvas_height;

void init_particle(Particle *p) {
    p->x = rand() % canvas_width;
    p->y = rand() % canvas_height;
    p->vx = (float)(rand() % 5 - 2);
    p->vy = (float)(rand() % 5 - 2);
    p->shape = rand() % 3 + 1;
    p->size = (rand() % 30 + 10) * PARTICLE_SCALE;
    sprintf(p->color, "#%06x", rand() % 0xFFFFFF);
}

void init_system(int width, int height) {
    canvas_width = width;
    canvas_height = height;
    srand(time(NULL));

    for (int i = 0; i < MAX_PARTICLES; i++) {
        init_particle(&particles[i]);
    }
}

void move_particle(Particle *p) {
    p->x += p->vx;
    p->y += p->vy;

    if (p->x - p->size < 0 || p->x + p->size > canvas_width) {
        p->vx *= -1;
    }
    if (p->y - p->size < 0 || p->y + p->size > canvas_height) {
        p->vy *= -1;
    }
}

void detect_collisions(Particle *p1, Particle *p2) {
    float dx = p1->x - p2->x;
    float dy = p1->y - p2->y;
    float distance = sqrt(dx * dx + dy * dy);
    
    if (distance < (p1->size + p2->size)) {
        float temp_vx = p1->vx;
        float temp_vy = p1->vy;
        p1->vx = p2->vx;
        p1->vy = p2->vy;
        p2->vx = temp_vx;
        p2->vy = temp_vy;
    }
}

void draw_particle(Particle *p) {
    switch (p->shape) {
        case SHAPE_CIRCLE:
            EM_ASM_({
                draw_circle($0, $1, $2, UTF8ToString($3));
            }, p->x, p->y, p->size, p->color);
            break;
        case SHAPE_SQUARE:
            EM_ASM_({
                draw_square($0, $1, $2, UTF8ToString($3));
            }, p->x, p->y, p->size, p->color);
            break;
        case SHAPE_TRIANGLE:
            EM_ASM_({
                draw_triangle($0, $1, $2, UTF8ToString($3));
            }, p->x, p->y, p->size, p->color);
            break;
    }
}

void EMSCRIPTEN_KEEPALIVE main_loop() {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        move_particle(&particles[i]);
        draw_particle(&particles[i]);

        for (int j = i + 1; j < MAX_PARTICLES; j++) {
            detect_collisions(&particles[i], &particles[j]);
        }
    }
}

