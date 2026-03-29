import '../domain/quiz_card.dart';

const gameRules = [
  'Won the Champions League',
  'Played for Manchester City',
  'Forward Position',
  'Played in Serie A',
];

const sampleCards = [
  QuizCard(
    id: 'haaland',
    name: 'Erling Haaland',
    subtitle: 'FORWARD • MAN CITY',
    imageUrl:
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': true,
      'Played for Manchester City': true,
      'Forward Position': true,
      'Played in Serie A': false,
    },
  ),
  QuizCard(
    id: 'lewandowski',
    name: 'Robert Lewandowski',
    subtitle: 'FORWARD • BARCELONA',
    imageUrl:
        'https://images.unsplash.com/photo-1511886929837-354d827aae26?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': true,
      'Played for Manchester City': false,
      'Forward Position': true,
      'Played in Serie A': false,
    },
  ),
  QuizCard(
    id: 'debruyne',
    name: 'Kevin De Bruyne',
    subtitle: 'MIDFIELDER • MAN CITY',
    imageUrl:
        'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': true,
      'Played for Manchester City': true,
      'Forward Position': false,
      'Played in Serie A': false,
    },
  ),
  QuizCard(
    id: 'osimhen',
    name: 'Victor Osimhen',
    subtitle: 'FORWARD • NAPOLI',
    imageUrl:
        'https://images.unsplash.com/photo-1487466365202-1afdb86c764e?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': false,
      'Played for Manchester City': false,
      'Forward Position': true,
      'Played in Serie A': true,
    },
  ),
  QuizCard(
    id: 'modric',
    name: 'Luka Modric',
    subtitle: 'MIDFIELDER • REAL MADRID',
    imageUrl:
        'https://images.unsplash.com/photo-1471295253337-3ceaaedca402?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': true,
      'Played for Manchester City': false,
      'Forward Position': false,
      'Played in Serie A': false,
    },
  ),
  QuizCard(
    id: 'lautaro',
    name: 'Lautaro Martinez',
    subtitle: 'FORWARD • INTER',
    imageUrl:
        'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Won the Champions League': false,
      'Played for Manchester City': false,
      'Forward Position': true,
      'Played in Serie A': true,
    },
  ),
];
