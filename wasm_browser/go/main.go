package main

import (
    "fmt"
    "math"
    "math/rand"
    "syscall/js"
)

const ParticleSize = 3.0

type Particle struct {
    x, y      float64
    vx, vy    float64
    color     string
    isCircle  bool
}

func newParticle(width, height float64) Particle {
    r := rand.Intn(256)
    g := rand.Intn(256)
    b := rand.Intn(256)
    color := fmt.Sprintf("rgb(%d, %d, %d)", r, g, b)

    return Particle{
        x:       rand.Float64()*(width-2*ParticleSize) + ParticleSize, 
        y:       rand.Float64()*(height-2*ParticleSize) + ParticleSize, 
        vx:      (rand.Float64() - 0.5) * 2.0,
        vy:      (rand.Float64() - 0.5) * 2.0,
        color:   color,
        isCircle: rand.Float64() > 0.5,
    }
}

func (p *Particle) update(width, height float64) {
    p.x += p.vx
    p.y += p.vy

    if p.x <= ParticleSize {
        p.x = ParticleSize
        p.vx *= -1
    }
    if p.x >= width-ParticleSize {
        p.x = width - ParticleSize
        p.vx *= -1
    }
    if p.y <= ParticleSize {
        p.y = ParticleSize
        p.vy *= -1
    }
    if p.y >= height-ParticleSize {
        p.y = height - ParticleSize
        p.vy *= -1
    }
}

func (p *Particle) detectCollision(other *Particle) {
    distance := math.Sqrt((p.x-other.x)*(p.x-other.x) + (p.y-other.y)*(p.y-other.y))
    if distance <= ParticleSize*2 {
        p.vx, other.vx = other.vx, p.vx
        p.vy, other.vy = other.vy, p.vy
    }
}

func (p *Particle) draw(ctx js.Value) {
    ctx.Set("fillStyle", p.color)
    if p.isCircle {
        ctx.Call("beginPath")
        ctx.Call("arc", p.x, p.y, ParticleSize, 0, 2*math.Pi)
        ctx.Call("fill")
    } else {
        ctx.Call("fillRect", p.x-ParticleSize, p.y-ParticleSize, ParticleSize*2, ParticleSize*2)
    }
}

func particleSystem(width, height float64, ctx js.Value) {
    particles := make([]Particle, 1000)
    for i := range particles {
        particles[i] = newParticle(width, height)
    }

    var renderFrame js.Func
    renderFrame = js.FuncOf(func(this js.Value, args []js.Value) interface{} {
        ctx.Call("clearRect", 0, 0, width, height)

        for i := range particles {
            particles[i].update(width, height)
            for j := i + 1; j < len(particles); j++ {
                particles[i].detectCollision(&particles[j])
            }

            particles[i].draw(ctx)
        }

        js.Global().Call("requestAnimationFrame", renderFrame)
        return nil
    })

    js.Global().Call("requestAnimationFrame", renderFrame)
}

func main() {
    c := make(chan struct{}, 0)

    js.Global().Set("particleSystem", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
        width := args[0].Float()
        height := args[1].Float()
        ctx := args[2]
        particleSystem(width, height, ctx)
        return nil
    }))

    <-c
}

