import '../settings/app_settings.dart';

class AppStrings {
  static final Map<String, Map<String, String>> _data = {
    'Русский': {
      // Navigation
      'home': 'Домой',
      'favorites': 'Избранные',
      'tickets': 'Билеты',
      'profile': 'Профиль',
      'settings': 'Настройки',

      // Home
      'now_in_cinema': 'Сейчас в кино',
      'soon': 'Скоро',
      'search': 'Поиск',

      // Errors / states
      'tmdb_load_error': 'Не удалось получить фильмы из TMDb.',
      'movies_not_found_by_filter': 'По текущим фильтрам фильмов не найдено.',
      'nothing_found': 'Ничего не найдено',
      'try_again': 'Попробовать снова',

      // Movie
      'rating': 'Рейтинг',
      'min': 'мин',

      // Favorites
      'favorites_empty': 'У вас пока нет избранных фильмов.',
      'favorites_error': 'Не удалось загрузить избранные фильмы.',

      // Tickets
      'cinema': 'Кинотеатр',
      'session': 'Сеанс',
      'seat': 'Место',
      'ticket_note':
      'Данные билета пока используются как заглушка без БД/API.',

      // Profile
      'profile_settings': 'Настройка профиля',
      'profile_settings_sub': 'Изменить имя, аватар и контактные данные',
      'security': 'Безопасность',
      'security_sub': 'Смена пароля и управление сессиями',
      'payment_methods': 'Способы оплаты',
      'payment_methods_sub': 'Банковские карты и кошельки',
      'support': 'Поддержка',
      'support_sub': 'Чат и FAQ',
      'logout': 'Выйти из аккаунта',
      'logout_sub': 'Завершить текущую сессию',

      // Settings
      'language': 'Язык интерфейса',
      'choose_language': 'Выберите язык',
      'notifications': 'Уведомления',
      'enabled': 'Включены',
      'disabled': 'Отключены',
      'theme': 'Тема',
      'dark': 'Тёмная',
      'light': 'Светлая',
      'about': 'О приложении',
      'authors': 'Авторы проекта',
    },

    'Қазақша': {
      // Navigation
      'home': 'Басты бет',
      'favorites': 'Таңдаулылар',
      'tickets': 'Билеттер',
      'profile': 'Профиль',
      'settings': 'Баптаулар',

      // Home
      'now_in_cinema': 'Қазір кинотеатрда',
      'soon': 'Жақында',
      'search': 'Іздеу',

      // Errors / states
      'tmdb_load_error': 'TMDb-тен фильмдерді алу мүмкін болмады.',
      'movies_not_found_by_filter': 'Қазіргі сүзгілер бойынша фильмдер табылмады.',
      'nothing_found': 'Ештеңе табылмады',
      'try_again': 'Қайта көру',

      // Movie
      'rating': 'Рейтинг',
      'min': 'мин',

      // Favorites
      'favorites_empty': 'Сізде әзірге таңдаулы фильмдер жоқ.',
      'favorites_error': 'Таңдаулы фильмдерді жүктеу мүмкін болмады.',

      // Tickets
      'cinema': 'Кинотеатр',
      'session': 'Сеанс',
      'seat': 'Орын',
      'ticket_note':
      'Билет деректері әзірге БД/API жоқ үлгі ретінде қолданылады.',

      // Profile
      'profile_settings': 'Профильді баптау',
      'profile_settings_sub':
      'Атын, аватарын және байланыс деректерін өзгерту',
      'security': 'Қауіпсіздік',
      'security_sub': 'Құпиясөзді өзгерту және сессияларды басқару',
      'payment_methods': 'Төлем әдістері',
      'payment_methods_sub': 'Банк карталары және әмияндар',
      'support': 'Қолдау',
      'support_sub': 'Чат және FAQ',
      'logout': 'Аккаунттан шығу',
      'logout_sub': 'Ағымдағы сессияны аяқтау',

      // Settings
      'language': 'Интерфейс тілі',
      'choose_language': 'Тілді таңдаңыз',
      'notifications': 'Хабарламалар',
      'enabled': 'Қосулы',
      'disabled': 'Өшірулі',
      'theme': 'Тақырып',
      'dark': 'Қараңғы',
      'light': 'Жарық',
      'about': 'Қосымша туралы',
      'authors': 'Жоба авторлары',
    },

    'English': {
      // Navigation
      'home': 'Home',
      'favorites': 'Favorites',
      'tickets': 'Tickets',
      'profile': 'Profile',
      'settings': 'Settings',

      // Home
      'now_in_cinema': 'Now in Cinema',
      'soon': 'Soon',
      'search': 'Search',

      // Errors / states
      'tmdb_load_error': 'Failed to get movies from TMDb.',
      'movies_not_found_by_filter':
      'No movies found for the current filters.',
      'nothing_found': 'Nothing found',
      'try_again': 'Try again',

      // Movie
      'rating': 'Rating',
      'min': 'min',

      // Favorites
      'favorites_empty': 'You do not have favorite movies yet.',
      'favorites_error': 'Failed to load favorite movies.',

      // Tickets
      'cinema': 'Cinema',
      'session': 'Session',
      'seat': 'Seat',
      'ticket_note':
      'Ticket data is currently used as a placeholder without DB/API.',

      // Profile
      'profile_settings': 'Profile settings',
      'profile_settings_sub':
      'Edit name, avatar and contact data',
      'security': 'Security',
      'security_sub': 'Change password and manage sessions',
      'payment_methods': 'Payment methods',
      'payment_methods_sub': 'Bank cards and wallets',
      'support': 'Support',
      'support_sub': 'Chat and FAQ',
      'logout': 'Log out',
      'logout_sub': 'End current session',

      // Settings
      'language': 'Interface language',
      'choose_language': 'Choose language',
      'notifications': 'Notifications',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'theme': 'Theme',
      'dark': 'Dark',
      'light': 'Light',
      'about': 'About app',
      'authors': 'Project authors',
    },
  };

  static String t(String key) {
    final lang = AppSettings.language.value;
    return _data[lang]?[key] ?? key;
  }
}