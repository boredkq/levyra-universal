---
name: audio-engine-and-caching
description: Instructions and architectural patterns for cross-platform audio playback, DSP processing, SponsorBlock, motion artwork, music recognition, background service, OS media integration, offline caching, and tag writing.
---

# Инструкция по аудио-движку, DSP, SponsorBlock и интеграциям

Данный навык описывает реализацию полноценного аудио-ядра студийного уровня, умного кэширования, распознавания музыки и интеграций с ОС.

## 1. Пайплайн воспроизведения и Локальный Прокси-Кэшер (Streaming Proxy)
- Плеер отправляет запрос на локальный прокси: `http://localhost:port/stream?id=...`.
- Прокси проверяет локальный LRU-кэш:
  - Если файл уже в кэше: отдает локальные байты со статусом `206 Partial Content`.
  - Если файла нет: транслирует чанки удаленного сервера плееру и параллельно пишет на диск во временный кэш.
  - По завершении трек готов к мгновенному офлайн-прослушиванию.

## 2. DSP и Аудио-процессинг студийного уровня
- **ReplayGain / Умная нормализация громкости**:
  - Анализ пиковых значений (LUFS / Track Gain).
  - Автоматическая подгонка уровня сигнала, чтобы треки из SoundCloud, YouTube Music и Яндекс Музыки звучали с одинаковой громкостью без ручной регулировки.
- **Crossfade и DJ Soft Mode**:
  - Настраиваемый плавный переход между треками (1–12 сек): текущий трек плавно затихает, а следующий нарастает.
- **Параметрический эквалайзер**:
  - 5/10-полосный эквалайзер с регулировкой частот (60Hz – 16kHz).
  - Пресеты: Rock, Pop, Classical, Bass Boost, Vocal Enhancer, Electronic.
  - Bass Boost (усиление низких частот) и Virtualizer (расширение стереобазы / 3D Spatial Audio).
- **Tempo и Pitch**:
  - Изменение скорости воспроизведения без искажения тональности или с сохранением питча.

## 3. SponsorBlock и SkipSilence (Автопропуск немузыкальных фрагментов)
- Запрос таймкодов через SponsorBlock API: `GET https://sponsor.ajay.app/api/skipSegments?videoID=...`
- Категории для пропуска:
  - `sponsor` (реклама спонсоров)
  - `intro` / `outro` (заставки каналов, титры)
  - `music_offtopic` (диалоги персонажей в музыкальных видеоклипах, прерывающие музыку)
- При достижении позиции `startMs` плеер автоматически выполняет мгновенный `seek(endMs)` с плавной визуальной анимацией пропуска.
- `SkipSilence`: определение уровня тишины (<-60dB) в первых и последних секундах файла и их автоматическое отсечение.

## 4. Motion Artwork (Анимированные видео-обложки / Canvas)
- Запрос живых обложек через провайдеры (`AppleMotionArtworkProvider`, `TidalVideoCoverProvider`, Spotify Canvas).
- Отрисовка зацикленного видеоряда (`.mp4` H.264/AV1 без звуковой дорожки) под управлением `MotionArtworkEngine` с аппаратным декодированием и плавной сменой при переключении песен.

## 5. Распознавание музыки (Music Recognition / Shazam / AudD)
- Модуль захвата звукового потока с микрофона (PCM 44.1kHz 16-bit).
- Генерация акустического отпечатка (Audio Fingerprint / Landmark points).
- Запрос к Recognition API (Shazam / AudD) и возврат `TrackMatch`.
- Автоматический поиск совпадения в каталоге приложения и запуск трека в 1 клик.

## 6. Системные медиа-контролы (OS Media Integration)
- **macOS**: `MPNowPlayingInfoCenter` и `MPRemoteCommandCenter` (TouchBar, Центр управления, клавиатура).
- **Windows**: `SystemMediaTransportControls` (SMTC).
- **Linux**: D-Bus спецификация `org.mpris.MediaPlayer2`.
- **Android / iOS**: Фоновый сервис с уведомлением и кнопками управления на заблокированном экране.

## 7. Менеджер скачиваний и Тегирование
- Очередь загрузок с поддержкой паузы и возобновления через HTTP Range.
- Вшивание обложек в максимальном разрешении (APIC), ID3v2.4 / Vorbis тегов и синхронизированных слов песни.
- Шаблон путей сохранения: `{Music}/{Artist}/{Album}/{TrackNumber} - {Title}.{ext}`.
