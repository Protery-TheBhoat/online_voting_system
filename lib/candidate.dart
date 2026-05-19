class Candidate {
  final String id;
  final String name;
  final String category;
  final String program;
  final String level;
  final String academicYear;
  final String? imagePath;
  int votes;

  Candidate({
    required this.id,
    required this.name,
    required this.category,
    required this.program,
    required this.level,
    required this.academicYear,
    this.imagePath,
    this.votes = 0,
  });
}
