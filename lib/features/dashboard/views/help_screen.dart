import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';

/// সাহায্য: short answers about how the app counts things, and a way to
/// send feedback by email.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = <(String, String)>[
    (
      'ভুল উত্তরে কি নম্বর কাটা যায়?',
      'হ্যাঁ। প্রতিটি পরীক্ষার নিজস্ব নেগেটিভ মার্কিং থাকে, ভুল উত্তরে সেই হারে নম্বর কাটা যায়। '
          'উত্তর না দিলে কিছু কাটা যায় না। "স্কোর কৌশল" পাতায় দেখো কোন বিষয়ে আন্দাজে উত্তর দিলে লাভ, কোথায় ক্ষতি।',
    ),
    (
      '"সব ভুল" কোথা থেকে আসে?',
      'শেষ হয়ে যাওয়া পরীক্ষায় যে প্রশ্নের শেষ উত্তর ভুল বা ফাঁকা ছিল, সেগুলো। '
          'পরে একবার ঠিক উত্তর দিলে প্রশ্নটা তালিকা থেকে সরে যায়।',
    ),
    (
      '"আজকের রিভিশন" কীভাবে কাজ করে?',
      'ভুল করা প্রশ্ন ১, ৩, ৭, ১৫ ও ৩০ দিনের ব্যবধানে আবার সামনে আসে। '
          'ঠিক উত্তর দিলে পরের ধাপে যায়, ভুল করলে শুরুতে ফেরে। সব ধাপ পার হলে প্রশ্নটা "আয়ত্তে"।',
    ),
    (
      'streak কীভাবে গোনা হয়?',
      'যেসব রুটিন ব্লকে check-in করেছো, তার অন্তত অর্ধেক শেষ করলে সেই দিন গোনা হয়। '
          'একটা দিন বাদ গেলে streak আবার ১ থেকে শুরু হয়।',
    ),
    (
      'কিছু উত্তরের পাশে "পুরোনো হতে পারে" কেন?',
      'পদধারী, রেকর্ড বা সাম্প্রতিক ঘটনার উত্তর সময়ের সাথে বদলায়। প্রশ্ন যে সালের, উত্তরও সেই সময়ের। '
          'পরীক্ষার আগে সাম্প্রতিক তথ্য আলাদা করে মিলিয়ে নিয়ো।',
    ),
    (
      '"আমার লক্ষ্য" ও আজকের পরিকল্পনা',
      'লক্ষ্যের তারিখ দিলে বাকি দিনের হিসাবে পরিকল্পনা সাজে: ৬০ দিনের বেশি থাকলে ভিত্তি, '
          '১৫–৫৯ দিনে রিভিশন, তার কম হলে চূড়ান্ত প্রস্তুতি। তারিখ না দিলে পরের বিসিএসের তারিখ ধরা হয়।',
    ),
  ];

  static const feedbackEmail = 'asifreyad1@gmail.com';

  /// Opens the mail app with the address filled in; if there is none, copies
  /// the address so the learner can paste it anywhere.
  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {'subject': 'Exam Assistant মতামত'},
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (opened || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: feedbackEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('মেইল অ্যাপ পাওয়া যায়নি, ইমেইল ঠিকানা কপি করা হয়েছে'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'সাহায্য'),
      body: DsPage(
        children: [
          DsCard(
            color: AppColors.brandSoft,
            borderWidth: 0,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            onTap: () => _sendFeedback(context),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'মতামত বা সমস্যা জানাও',
                        style: dsText(
                          15,
                          weight: FontWeight.w700,
                          color: AppColors.brandStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feedbackEmail,
                        style: dsText(13, color: AppColors.brandInk2),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.mail_outline,
                  size: 22,
                  color: AppColors.brandStrong,
                ),
              ],
            ),
          ),
          for (final (q, a) in _faq)
            DsCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: dsText(15, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    a,
                    style: dsText(14, color: AppColors.ink2, height: 1.55),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
