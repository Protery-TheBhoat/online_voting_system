class Candidate {
  final String id;
  final String name;
  final String category;
  int votes;

  Candidate({
    required this.id,
    required this.name,
    required this.category,
    this.votes = 0,
  });
}
