class UserEducationCareer {
  final String? educationLevel;
  final String? educationOtherText;
  final String job;
  final String? careerSector;
  final String? annualIncome;
  final List<String>? jobCategories;
  final bool isJobVerified;
  final String? prefEducation;
  final String? prefCareer;
  final String? prefIncome;
  final String? prefOccupation;

  const UserEducationCareer({
    this.educationLevel,
    this.educationOtherText,
    this.job = '',
    this.careerSector,
    this.annualIncome,
    this.jobCategories,
    this.isJobVerified = false,
    this.prefEducation,
    this.prefCareer,
    this.prefIncome,
    this.prefOccupation,
  });

  factory UserEducationCareer.fromMap(Map<String, dynamic> row) {
    return UserEducationCareer(
      educationLevel: row['education_level']?.toString() ?? row['education']?.toString(),
      educationOtherText: row['education_other_text']?.toString(),
      job: row['job']?.toString() ?? row['occupation']?.toString() ?? '',
      careerSector: row['career_sector']?.toString(),
      annualIncome: row['annual_income']?.toString() ?? row['income']?.toString(),
      jobCategories: (row['job_categories'] is List)
          ? (row['job_categories'] as List).map((e) => e.toString()).toList()
          : null,
      isJobVerified: row['is_job_verified'] == true || row['is_job_verified']?.toString().toLowerCase() == 'true',
      prefEducation: row['pref_education']?.toString(),
      prefCareer: row['pref_career']?.toString(),
      prefIncome: row['pref_income']?.toString(),
      prefOccupation: row['pref_occupation']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'education_level': educationLevel,
      'education_other_text': educationOtherText,
      'job': job,
      'career_sector': careerSector,
      'annual_income': annualIncome,
      'job_categories': jobCategories,
      'is_job_verified': isJobVerified,
      'pref_education': prefEducation,
      'pref_career': prefCareer,
      'pref_income': prefIncome,
      'pref_occupation': prefOccupation,
    };
  }

  UserEducationCareer copyWith({
    String? educationLevel,
    String? educationOtherText,
    String? job,
    String? careerSector,
    String? annualIncome,
    List<String>? jobCategories,
    bool? isJobVerified,
    String? prefEducation,
    String? prefCareer,
    String? prefIncome,
    String? prefOccupation,
  }) {
    return UserEducationCareer(
      educationLevel: educationLevel ?? this.educationLevel,
      educationOtherText: educationOtherText ?? this.educationOtherText,
      job: job ?? this.job,
      careerSector: careerSector ?? this.careerSector,
      annualIncome: annualIncome ?? this.annualIncome,
      jobCategories: jobCategories ?? this.jobCategories,
      isJobVerified: isJobVerified ?? this.isJobVerified,
      prefEducation: prefEducation ?? this.prefEducation,
      prefCareer: prefCareer ?? this.prefCareer,
      prefIncome: prefIncome ?? this.prefIncome,
      prefOccupation: prefOccupation ?? this.prefOccupation,
    );
  }
}
