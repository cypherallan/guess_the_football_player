class Footballer {
  final String name;
  final String difficulty; // beginner, easy, normal, hard, expert
  final List<String> hints;
  final List<String> keywords; // For parsing the AI's guesses cleanly

  Footballer({
    required this.name,
    required this.difficulty,
    required this.hints,
    required this.keywords,
  });
}

class FootballDatabase {
  static final List<Footballer> registry = [
    // --- BEGINNER / EASY (Global Superstars / Highly recognizable) ---
    Footballer(
      name: "Lionel Messi",
      difficulty: "Beginner",
      hints: [
        "Won the 2022 World Cup with Argentina.",
        "Spent the majority of his senior club career at FC Barcelona.",
        "Has won 8 Ballon d'Or awards as of recent years.",
      ],
      keywords: ["messi", "lionel messi", "leo messi"],
    ),
    Footballer(
      name: "Lamine Yamal",
      difficulty: "Easy",
      hints: [
        "Broke records as the youngest scorer in Euro history during Euro 2024.",
        "Wears the number 19 jersey for FC Barcelona.",
        "Known for his spectacular left-footed curling shots from the right wing.",
      ],
      keywords: ["lamine", "yamal", "lamine yamal"],
    ),

    // --- NORMAL / HARD (Excellent players, but requires active football tracking) ---
    Footballer(
      name: "Cole Palmer",
      difficulty: "Normal",
      hints: [
        "Nicknamed 'Cold' for his icy penalty celebrations.",
        "Transferred from Manchester City to Chelsea and became their top scorer.",
        "Scored for England in the Euro 2024 final match.",
      ],
      keywords: ["palmer", "cole palmer", "cold palmer"],
    ),
    Footballer(
      name: "Viktor Gyökeres",
      difficulty: "Hard",
      hints: [
        "Swedish striker known for his iconic interlaced-finger mask celebration.",
        "Had an explosive, high-scoring run for Sporting CP in Portugal.",
        "Played for Coventry City before moving to prime European leagues.",
      ],
      keywords: ["gyokeres", "viktor gyokeres", "gyökeres"],
    ),

    // --- EXPERT (Obscure legends or highly specific deep-squad historical profiles) ---
    Footballer(
      name: "Just Fontaine",
      difficulty: "Expert",
      hints: [
        "Holds the ultimate record for the most goals scored in a single World Cup tournament (13 goals).",
        "Legendary French forward from the 1950s era.",
        "Played club football for Stade de Reims and Nice.",
      ],
      keywords: ["fontaine", "just fontaine"],
    ),
    Footballer(
      name: "Kazuyoshi Miura",
      difficulty: "Expert",
      hints: [
        "Known globally as 'King Kazu'.",
        "Recognized as the oldest active professional footballer in the world, playing well into his late 50s.",
        "The first Japanese player to play in the Italian Serie A (for Genoa).",
      ],
      keywords: ["miura", "kazu", "kazuyoshi miura", "king kazu"],
    ),
  ];

  /// Grabs a random player based exactly on the chosen UI tier profile
  static Footballer getRandomPlayerByTier(String tier) {
    final filtered = registry
        .where((p) => p.difficulty.toLowerCase() == tier.toLowerCase())
        .toList();
    if (filtered.isEmpty) {
      return registry.first; // Fallback security guard
    }
    return (filtered..shuffle()).first;
  }
}
