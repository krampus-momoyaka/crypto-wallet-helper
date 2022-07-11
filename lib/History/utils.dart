import '../User.dart';

class Utils {
  static int ascendingSort(User c1, User c2) =>
      c1.name.compareTo(c2.name);
}
