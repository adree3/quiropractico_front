class Country {
  final String name;
  final String flag;
  final String dialCode;

  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

class CountryData {
  static const List<Country> countries = [
    Country(name: 'España', flag: '🇪🇸', dialCode: '+34'),
    Country(name: 'México', flag: '🇲🇽', dialCode: '+52'),
    Country(name: 'Estados Unidos', flag: '🇺🇸', dialCode: '+1'),
    Country(name: 'Argentina', flag: '🇦🇷', dialCode: '+54'),
    Country(name: 'Colombia', flag: '🇨🇴', dialCode: '+57'),
    Country(name: 'Chile', flag: '🇨🇱', dialCode: '+56'),
    Country(name: 'Perú', flag: '🇵🇪', dialCode: '+51'),
    Country(name: 'Venezuela', flag: '🇻🇪', dialCode: '+58'),
    Country(name: 'Ecuador', flag: '🇪🇨', dialCode: '+593'),
    Country(name: 'Guatemala', flag: '🇬🇹', dialCode: '+502'),
    Country(name: 'Cuba', flag: '🇨🇺', dialCode: '+53'),
    Country(name: 'Bolivia', flag: '🇧🇴', dialCode: '+591'),
    Country(name: 'República Dominicana', flag: '🇩🇴', dialCode: '+1809'),
    Country(name: 'Honduras', flag: '🇭🇳', dialCode: '+504'),
    Country(name: 'Paraguay', flag: '🇵🇾', dialCode: '+595'),
    Country(name: 'El Salvador', flag: '🇸🇻', dialCode: '+503'),
    Country(name: 'Nicaragua', flag: '🇳🇮', dialCode: '+505'),
    Country(name: 'Costa Rica', flag: '🇨🇷', dialCode: '+506'),
    Country(name: 'Puerto Rico', flag: '🇵🇷', dialCode: '+1787'),
    Country(name: 'Panamá', flag: '🇵🇦', dialCode: '+507'),
    Country(name: 'Uruguay', flag: '🇺🇾', dialCode: '+598'),
    Country(name: 'Brasil', flag: '🇧🇷', dialCode: '+55'),
    Country(name: 'Portugal', flag: '🇵🇹', dialCode: '+351'),
    Country(name: 'Reino Unido', flag: '🇬🇧', dialCode: '+44'),
    Country(name: 'Francia', flag: '🇫🇷', dialCode: '+33'),
    Country(name: 'Alemania', flag: '🇩🇪', dialCode: '+49'),
    Country(name: 'Italia', flag: '🇮🇹', dialCode: '+39'),
  ];
}
