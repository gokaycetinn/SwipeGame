import '../domain/quiz_card.dart';

const gameRules = [
  'Sampiyonlar Ligi kazandi',
  'Manchester City formasini giydi',
  'Forvet pozisyonunda oynadi',
  "Serie A'da oynadi",
];

const sampleCards = [
  QuizCard(
    id: 'haaland',
    name: 'Erling Haaland',
    subtitle: 'FORVET • MAN CITY',
    imageUrl:
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': true,
      'Manchester City formasini giydi': true,
      'Forvet pozisyonunda oynadi': true,
      "Serie A'da oynadi": false,
    },
  ),
  QuizCard(
    id: 'lewandowski',
    name: 'Robert Lewandowski',
    subtitle: 'FORVET • BARCELONA',
    imageUrl:
        'https://images.unsplash.com/photo-1511886929837-354d827aae26?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': true,
      'Manchester City formasini giydi': false,
      'Forvet pozisyonunda oynadi': true,
      "Serie A'da oynadi": false,
    },
  ),
  QuizCard(
    id: 'debruyne',
    name: 'Kevin De Bruyne',
    subtitle: 'ORTA SAHA • MAN CITY',
    imageUrl:
        'https://images.unsplash.com/photo-1556056504-5c7696c4c28d?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': true,
      'Manchester City formasini giydi': true,
      'Forvet pozisyonunda oynadi': false,
      "Serie A'da oynadi": false,
    },
  ),
  QuizCard(
    id: 'osimhen',
    name: 'Victor Osimhen',
    subtitle: 'FORVET • NAPOLI',
    imageUrl:
        'https://images.unsplash.com/photo-1487466365202-1afdb86c764e?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': false,
      'Manchester City formasini giydi': false,
      'Forvet pozisyonunda oynadi': true,
      "Serie A'da oynadi": true,
    },
  ),
  QuizCard(
    id: 'modric',
    name: 'Luka Modric',
    subtitle: 'ORTA SAHA • REAL MADRID',
    imageUrl:
        'https://images.unsplash.com/photo-1471295253337-3ceaaedca402?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': true,
      'Manchester City formasini giydi': false,
      'Forvet pozisyonunda oynadi': false,
      "Serie A'da oynadi": false,
    },
  ),
  QuizCard(
    id: 'lautaro',
    name: 'Lautaro Martinez',
    subtitle: 'FORVET • INTER',
    imageUrl:
        'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?auto=format&fit=crop&w=900&q=80',
    rules: {
      'Sampiyonlar Ligi kazandi': false,
      'Manchester City formasini giydi': false,
      'Forvet pozisyonunda oynadi': true,
      "Serie A'da oynadi": true,
    },
  ),
];
