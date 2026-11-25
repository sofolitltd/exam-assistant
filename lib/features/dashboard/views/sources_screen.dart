import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';

/// তথ্যের উৎস ও দাবিত্যাগ: states that the app is not a government entity
/// and links the official sites behind its exam information. Google Play's
/// Misleading Claims policy requires both for apps that show government
/// information; keep this list in sync with the store description
/// (`play_store/store-listing.md`).
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const sources = <(String, String)>[
    ('বাংলাদেশ সরকারি কর্ম কমিশন (বিসিএস)', 'https://bpsc.gov.bd'),
    (
      'বেসরকারি শিক্ষক নিবন্ধন ও প্রত্যয়ন কর্তৃপক্ষ (এনটিআরসিএ)',
      'https://ntrca.gov.bd',
    ),
    (
      'প্রাথমিক শিক্ষা অধিদপ্তর (প্রাইমারি শিক্ষক নিয়োগ)',
      'https://dpe.gov.bd',
    ),
    ('বাংলাদেশ ব্যাংক', 'https://www.bb.org.bd'),
    ('ব্যাংকার্স সিলেকশন কমিটি নিয়োগ', 'https://erecruitment.bb.org.bd'),
    ('সরকারি চাকরির আবেদন (টেলিটক)', 'https://alljobs.teletalk.com.bd'),
    ('বাংলাদেশ জাতীয় তথ্য বাতায়ন', 'https://bangladesh.gov.bd'),
  ];

  Future<void> _open(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (opened || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('লিংক খোলা যায়নি, কপি করা হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = dsText(14, color: AppColors.ink2, height: 1.55);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'তথ্যের উৎস ও দাবিত্যাগ'),
      body: DsPage(
        children: [
          DsCard(
            color: AppColors.brandSoft,
            borderWidth: 0,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'দাবিত্যাগ',
                  style: dsText(
                    15,
                    weight: FontWeight.w700,
                    color: AppColors.brandStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Exam Assistant Sofol IT-এর তৈরি একটি বেসরকারি অ্যাপ। এটি কোনো সরকারি '
                  'প্রতিষ্ঠানের প্রতিনিধিত্ব করে না এবং বাংলাদেশ সরকারি কর্ম কমিশন (BPSC), '
                  'এনটিআরসিএ, প্রাথমিক শিক্ষা অধিদপ্তর, বাংলাদেশ ব্যাংক বা অন্য কোনো সরকারি '
                  'সংস্থার সাথে যুক্ত বা তাদের অনুমোদিত নয়। অ্যাপ থেকে কোনো সরকারি সেবা বা '
                  'চাকরির আবেদন করা যায় না।',
                  style: body,
                ),
              ],
            ),
          ),
          DsCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('তথ্যের উৎস', style: dsText(15, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'বিগত প্রশ্ন, সিলেবাস, মানবণ্টন ও পরীক্ষার তারিখ নিচের অফিসিয়াল সূত্রে প্রকাশিত '
                  'প্রশ্নপত্র ও বিজ্ঞপ্তি থেকে নেওয়া। আবেদন, প্রবেশপত্র, '
                  'ফল বা যেকোনো চূড়ান্ত তথ্যের জন্য সবসময় অফিসিয়াল ওয়েবসাইট দেখো।',
                  style: body,
                ),
              ],
            ),
          ),
          DsListCard(
            radius: 16,
            children: [
              for (final (name, url) in sources)
                InkWell(
                  onTap: () => _open(context, url),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: dsText(14, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                url.replaceFirst('https://', ''),
                                style: dsText(13, color: AppColors.brandInk2),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Color(0xFF8A919C),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
