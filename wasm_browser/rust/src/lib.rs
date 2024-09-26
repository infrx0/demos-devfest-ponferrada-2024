use wasm_bindgen::prelude::*;
use web_sys::CanvasRenderingContext2d;
use js_sys::Math::{random, floor};

#[wasm_bindgen]
pub struct Particle {
    x: f64,
    y: f64,
    vx: f64,
    vy: f64,
    ax: f64,
    ay: f64,
    color: String,
}

#[wasm_bindgen]
impl Particle {
    pub fn new(canvas_width: f64, canvas_height: f64) -> Particle {
        let r = (floor(random() * 255.0)) as u8;
        let g = (floor(random() * 255.0)) as u8;
        let b = (floor(random() * 255.0)) as u8;
        let color = format!("rgb({}, {}, {})", r, g, b);

        Particle {
            x: random() * canvas_width,
            y: random() * canvas_height,
            vx: (random() - 0.5) * 4.0,
            vy: (random() - 0.5) * 4.0,
            ax: (random() - 0.5) * 0.1,
            ay: (random() - 0.5) * 0.1,
            color,
        }
    }

    pub fn update(&mut self, canvas_width: f64, canvas_height: f64) {
        self.vx += self.ax;
        self.vy += self.ay;
        self.x += self.vx;
        self.y += self.vy;

        // Rebote en los bordes
        if self.x <= 0.0 || self.x >= canvas_width {
            self.vx *= -1.0;
        }
        if self.y <= 0.0 || self.y >= canvas_height {
            self.vy *= -1.0;
        }
    }

    pub fn draw(&self, ctx: &CanvasRenderingContext2d) {
        ctx.begin_path();
        ctx.arc(self.x, self.y, 5.0, 0.0, std::f64::consts::PI * 2.0).unwrap();
        ctx.set_fill_style(&JsValue::from_str(&self.color));
        ctx.fill();
    }
}

#[wasm_bindgen]
pub struct ParticleSystem {
    particles: Vec<Particle>,
}

#[wasm_bindgen]
impl ParticleSystem {
    pub fn new(canvas_width: f64, canvas_height: f64) -> ParticleSystem {
        let particles = (0..1000)
            .map(|_| Particle::new(canvas_width, canvas_height))
            .collect();
        ParticleSystem { particles }
    }

    pub fn update_and_draw(&mut self, ctx: &CanvasRenderingContext2d, canvas_width: f64, canvas_height: f64) {
        ctx.clear_rect(0.0, 0.0, canvas_width, canvas_height);

        for particle in self.particles.iter_mut() {
            particle.update(canvas_width, canvas_height);
            particle.draw(&ctx);
        }
    }
}

