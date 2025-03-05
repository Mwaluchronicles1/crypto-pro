class Validators {
  static String? validateHash(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter document hash';
    }
    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter document title';
    }
    return null;
  }
}