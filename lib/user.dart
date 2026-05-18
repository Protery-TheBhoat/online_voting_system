class User {
  final String stuID;
  final String password;
  bool hasVoted;
  bool isFingerprintEnabled;

  User({
    required this.stuID,
    required this.password,
    this.hasVoted = false,
    this.isFingerprintEnabled = false,
  });
}
