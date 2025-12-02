extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

extension StringLowerExtension on String {
  String lowerCase() {
    if (isEmpty) return this;
    return this[0].toLowerCase() + substring(1);
  }
}

extension StringPluralExtension on String {
  String pluralize() {
    if (isEmpty) return this;
    return this + "s";
  }
}