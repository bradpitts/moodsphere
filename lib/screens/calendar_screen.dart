final Map<String, double> aggregatedMoods = {};

    for (var e in monthEntries) {
      final percentages = e.moodPercentages ?? {};
      percentages.forEach((name, val) {
        aggregatedMoods[name] = (aggregatedMoods[name] ?? 0) + val;
      });
    }
