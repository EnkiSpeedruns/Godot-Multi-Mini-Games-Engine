# 🎮 Godot Multi Minigame Engine – 2D Component-Based Architecture

![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478cbf?logo=godot-engine&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Status: Early Development](https://img.shields.io/badge/Status-Early%20Dev-yellow)

**Un laboratorio de minijuegos 2D en Godot 4.5** diseñado para enseñar buenas prácticas, arquitectura escalable y reutilización de componentes.  
Cada minijuego introduce conceptos nuevos del motor, mientras que la base del proyecto mantiene un estándar limpio y profesional.

👉 Ideal para: Autodidactas, educadores, estudiantes, o cualquiera que quiera ver Godot 4 en acción con código modular.

---

## ✨ Filosofía del Proyecto

Este no es solo un conjunto de minijuegos sueltos. Es un **ecosistema** donde:

- ✅ Los minijuegos se **integran sin tocar código existente** (solo registro en el GameManager).
- ✅ Usamos **composición sobre herencia**: `Player` tiene un `HealthComponent`, no hereda de una clase base.
- ✅ La comunicación es por **señales**, no referencias directas acopladas.
- ✅ Todo componente relevante se expone con `@export` para ajustarse desde el inspector.
- ✅ El menú principal se auto-genera a partir de un array de datos.

> 📚 Lee la [hoja de ruta y documentación técnica](./proyecto_minijuegos_godot_roadmap.md) para entender la arquitectura completa.

---

## 🧱 Estructura Base

res://
├── autoload/ # GameManager, AudioManager, SceneTransition

├── components/ # Health, Hitbox, Movement, InputBuffer, ScreenWrap, etc.

├── scenes/

│ ├── main_menu/ # Menú dinámico, botones auto-generados

│ └── minigames/ # Cada juego en su carpeta (platformer, snake, etc.)

└── resources/ # Sprites, audio, fonts, thumbnails


---

## 🕹️ Minijuegos (Planificados y en Desarrollo)

| Minijuego | Conceptos Clave | Estado |
|----------|----------------|--------|
| 🟩 Platformer | CharacterBody2D, TileMap, coyote time, jump buffering | 🚧 En desarrollo |
| 🐍 Snake | Grid movement, auto-colisión, step-based timer | ⏳ Planeado |
| 🧱 Breakout | RigidBody2D, rebotes, power-ups | ⏳ Planeado |
| 🚀 Shoot 'Em Up | Object pooling, spawners, parallax | ⏳ Planeado |
| 👊 Beat 'Em Up | Input buffering, combos, YSort | ⏳ Planeado |
| ☄️ Asteroids | Screen wrap, thrust, fragmentación | ⏳ Planeado |

¿Quieres añadir tu propio minijuego? Sigue el [flujo de integración](./proyecto_minijuegos_godot_roadmap.md#flujo-de-integración-de-nuevos-minijuegos) y lanza un PR.

---

## 🧩 Componentes Reutilizables (Core)

| Componente | Propósito |
|-----------|-----------|
| `HealthComponent` | Vida, daño, curación, invencibilidad |
| `Hitbox/Hurtbox` | Sistema de daño genérico con capas |
| `MovementComponent` | Aceleración, fricción, velocidad máxima |
| `InputBufferComponent` | Buffer de inputs para combos/jump buffering |
| `ScreenWrapComponent` | Teletransporte al bordear pantalla (Asteroids) |
| `GridMovementComponent` | Movimiento por casillas (Snake, puzzles) |

... y más en [`components/`](./components)

---

## 🚀 Cómo Empezar

### Requisitos
- [Godot 4.5](https://godotengine.org/download) (o superior 4.x)

### Pasos
1. Clona el repositorio:
   ```bash
   git clone https://github.com/tuusuario/Godot-Multi-Minigames-Engine.git

   Abre el proyecto en Godot.

2. Ejecuta la escena main_menu.tscn.

3. ¡Explora los minijuegos disponibles!

💡 ¿Primera vez con Godot 4? Revisa la guía de inicio rápido (próximamente).

## 🤝 ¿Cómo Contribuir?

¡Este proyecto vive de la comunidad! Toda ayuda suma, sin importar tu nivel:

. 🐛 Reporta bugs o problemas de arquitectura.

. 🧪 Prueba minijuegos y sugiere mejoras.

. 🎨 Crea sprites, sonidos o thumbnails.

. 📝 Mejora la documentación o los comentarios.

. 🕹️ ¡Añade un minijuego nuevo!

Revisa la guía de contribución (próximamente) y nuestro código de conducta.

## 📚 Aprendizaje y Contexto

Este proyecto nace como una forma práctica de aprender Godot 4 en profundidad, aplicando patrones de diseño y buenas prácticas desde el día cero.

Cada decisión de arquitectura está explicada en la hoja de ruta.

Ideal para quienes ya hicieron algunos tutoriales y quieren dar el salto a proyectos más estructurados.

También es útil para enseñar en entornos educativos (bootcamps, talleres, aulas).

## 📄 Licencia

Distribuido bajo licencia MIT. Ver LICENSE para más información.

## 🌟 Apoya el Proyecto

⭐ Dale estrella al repo — me ayuda a saber que esto es útil.

🐦 Comparte en redes: #GodotEngine #Minigames #OpenSource

💬 Comenta, pregunta, sugiere. ¡Me encantaría escuchar tu experiencia!
