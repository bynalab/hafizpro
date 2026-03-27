import 'package:adhkar/adhkar.dart';

class AdhkarService {
  static const String idWakingUp = 'c1';
  static const String idMorningEvening = 'c27';
  static const String idBeforeSleeping = 'c28';
  // Note: 'c26' is duplicated in the package (Guidance & Before Sleeping).
  // We must find "Before sleeping" by title.

  static Adhkar getWakingUp() {
    return AdhkarFactory.getAdhkar(adhkarId: idWakingUp) as Adhkar;
  }

  static Adhkar getMorningEvening() {
    return AdhkarFactory.getAdhkar(adhkarId: idMorningEvening) as Adhkar;
  }

  static Adhkar getBeforeSleeping({required String fallbackTitle}) {
    // Workaround for duplicate ID bug in package
    final all = AdhkarFactory.getAdhkar() as List<Adhkar>;
    try {
      return all
          .firstWhere((a) => a.title.toLowerCase().contains('before sleeping'));
      // return AdhkarFactory.getAdhkar(adhkarId: idBeforeSleeping) as Adhkar;
    } catch (e) {
      return Adhkar(id: 'err', title: fallbackTitle, adhkars: []);
    }
  }
}
