class MatchModel {
  final String id;
  final String categoryId;
  final String championship;
  final String country;
  final DateTime matchTime;
  final String team1;
  final String team2;
  final String optionChosen;
  final double odds;
  final bool isVisible;
  final String result;        // 'won' | 'lost' | 'pending'
  final DateTime? resultDate;
  final DateTime? createdAt;

  MatchModel({
    required this.id,
    required this.categoryId,
    required this.championship,
    required this.country,
    required this.matchTime,
    required this.team1,
    required this.team2,
    required this.optionChosen,
    required this.odds,
    required this.isVisible,
    this.result = 'pending',
    this.resultDate,
    this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id:           json['id'] as String,
      categoryId:   json['category_id'] as String,
      championship: json['championship'] as String,
      country:      json['country'] as String,
      matchTime:    DateTime.parse(json['match_time'] as String).toLocal(),
      team1:        json['team1'] as String,
      team2:        json['team2'] as String,
      optionChosen: json['option_chosen'] as String,
      odds:         (json['odds'] as num).toDouble(),
      isVisible:    json['is_visible'] as bool? ?? true,
      result:       json['result'] as String? ?? 'pending',
      resultDate:   json['result_date'] != null
                      ? DateTime.parse(json['result_date'] as String)
                      : null,
      createdAt:    json['created_at'] != null
                      ? DateTime.parse(json['created_at'] as String)
                      : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':             id,
      'category_id':    categoryId,
      'championship':   championship,
      'country':        country,
      'match_time':     matchTime.toUtc().toIso8601String(),
      'team1':          team1,
      'team2':          team2,
      'option_chosen':  optionChosen,
      'odds':           odds,
      'is_visible':     isVisible,
      'result':         result,
      'result_date':    resultDate?.toIso8601String().split('T').first,
    };
  }

  // Helper
  bool get isWon    => result == 'won';
  bool get isLost   => result == 'lost';
  bool get isPending => result == 'pending';
}