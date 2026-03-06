import '../models/monthly_report_model.dart';

const Map<String, String> genreLabels = {
  'cafe_sweets': 'カフェ・スイーツ',
  'washoku': '和食',
  'izakaya_bar': '居酒屋・バー',
  'yakitori_age': '焼き鳥・揚げ物',
  'nabe_yakiniku': '鍋・焼肉',
  'ramen_chinese': 'ラーメン・中華',
  'asian_ethnic': 'アジア・エスニック',
  'western_french': '洋食・フレンチ',
  'italian_meat': 'イタリアン・肉料理',
  'shokudo_other': '食堂・その他',
};

const Map<String, String> genreHashtags = {
  'cafe_sweets': 'カフェ巡り',
  'washoku': '和食巡り',
  'izakaya_bar': '居酒屋巡り',
  'yakitori_age': '焼き鳥',
  'nabe_yakiniku': '焼肉',
  'ramen_chinese': 'ラーメン',
  'asian_ethnic': 'エスニック料理',
  'western_french': '洋食',
  'italian_meat': 'イタリアン',
  'shokudo_other': '食堂',
};

class ShareTextGenerator {
  static String generateMonthlyReport(MonthlyReportModel report) {
    final year = report.yearMonth.substring(0, 4);
    final month = report.yearMonth.substring(5, 7);
    final yearMonth = '$year年${month}月';
    final topGenreLabel = genreLabels[report.topGenre] ?? '色々なジャンル';
    final topGenreHashtag = genreHashtags[report.topGenre] ?? 'グルメ';

    final legendLine = report.legendDiscoveredCount > 0
        ? '\n✨ レジェンド発見: ${report.legendDiscoveredCount}店舗！'
        : '';
    final areeLine = report.visitedAreas.isNotEmpty
        ? '\n🗾 探検エリア: ${report.visitedAreas.join('・')}'
        : '';

    return '''$yearMonthのぐるまっぷ探検レポート🗺️

📍 今月の発見: ${report.monthlyDiscoveredCount}店舗
🏆 累計発見: ${report.totalDiscoveredCount}店舗
🍽️ 今月のお気に入りジャンル: $topGenreLabel$legendLine$areeLine

みんなと一緒に街を探検中！
#ぐるまっぷ #街歩き #$topGenreHashtag''';
  }
}
