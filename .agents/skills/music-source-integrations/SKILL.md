---
name: music-source-integrations
description: Instructions, API specs, and reverse-engineering protocols for integrating YouTube Music, SoundCloud, and Yandex Music audio streams, searches, and metadata into a unified music client.
---

# Инструкция по интеграции музыкальных источников

Данный навык используется при реализации и отладке коннекторов к музыкальным сервисам: YouTube Music, SoundCloud и Яндекс Музыка.

## 1. YouTube Music (Innertube API)

### Архитектура подключения:
- **Базовый URL**: `https://music.youtube.com/youtubei/v1`
- **Клиенты**:
  - `WEB_REMIX` (Web client context, user-agent: Chrome/Desktop)
  - `ANDROID` (Context с версией Android Music app, полезен при обходе некоторых ограничений потока)
- **Поиск**:
  - Endpoint: `/search`
  - POST-запрос с JSON-телом: `{ "context": { "client": { "clientName": "WEB_REMIX", "clientVersion": "1.2024..." } }, "query": "..." }`
  - Парсинг: `musicShelfRenderer`, `musicCardShelfRenderer`, выделение `videoId`, `title`, `artists`, `duration`, `thumbnails`.
- **Получение потока (Audio Stream)**:
  - Endpoint: `/player`
  - POST с `{ "videoId": "...", "context": ... }`
  - Анализ `streamingData.adaptiveFormats`. Фильтрация по `mimeType`:
    - Аудио Opus: `audio/webm; codecs="opus"` (itag 251, ~160 kbps, наивысшее качество на YT)
    - Аудио AAC: `audio/mp4; codecs="mp4a.40.2"` (itag 140, ~128-140 kbps)
  - Если URL зашифрован (содержит параметр `s` или `signatureCipher` / `cipher`):
    - Применить дешифровку через регулярные выражения базового JS-плеера YouTube (reverse, slice, swap операции).
  - Поддержка `Range` заголовков для потокового воспроизведения и возобновления скачивания.

## 2. SoundCloud (Public API v2)

### Архитектура подключения:
- **Базовый URL**: `https://api-v2.soundcloud.com`
- **Аутентификация**: `client_id` передается в query-параметрах.
  - *Динамическое извлечение*: при старте приложения или ошибке 401 парсится HTML `https://soundcloud.com`, находятся скрипты бандла (`https://a-v2.sndcdn.com/assets/...js`), регуляркой извлекается `client_id: "..."`.
- **Поиск**:
  - Endpoint: `/search/tracks?q={query}&client_id={client_id}&limit=20`
- **Получение потока**:
  - В объекте трека поле `media.transcodings`:
    - Progressive MP3 (`format.protocol === "progressive"`): прямая ссылка на MP3 файл через авторизованный запрос к `transcoding.url + "?client_id="`.
    - HLS/m3u8 (`format.protocol === "hls"`): ссылки на чанки Opus/MP3 для адаптивного битрейта.
- **Волноформа (Waveform)**:
  - `waveform_url`: загрузка JSON волноформы для красивой визуализации трека в UI.

## 3. Яндекс Музыка (Yandex Music API)

### Архитектура подключения:
- **Базовый URL**: `https://api.music.yandex.net`
- **Аутентификация**:
  - Заголовок: `Authorization: OAuth {token}`
  - Для анонимных пользователей возможен поиск и превью 30 сек, но для полного прослушивания (HQ 320 kbps) и доступа к плейлистам требуется токен аккаунта Яндекс.
- **Поиск**:
  - Endpoint: `/search?text={query}&type=all&page=0`
  - Результаты содержат `tracks.items`, `artists.items`, `albums.items`.
- **Получение прямого URL аудио (Download Info & MD5 Hash)**:
  1. Запрос информации о загрузке: `GET /tracks/{trackId}/download-info`
  2. Получение списка с `downloadInfoUrl` (варианты: mp3 320kbps, mp3 192kbps, aac).
  3. Запрос XML с параметрами: `GET {downloadInfoUrl}` (возвращает XML с тегами `<host>`, `<path>`, `<ts>`, `<s>`).
  4. Формирование ключа MD5:
     ```
     hash = md5("XGRlBW9FXlekgbPrrGArDq" + path.substring(1) + s)
     ```
  5. Итоговый URL аудиопотока:
     ```
     https://{host}/get-mp3/{hash}/{ts}{path}
     ```

## 4. Единый адаптер (Composite Music Provider)
- Приложение использует `CompositeMusicProvider`, объединяющий результаты поиска из всех трёх источников с возможностью фильтрации (например: "Искать везде", "Только в YouTube", "Только в Яндекс").
- Для треков из других источников (например, импортированных из Spotify) реализуется `AudioSourceResolver`, который по метаданным (название + исполнитель + длительность) находит наилучший аудиопоток на YouTube Music или SoundCloud.
