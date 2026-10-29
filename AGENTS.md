# Правила и архитектурные стандарты проекта (Music App)

## 1. Архитектурная парадигма (Clean Architecture & Levyra Standards)
Проект строится по принципам чистой архитектуры, модульности и стандартам Levyra-deepsound:
- **`core/`**: Базовые типы, интерфейсы, утилиты, ошибки, сетевой клиент.
- **`sources/` (Провайдеры музыки)**:
  - Каждый источник (`youtube_music`, `soundcloud`, `yandex_music`, `local_files`, `lossless_resolver`) реализует единый интерфейс `MusicProvider`:
    - `search(query, filters) -> Page<Track | Album | Artist | Playlist>`
    - `getTrackInfo(id) -> TrackDetails`
    - `getStreamUrl(trackId, quality) -> AudioStreamInfo`
    - `getVideoStreamUrl(trackId) -> VideoStreamInfo?` (для режима клипов с YouTube Music)
    - `getLyrics(trackId) -> SyncedLyrics?` (караоке-формат с таймингами строк и слов)
    - `getArtist(id) -> ArtistDetails` (дискография: популярные треки, альбомы, синглы, плейлисты, биография)
    - `getAlbum(id) -> AlbumDetails`
    - `getPlaylist(id) -> PlaylistDetails`
    - `getHomeFeed() -> HomeFeed` («Твоя орбита» / Моя волна, «Открытие для вас», «Чарты», «Премьеры», «Тайник», «Плейлист дня»)
    - `getComments(trackId) -> List<Comment>` (комментарии YouTube к треку)
    - `getMotionArtworkUrl(trackId) -> MotionArtworkInfo?` (Canvas / анимированная видео-обложка)
- **`audio/` (Аудиоплеер и DSP пайплайн)**:
  - Состояния: `playing`, `paused`, `buffering`, `idle`, `error`.
  - Локальный HTTP прокси-кэшер (одновременное воспроизведение и кэширование на диск с Range-запросами).
  - **DSP Модуль**:
    - ReplayGain (умная нормализация громкости между разными источниками).
    - Параметрический 5/10-полосный эквалайзер, Bass Boost, Virtualizer.
    - Crossfade и DJ Soft Mode (бесшовный переход между песнями).
    - Изменение скорости (0.5x–2.0x) и тональности (Pitch).
    - **SponsorBlock**: автоматический пропуск интро/аутро/немузыкальных фрагментов.
    - **SkipSilence**: пропуск цифровой тишины в начале и конце файлов.
  - Интеграция с ОС (MPRIS / SMTC / NowPlaying / MediaSession).
  - Бесшовное переключение `[ Песня | Клип ]` с синхронизацией таймкода и pinch-to-zoom жестами видео.
- **`recognition/` (Распознавание музыки)**:
  - Встроенный захват аудио с микрофона (Shazam / AudD протоколы) для мгновенного определения треков вокруг.
- **`downloader/` (Менеджер скачиваний)**:
  - Очередь загрузок с HTTP Range докачкой и многопоточностью.
  - Автоматическое вшивание ID3v2.4 / Vorbis тегов, текстов песен и Hi-Res обложек.
- **`database/` (Локальное хранилище и бэкап)**:
  - SQLite (история, избранное, плейлисты, закэшированные метаданные, локальные треки, «Пульс прослушивания»).
  - Модуль автоматического бэкапа и восстановления медиатеки в 1 клик.
- **`ui/` (Интерфейс)**:
  - **Дизайн-система Levyra**: палитра `#07090D` (фон), `#0B0E14` (поверхность), `#0F131B` (карточки), акценты `#27D9F5` (Levyra Cyan), `#8B7CFF` (Violet), `#50E3B3` (Mint).
  - **Плеер**:
    - Круглые аватарки артистов (`PlayerTopArtistCluster`) с наложением, тенями и бейджем `+N`.
    - Одиночный тап по артисту -> переход на `ArtistProfileScreen`; если авторов несколько -> шторка `PlayerArtistPickerSheet`.
    - Переключатель `[ Песня | Клип ]` (`PlayerModeSwitchIconTab`).
    - Живые Motion-обложки (Canvas / анимированное видео вместо статичной картинки).
    - Синхронные караоке-тексты (`LyricsKaraokeText`) с переходом по тапу на строчку.
    - Шторка комментариев YouTube (`PlayerYoutubeComments`).
  - **Desktop Mini-Player**: компактный плавающий режим «Поверх всех окон» (Picture-in-Picture).
  - **Вкладка «Обзор»**: 4-рядная сетка жанров, сэмплы, тренды, видеоклипы недели.
  - **Вкладка «Медиатека»**: плейлисты (drag-and-drop), треки, локальные файлы с редактором тегов, менеджер загрузок, «Пульс прослушивания».

## 2. Модели данных (Unified Domain Models)
Все источники преобразуют сырые ответы в строгие унифицированные структуры:
```typescript
interface UnifiedArtist {
  id: string;
  name: string;
  thumbnailUrl?: string;
  isVerified?: boolean;
}

interface UnifiedTrack {
  id: string; // e.g. "ytm:abc123xyz", "sc:987654321", "ym:11223344", "local:hash"
  source: 'youtube_music' | 'soundcloud' | 'yandex_music' | 'local';
  sourceId: string;
  title: string;
  artists: UnifiedArtist[];
  album?: { id: string; title: string; coverUrl?: string };
  durationMs: number;
  thumbnailUrl: string;
  highResThumbnailUrl?: string;
  motionArtworkUrl?: string; // Looping canvas video URL
  videoId?: string; // Для переключения в режим видеоклипа
  isExplicit?: boolean;
  hasLyrics?: boolean;
}

interface SponsorBlockSegment {
  category: 'sponsor' | 'intro' | 'outro' | 'interaction' | 'music_offtopic';
  startMs: number;
  endMs: number;
}
```

## 3. Требования к отказоустойчивости и сетевому слою
- Всегда реализовывать механизм Exponential Backoff и Circuit Breaker при получении HTTP 429 (Too Many Requests).
- Для SoundCloud: автоматический парсинг актуального `client_id` из бандлов soundcloud.com при истечении старого.
- Для YouTube Music: поддержка обхода сигнатур (signature deciphering) и выбор наилучшего аудиопотока (Opus 160kbps / AAC 140kbps).
- Для Яндекс.Музыки: поддержка как анонимного поиска, так и работы с авторизационным OAuth-токеном пользователя (доступ к HQ 320kbps, «Моей волне», блоку `/landing3` с «Плейлистом дня», «Премьерами», «Тайником» и «Чартами»).
- Бесшовный fallback на Lossless (FLAC) при наличии трека в каталоге Hi-Res провайдеров.
- Строго разделять логику скачивания и стриминга: потоковое воспроизведение не должно блокироваться медленным интернетом.
