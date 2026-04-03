# booking_app

Бронирование мест в кинотеатре.

## TMDb интеграция

Главная страница загружает популярные фильмы из The Movie Database API.

### Как запустить

1. Получите API-ключ на [TMDb](https://www.themoviedb.org/settings/api).
2. Запустите приложение с `dart-define`:

```bash
flutter run --dart-define=TMDB_API_KEY=ваш_ключ
```

Без ключа приложение покажет сообщение об ошибке и кнопку повторной загрузки.
