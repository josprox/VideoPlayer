# 📽️ Video — Flutter Video Browser & Player

Un visualizador de videos multiplataforma (Android, iOS, Windows, Linux, macOS) construido con **Flutter**, que permite:

✅ Seleccionar múltiples carpetas locales
✅ Escanear automáticamente videos compatibles
✅ Reproducirlos usando **video_player + Chewie**
✅ Guardar las rutas configuradas con **Shared Preferences**
✅ Manejar permisos por plataforma
✅ Usar Material Design 3 con estilo moderno y oscuro

---

## ✨ Características principales

* **Gestor de carpetas de video**

  * Añade varias carpetas desde el explorador del sistema.
  * Evita duplicados.
  * Guarda las rutas de forma persistente.
  * Permite eliminar rutas fácilmente.

* **Escaneo inteligente**

  * Procesa carpetas usando streams para evitar bloqueos en la UI.
  * Verifica extensiones: `.mp4`, `.mov`, `.avi`, `.mkv`, `.wmv`.

* **Reproductor completo**

  * Controles modernos gracias a **Chewie**.
  * AutoPlay.
  * Soporte para múltiples plataformas.
  * Mantiene relación de aspecto real del video.

* **Material Design 3 (modo oscuro)**

  * UI moderna, elegante y expresiva.
  * Cards, listas, iconografía y color basado en Seed.

---

## 🏗️ Arquitectura

```
lib/
 ├── main.dart
 ├── PreferencesService.dart      # Servicio de almacenamiento persistente
 ├── SettingsScreen.dart          # Gestión de rutas de carpetas
 ├── VideoListScreen.dart         # Listado de videos + permisos
 ├── VideoPlayerScreen.dart       # Reproductor Chewie/video_player
```

El flujo principal del sistema:

1. El usuario abre la app → se cargan rutas guardadas.
2. Se escanean todas las carpetas configuradas.
3. La UI muestra las mini tarjetas de cada video.
4. Al abrir un video, se inicializa el reproductor con `Chewie`.
5. El usuario puede volver y agregar más rutas desde Configuración.

---

## 📦 Dependencias utilizadas

```yaml
video_player: ^2.10.0        # Motor de reproducción
chewie: ^1.13.0              # Controles de reproductor
file_picker: ^10.3.3         # Selección de carpetas
shared_preferences: ^2.5.3   # Guardar rutas de carpetas
permission_handler: ^12.0.1  # Permisos Android/iOS
path_provider: ^2.1.5        # Acceso a paths del sistema
device_info_plus: ^12.2.0    # Saber versión de Android (SDK)
pip_view: ^0.9.7             # (Opcional) Picture-in-Picture
```

---

## ⚙️ Instalación y ejecución

### 1. Clonar el repositorio

```bash
git clone https://github.com/josprox/VideoPlayer
cd VideoPlayer
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Ejecutar

```bash
flutter run
```

---

## 📂 Uso de la aplicación

### 🟦 Pantalla principal

* Escanea automáticamente todas las carpetas guardadas.
* Muestra el listado de videos disponibles.
* Cada elemento indica:

  * Nombre del archivo
  * Carpeta del video

### 🟪 Configuración de carpetas

* Pulsa el botón (+) para añadir una nueva carpeta.
* Si la carpeta ya existe, se mostrará una alerta.
* Puedes borrar carpetas desde la lista de configuraciones.

### 🟥 Reproducción

* Se usa `Chewie` para una experiencia más completa:

  * Pausa, play, volumen, avance, pantalla completa, etc.
  * Mantiene la relación de aspecto real del video.

---

## 📱 Permisos en Android (SDK ≥ 33)

Android 13+ requiere permisos diferentes para acceder a videos:

* Si el SDK ≥ 33 → pide `Permission.videos`
* Si el SDK < 33 → pide `Permission.storage`

El código ya lo maneja automáticamente.

---

