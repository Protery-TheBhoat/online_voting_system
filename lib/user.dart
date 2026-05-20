class User {
  final String stuID;
  String password;
  bool hasVoted;
  bool isFingerprintEnabled;
  bool isFaceEnabled;

  User({
    required this.stuID,
    required this.password,
    this.hasVoted = false,
    this.isFingerprintEnabled = false,
    this.isFaceEnabled = false,
  });
}
