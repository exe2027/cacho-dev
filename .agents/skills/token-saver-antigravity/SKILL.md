---
name: token-saver-antigravity
description: Ahorra tokens en AntiGravity y Cloud Code. Respuestas breves, contexto mínimo, solo archivos indicados. Para modelos Gemini de AntiGravity y Claude Opus 4.6.
---

# Token Saver AntiGravity

Aplica estas reglas en toda tarea de código, salvo que el usuario pida explícitamente una explicación larga.

## Reglas de salida (siempre)

- Sin saludos, sin resúmenes previos ni posteriores, sin explicar lo que vas a hacer.
- Entrega solo: qué cambiaste, archivos tocados y cómo lo verificaste.
- Un objetivo por respuesta. No mezcles análisis, refactor, tests y deploy en un mismo turno.
- Si falta información, pregunta antes de explorar todo el proyecto.

## Reglas de contexto (lo que más ahorra)

- Lee solo los archivos que el usuario indica, con su ruta y rango de líneas si los da.
- No escanees todo el workspace, no re-leas archivos sin cambios, no pegues logs ni código completo: usa solo el fragmento relevante.
- No lances subagentes para tareas pequeñas: cada uno hereda contexto y multiplica el gasto.
- No cargues otras skills salvo que la tarea las exija.
- Excluye siempre del contexto: `.env`, `*.pem`, `*.key`, `secrets/`, `credentials/`, `*.sqlite`, `*.db`, `node_modules/`, `dist/`, `build/`.

## Modelos Gemini en AntiGravity

- Rutina (formato, boilerplate, refactor simple): usa Flash.
- Solo usa Pro para arquitectura, debugging complejo o decisiones con trade-offs.
- Thinking: Low para tareas simples, Medium por defecto, High solo para arquitectura o debugging complejo.
- Prefiere workflows prearmados a planificar desde cero cuando la tarea se repite.

## Claude Opus 4.6 en AntiGravity

- Opus 4.6 es el modelo caro: úsalo solo para trabajo complejo, no para tareas rutinarias.
- No pidas razonamiento extenso ni borradores que nadie va a leer.
- Divide el trabajo complejo en pasos cortos y verificables, un paso por turno.
- Mantén la misma regla de salida: cambio, archivos, verificación. Nada más.

## Al escribir un prompt (para el usuario)

- Indica archivo exacto, no "revisa el proyecto".
- Un objetivo por prompt.
- Pega solo el error y el fragmento relevante, nunca el log completo ni el repo completo.
