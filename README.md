# Levyra Universal — Cross-Platform Music Client & Studio

<div align="center">
  <h3>Кроссплатформенный музыкальный плеер и загрузчик нового поколения</h3>
  <p>Объединение каталогов <b>YouTube Music</b>, <b>SoundCloud</b>, <b>Яндекс Музыки</b> и локальной медиатеки с бескомпромиссным качеством звука и строгой дизайн-системой Levyra.</p>
</div>

---

## 🎧 Ключевые возможности

### 1. Единый мульти-провайдер каталогов (`CompositeMusicProvider`)
* **YouTube Music**: Стриминг аудио (Opus 160k / AAC 140k) и видео через нативный профиль iOS Innertube без ограничений и шифрования.
* **Яндекс Музыка**: Поддержка HQ 320 kbps (MD5-подпись `XGRlBW9FXlekgbPrRHuSiA`), станция «Моя волна» (`rotor/station/user:onyourwave`) и персональные полки (`/landing3`).
* **SoundCloud**: Автоматический парсинг активного `client_id` из веб-бандлов, прогрессивный MP3 и HLS Opus стриминг.
* **Локальные файлы**: Поддержка FLAC, ALAC, MP3, AAC с редактором ID3v2.4 и Vorbis тегов.

### 2. Студийный звуковой DSP-тракт и отказоустойчивость
* **Локальный Streaming Cache Proxy**: HTTP-сервер на `127.0.0.1` с поддержкой Range 206 для мгновенного старта и чанкового кэширования на диск.
* **ReplayGain**: Умная нормализация громкости (0.2x–1.5x) между разными источниками без клиппинга.
* **10-полосный параметрический эквалайзер**: 31 Гц – 16 кГц со студийными пресетами.
* **SponsorBlock & SkipSilence**: Автоматический пропуск немузыкальных пауз, интро, аутро и тишины.

### 3. Интерфейс Levyra Dark-First
* **Круглый кластер авторов (`PlayerTopArtistCluster`)**: Отображение круглых аватарок артистов (46px со сдвигом 34px и бейджем `+N`) со шторкой выбора [`PlayerArtistPickerSheet`].
* **Бесшовный режим `[ Песня | Клип ]`**: Мгновенный переход на видеопоток YouTube с синхронизацией таймкода и жестами масштабирования (Pinch-to-zoom 1.0x–5.0x).
* **Синхронные караоке-тексты (LRC)**: Живой эквалайзер, подсветка активной строки и перемотка по тапу.
* **Desktop Mini-Player**: Компактный плавающий режим «Поверх всех окон» (Picture-in-Picture).
* **Приватный «Пульс прослушивания»**: Локальная аналитика времени прослушивания и пиковых часов без телеметрии.
* **1-Клик бэкап и восстановление**: Полная сохранность медиатеки в JSON.

---

## 📱 Кроссплатформенная поддержка

| Платформа | Формат сборки | Статус |
| :--- | :--- | :--- |
| **Android** | `.apk` (ARM64 / ARMv7 / x86_64) | ✅ Готово |
| **iOS** | `.ipa` (AltStore / TrollStore / SideStore) | ✅ Готово |
| **macOS** | `.app` / `.zip` (Apple Silicon & Intel) | ✅ Готово |
| **Windows** | `.exe` (x64 Installer / Portable) | ✅ Готово |
| **Linux** | `.tar.gz` / `.AppImage` (x64) | ✅ Готово |

---

## 🚀 Бесплатная облачная сборка (CI/CD)

В репозиторий вшиты готовые манифесты для сборки без использования вашего ПК и без GitHub Actions:

* **[Codemagic](https://codemagic.io/)** ([`codemagic.yaml`](codemagic.yaml)): 500 бесплатных минут/мес на Apple Silicon M2, Windows и Linux.
* **[Azure Pipelines](https://dev.azure.com/)** ([`azure-pipelines.yml`](azure-pipelines.yml)): 1800 бесплатных минут/мес на hosted агентах macOS, Windows и Ubuntu.
* **[GitLab CI](https://gitlab.com/)** ([`.gitlab-ci.yml`](.gitlab-ci.yml)): 400 бесплатных минут/мес на shared раннерах.

---

## 🛠 Структура проекта

```
lib/
├── audio/          # PlaybackController, StreamCacheProxy, DSP, SponsorBlock
├── core/           # Цветовые токены Levyra, типографика, унифицированные модели
├── database/       # LocalDatabase (SQLite, избранное, история, бэкап)
├── downloader/     # Менеджер скачиваний и Id3TagWriter (TIT2, TPE1, TALB, APIC)
├── recognition/    # Сервис распознавания музыки (Shazam / AudD)
├── sources/        # YouTube Music, SoundCloud, Yandex Music, Composite Provider
└── ui/             # Виджеты плеера, экраны артистов, Главная, Обзор, Медиатека
```

---

## 📄 Лицензия

GPL-3.0 License. Создано на основе стандартов [Levyra-deepsound](https://github.com/boredkq/Levyra-deepsound).
