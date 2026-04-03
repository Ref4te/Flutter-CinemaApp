# booking_app

Бронирование мест в кинотеатре.

## TMDb API

Теперь список фильмов и детали фильма загружаются из **The Movie Database (TMDb)**.

Запускайте приложение с ключом API через `--dart-define`:

```bash
flutter run --dart-define=TMDB_API_KEY=YOUR_TMDB_KEY
```

Если ключ не передан, на главном экране будет показана ошибка загрузки.
