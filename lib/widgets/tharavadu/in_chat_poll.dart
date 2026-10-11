import 'package:flutter/material.dart';

class InChatPollWidget extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isClanMember;
  final Function(int optionIndex) onVote;

  const InChatPollWidget({
    super.key,
    required this.msg,
    required this.isClanMember,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final question = (msg['poll_question'] ?? msg['text'] ?? 'വോട്ടെടുപ്പ്')
        .toString();
    final options =
        (msg['poll_options'] as List<dynamic>?) ??
        [
          {'text': 'അതെ (Yes)', 'votes': 0},
          {'text': 'അല്ല (No)', 'votes': 0},
        ];
    final userVotedOptionIndex = msg['user_voted_index'] as int?;

    int totalVotes = 0;
    for (final opt in options) {
      if (opt is Map) {
        totalVotes += (opt['votes'] as int? ?? 0);
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll, color: Color(0xFF000080), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF5C3E00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(options.length, (idx) {
            final opt = options[idx] as Map<String, dynamic>;
            final optText = opt['text'] as String? ?? '';
            final votes = opt['votes'] as int? ?? 0;
            final double percent = totalVotes > 0 ? (votes / totalVotes) : 0.0;
            final bool isSelected = userVotedOptionIndex == idx;

            return InkWell(
              onTap: isClanMember ? () => onVote(idx) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF000080)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            optText,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(0)}% ($votes)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected
                              ? const Color(0xFF000080)
                              : Colors.blue.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Text(
            'ആകെ വോട്ടുകൾ: $totalVotes',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
