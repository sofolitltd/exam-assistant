# ২৪ কলামের হেডার আজই স্থির করুন

**মূল সিদ্ধান্ত:** BCS প্রিলিমিনারি প্রশ্নব্যাংকের Excel হেডারে **মোট ২৪টি কলাম** থাকবে। এর মধ্যে বর্তমান ১২টি কলাম হুবহু থাকবে, নতুন যোগ হবে ১২টি। সব ফাইলে **৭টি কলাম বাধ্যতামূলক**, আর বিগত-বছরের (PYQ) ফাইলে আরও **২টি** (`examCode`, `questionNo`)। ডাটাবেসে প্রশ্ন-সংক্রান্ত মোট **৭৩টি ফিল্ড থাকবে ৭টি টেবিলে**। এর মধ্যে Excel থেকে আসে ২০টি ফিল্ড। বাকিগুলো সিস্টেম নিজে লেখে বা হিসাব করে: পরিসংখ্যান, কতবার এসেছে, অ্যাটেম্পট থেকে কঠিনতা, বুকমার্ক বা ভুলের তালিকা। বাংলাদেশি অ্যাপ, ভারতীয় প্ল্যাটফর্ম আর QTI/Moodle—তিন দিকের তুলনায় একই কাঠামো বারবার পাওয়া গেছে। প্রতিটি প্রশ্নের একটি স্থায়ী ID থাকে। প্রশ্নটি কোন পরীক্ষার কত নম্বর প্রশ্ন ছিল, তা আলাদা many-to-many লিংকে রাখা হয়। টপিকের জন্য থাকে একটি প্রধান কোড-ভিত্তিক শ্রেণিবিন্যাস। উত্তর নিয়ে বিতর্ক থাকলে তা চিহ্নিত করা হয়। আর কঠিনতা আসে মূলত ব্যবহারকারীর ডেটা থেকে, এডিটরের লেবেল থেকে নয়। এই নকশা থেকে Live MCQ, BCS Prostuti, Satt Academy-র প্রায় সব ফিল্টার পাওয়া যায়, সঙ্গে "৩৫, ৩৮, ৪৪তম BCS-এ এসেছে" ধরনের পুনরাবৃত্তি-বিশ্লেষণও। প্রতিযোগীরা এটি আলাদা ফিচার হিসেবে প্রকাশ্যে দেখায় না। মাইগ্রেশন কম রাখার মূল নীতি একটাই: `questions` টেবিলের কলাম আর Excel হেডার এখনই স্থির করা। ভবিষ্যতের চাহিদা মেটানো হবে নতুন টেবিল যোগ করে বা `extra` JSONB-তে রেখে, পুরোনো কলাম বদলে নয়।

## প্রতিযোগীরা প্রশ্নকে তিনটি অক্ষে সাজায়: পরীক্ষা, টপিক, উত্তরের নির্ভরযোগ্যতা

বাংলাদেশের বাজারে Live MCQ শীর্ষে আছে (১M+ ইনস্টল, দাবি ২৪ লাখ+ ব্যবহারকারী) ([Google Play: Live MCQ](https://play.google.com/store/apps/details?id=com.livemcq.livemcq))। এর পরে আছে BCS Prostuti (৫০০K+), Medha, GuruKlub এবং আরও কয়েকটি ১০০K+ অ্যাপ। প্রায় সবার মেটাডেটা প্রায় একই। প্রথম অক্ষ হলো **পরীক্ষার পরিচয়**। Satt Academy প্রতিটি পেপারের সঙ্গে পরীক্ষার নম্বর, ধরন, তারিখ আর MCQ সংখ্যা দেখায় ("50th BCS Preliminary — 2026-01-30 — MCQ 200")। নামধারী সেট ("চন্দ্রমল্লিকা", "কীর্তনখোলা"), English version এবং বিশেষ BCS (Health, Education) আলাদা এন্ট্রি হিসেবে থাকে ([Satt Academy BCS Preliminary](https://www.sattacademy.com/job-solution/bcs-preliminary/))। দ্বিতীয় অক্ষ হলো **বিষয় → অধ্যায় → টপিক**। BCS Prostuti প্রশ্ন সাজায় "category, subcategory, and chapter" ধরে এবং কাস্টম টেস্টও বানায় এই তিন স্তর থেকে ([Google Play: BCS Prostuti](https://play.google.com/store/apps/details?id=com.bcsprostuti.tanim.bcsprostuti))। Medha-র দাবি ৩০টি ক্যাটাগরিতে ১,৫০০+ টপিক ([Google Play: Medha](https://play.google.com/store/apps/details?id=com.einstechstudio.medha))। তৃতীয় অক্ষ হলো **উত্তরের নির্ভরযোগ্যতা**। এখানে বাজারের পার্থক্যটা চোখে পড়ে। Live MCQ-র "তথ্যকল্পদ্রুম" বিতর্কিত প্রশ্নের সঠিক উত্তর, যুক্তি আর সূত্র দেয়, আর "সম্প্রতি পরিবর্তিত সকল তথ্য" বাটনে পুরোনো হয়ে যাওয়া তথ্য দেখায় ([Live MCQ BCS](https://web.livemcq.com/bcs))। "BCS Question Bank: Explained" বিতর্কিত উত্তর চিহ্নিত করে, সংশোধিত প্রশ্ন তারিখসহ তালিকায় রাখে, আর বাতিল প্রশ্ন বাদ দিয়ে পেপার দেখায় (যেমন ৫০তম-এ ১৯০টি) ([Google Play: Explained](https://play.google.com/store/apps/details?id=com.contextser.bcs))। এর মানে, **`answerStatus` আর `answerNote` বাজারে প্রতিযোগিতার একটি বাস্তব মাপকাঠি, অতিরিক্ত বিলাসিতা নয়**।

ভারতীয় প্ল্যাটফর্মেও একই কাঠামো দেখা যায়। Examside-এর প্রতিটি প্রশ্নে থাকে পরীক্ষা, তারিখ, শিফট, সেকশন, টপিক, মার্কিং (+2 −0.5), ধরন ("MCQ (Single Correct Answer)"), উত্তর আর ব্যাখ্যা। কোনো difficulty বা ট্যাগ দেখানো হয় না ([Examside](https://questions.examside.com/past-years/ssc/question/who-among-the-following-served-the-shortest-tenure-as-the-pr-ssc-cgl-tier-i-general-awareness-uyaajihprntvvrec))। UPSC বিশ্লেষক Anantam IAS ১,৪০৩টি প্রশ্নের প্রতিটিতে **ঠিক একটি বিষয় আর একটি টপিক** ট্যাগ করে। সাবটপিক রাখে না ([Anantam IAS](https://anantamias.com/upsc-prelims-pyq-topic-wise/))। বিপরীত প্রান্তে আছে Embibe: ৭৪,০০০+ কনসেপ্ট নোড, Bloom লেভেল আর ideal time। এই গভীরতা বজায় রাখতে তাদের মেশিন-সহায়ক ট্যাগিং লাগে ([Embibe MetaTags Ranker](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education-articles/meta-tags-ranker/))। এক ব্যক্তির পরিচালিত BCS ব্যাংকের জন্য উপসংহারটা পরিষ্কার: **তিন স্তরের ট্যাক্সোনমি (subject/topic/subtopic) যথেষ্ট, আর প্রতিটি প্রশ্নের একটিমাত্র প্রধান টপিক থাকবে**। তা না হলে ট্রেন্ড-গণনায় একই প্রশ্ন দুবার গোনা হবে। একই UPSC পেপার নিয়ে ভিন্ন ভিন্ন ট্যাগিং স্কিম ভিন্ন সংখ্যা দেয়, যেমন Vajiram আর Anantam-এর হিসাব মেলে না ([Vajiram](https://vajiramandravi.com/upsc-exam/topic-wise-upsc-prelims-questions/))। তাই টপিক-কোড একবার স্থির করে আর বদলানো উচিত নয়।

## স্ট্যান্ডার্ডগুলো দুটি নিয়ম শেখায়: স্থায়ী ID আর এডিটরের difficulty-কে চূড়ান্ত না ধরা

QTI 3.0-তে প্রতিটি আইটেমের একটি স্থায়ী `identifier` থাকে, যা মানুষের পড়ার মতো `title`/`label` থেকে আলাদা। প্রতিটি অপশনেরও নিজস্ব identifier থাকে, তাই সঠিক উত্তর নির্দেশ করা হয় অপশন-ID দিয়ে, অবস্থান দিয়ে নয় ([QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl))। আপনার `options` JSONB `[{key,value}]` আর `correctOptionKeys` ইতিমধ্যে এই নিয়ম মেনে চলে। QTI-র LOM প্রোফাইলে শ্রেণিবিন্যাস থাকে `taxonPath`-এ, স্কিমের নামসহ। লক্ষ করার মতো বিষয় হলো, **এডিটরিয়াল `Difficulty` ফিল্ডকে সেখানে "not recommended" বলা হয়েছে** ([QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind))। ভারতীয় প্ল্যাটফর্মগুলোও একই পথে গেছে। Unacademy কঠিনতা হিসাব করে ভুল/সঠিকের অনুপাত আর মিডিয়ান সময় থেকে ([Unacademy tech](https://tech.unacademy.com/question-difficulty-estimation/))। Embibe অ্যাটেম্পট-ডেটা থেকে 2PL IRT প্যারামিটার বের করে ([Embibe](https://embibe.com/in-en/artificial-intelligence-ai-in-education/question-discrimination-factor))। তাই Excel-এর `difficulty` শুধু একটি **প্রাথমিক অনুমান**। পর্যাপ্ত অ্যাটেম্পট জমলে `question_stats.computed_difficulty` সেটিকে প্রতিস্থাপন করবে। সাইকোমেট্রিক্সে কঠিনতা মানে p-value, অর্থাৎ যত অংশ সঠিক উত্তর দিয়েছে। UT Austin-এর মাপকাঠিতে p > 0.90 খুব সহজ আর p < 0.20 খুব কঠিন ([UT Austin](https://testingservices.utexas.edu/interpreting-test-results))।

Moodle শেখায় স্ট্যাটাস আর পরিসংখ্যান কীভাবে রাখতে হয়। প্রশ্নব্যাংকের কলামে থাকে Version, Status (ready/draft), Usage, Last used, Facility index, Discriminative efficiency আর "Needs checking"। শুধু Ready প্রশ্নই কুইজে যোগ করা যায় ([MoodleDocs 5.0](https://docs.moodle.org/500/en/Question_banks))। TAO-তে retire করা আইটেম মুছে ফেলা হয় না, যাতে ইতিহাস ঠিক থাকে ([TAO](https://userguide.taotesting.com/user-documentation/latest/public/item-status))। এ থেকে আপনার জন্য দুটি সিদ্ধান্ত আসে। প্রথমত, `status` (draft/ready/retired) সিস্টেম-ফিল্ড হিসেবে রাখুন, Excel-এ নয়। দ্বিতীয়ত, পরিসংখ্যান রাখুন আলাদা `question_stats` টেবিলে, যা ব্যাচে আবার হিসাব করা হবে। ডিস্ট্র্যাক্টর বিশ্লেষণের জন্য প্রতিটি অপশন কতবার বাছাই হয়েছে তা রাখা দরকার। কোনো ভুল অপশন সঠিক উত্তরের চেয়ে বেশি বাছাই হলে সেটি সম্ভাব্য ভুল উত্তর-কীর সংকেত ([HKU item analysis](https://bimhse.med.hku.hk/wp-content/uploads/2026/05/Item_Analysis_Workshop_PDF_BIMHSE.pdf))। BCS গাইডগুলোর মধ্যে উত্তর নিয়ে মতভেদ সাধারণ ঘটনা, তাই এই সংকেত `answerStatus = disputed` প্রশ্ন খুঁজে পেতে সরাসরি কাজে লাগবে। একটি সতর্কতা আছে: Moodle-এর পরিসংখ্যান একবারের সামেটিভ টেস্টের জন্য তৈরি ([MoodleDocs dev](https://docs.moodle.org/dev/Quiz_report_statistics))। ফ্রি প্র্যাকটিসের ডেটা স্বেচ্ছা-নির্বাচিত, তাই discrimination হিসাব করুন শুধু পূর্ণ মডেল টেস্ট থেকে।

## পুনরাবৃত্তি আসলে একটি লিংক, ফিল্ড নয়

কোনো প্রতিযোগী প্রশ্নপ্রতি "N বার এসেছে" ফিল্ড প্রকাশ্যে দেখায় না। ভারতীয় গবেষণাতেও প্রশ্নপ্রতি "asked in" তালিকা পাওয়া যায়নি। Preceptors ডাইজেস্ট "১০ম থেকে ৫০তম বিসিএস প্রিলিমিনারি পর্যন্ত সকল প্রশ্ন টপিকভিত্তিকভাবে" সাজায় ([Preceptors](https://preceptors.com.bd/product/bcs-digest/))। com.bcsquestionbank "কোন অধ্যায় থেকে বেশি প্রশ্ন এসেছে" ধরনের ট্রেন্ড বিশ্লেষণ দেয় ([Google Play: com.bcsquestionbank](https://play.google.com/store/apps/details?id=com.bcsquestionbank))। দুটোই চলে একই ডেটা থেকে: (প্রশ্ন, টপিক, উৎস-পরীক্ষা)। তাই "এসেছে ৩৫, ৩৮, ৪৪তম BCS-এ" কোনো Excel কলাম নয়। এটি `exam_questions`-এ একটি `questions.id`-এর তিনটি সারি থেকে আসে। পেটেন্ট-সাহিত্যে এমন প্রায় একই আইটেমকে "enemy items" বলা হয়, আর সেগুলো শনাক্ত হয় cosine similarity ও মানুষের যাচাই দিয়ে। সব জোড়া মিলিয়ে দেখা দ্রুত অসম্ভব হয়ে যায়: ১,০০০ আইটেমে ৪৯৯,৫০০ জোড়া ([US10741093](https://patents.google.com/patent/US10741093))। তাই পদ্ধতিটা হবে তিন ধাপের। প্রথমে স্বাভাবিকীকৃত টেক্সটের `text_hash` দিয়ে হুবহু মিল ধরা। তারপর Postgres `pg_trgm` দিয়ে প্রায়-মিল খোঁজা, কারণ MinHash/trigram এখনও শক্ত ও সস্তা ভিত্তিরেখা ([RETSim](https://arxiv.org/pdf/2311.17264))। শেষে আমদানির সময় অ্যাডমিন নিজে নিশ্চিত করবেন। Excel-এর `sameAs` কলাম এই নিশ্চিতকরণ আগেভাগেই করে রাখার উপায়। একটি ব্যতিক্রম মনে রাখুন: **একই প্রশ্নে ভিন্ন সঠিক উত্তর থাকলে সেটি duplicate নয়, তথ্য বদলে গেছে**। তখন নতুন প্রশ্ন বানাতে হবে এবং পুরোনোটিতে `timeSensitive = true` দিতে হবে।

একই যুক্তিতে টপিক পরীক্ষার লিংকে না রেখে **প্রশ্নের ওপর** রাখতে হবে। এখন টপিক আছে `exam_questions.syllabus_node_id`-এ, অর্থাৎ পরীক্ষাভেদে। তার ওপর `syllabus_nodes` সিলেবাস-ভার্সন অনুযায়ী আলাদা। মাইগ্রেশনে বাংলা ৩৫ ও ৩০ নম্বরের দুটি ভার্সন রয়েছে, যা ৫০তম BCS-এর নম্বর-বণ্টন পরিবর্তনের সঙ্গে মেলে ([Prothom Alo English](https://en.prothomalo.com/youth/employment/313ygkw0bx))। তাই প্রশ্নে স্থায়ী **কোড-পাথ** (`bangla/grammar/usage`) রাখাই নিরাপদ। নোড ID সিলেবাস-ভার্সন বদলালে বদলে যায়, কোড বদলায় না। প্রতিটি পরীক্ষার সিলেবাসে সেই কোড থেকে নোড খুঁজে নেওয়া হবে।

## উপসংহার ও চূড়ান্ত সুপারিশ

তুলনার সবচেয়ে বড় শিক্ষা হলো, ভবিষ্যৎ-প্রমাণ স্কিমা মানে বেশি কলাম নয়। দরকার কলামগুলোর সঠিক জায়গা। প্রতিযোগীদের প্রায় সব "স্মার্ট" ফিচার, যেমন দুর্বল টপিক, ট্রেন্ড, ভুলের ভল্ট বা readiness score, প্রশ্নের ফিল্ড নয়। এগুলো চার জিনিসের যোগফল: অ্যাটেম্পট-লগ, পরীক্ষা-লিংক, স্থির টপিক-কোড আর ব্যাচে হিসাব করা পরিসংখ্যান। তাই Excel-এ শুধু সেই তথ্য রাখুন যা মানুষ ছাড়া কেউ জানে না: প্রশ্ন, উত্তর, উৎস, টপিক আর উত্তরের নির্ভরযোগ্যতা। বাকি সব সিস্টেম নিজে তৈরি করবে। একটি অনিশ্চয়তা থেকে যায়। হিসাব করা difficulty কত অ্যাটেম্পটের পর বিশ্বাসযোগ্য হবে, তার কোনো প্রামাণিক সংখ্যা পাওয়া যায়নি। নিচের ৩০ সংখ্যাটি একটি বিচারভিত্তিক অনুমান।

### ১. Excel হেডার: মোট ২৪টি কলাম

কলামের ক্রম এটাই রাখুন। বর্তমান পার্সার কলাম নাম দিয়ে মেলায় (case-insensitive), তাই পুরোনো ১২ কলামের ফাইল আগের মতোই চলবে। ভবিষ্যতে নতুন কলাম লাগলে শুধু শেষে যোগ করুন, কখনো নাম বদলাবেন না বা মুছবেন না।

| # | কলাম | বাধ্যতামূলক? | অনুমোদিত মান / নিয়ম |
|---|---|---|---|
| 1 | `id` | ঐচ্ছিক | ফাঁকা থাকলে নতুন প্রশ্ন (সিস্টেম ID দেবে); বিদ্যমান ID থাকলে সেই প্রশ্ন আপডেট হবে |
| 2 | `questionText` | **সব ফাইলে** | প্রশ্নের মূল টেক্সট |
| 3 | `subject` | **সব ফাইলে** | `bangla`, `english`, `bangladesh-affairs`, `international-affairs`, `geography-environment`, `general-science`, `computer-ict`, `mathematical-reasoning`, `mental-ability`, `ethics-good-governance` |
| 4–7 | `optionA` `optionB` `optionC` `optionD` | **সব ফাইলে** | চারটিই পূরণ করতে হবে |
| 8 | `correctOptionKeys` | **সব ফাইলে** | `A`/`B`/`C`/`D`; একাধিক হলে কমা দিয়ে আলাদা (`A,C`) |
| 9 | `explanation` | সুপারিশকৃত | ব্যাখ্যা |
| 10 | `source` | ঐচ্ছিক | পুরোনো ফিল্ড; PYQ নয় এমন উৎস (যেমন "মডেল টেস্ট", বইয়ের নাম)। `examCode` থাকলে ফাঁকা রাখা যায়, সিস্টেম পরীক্ষার শিরোনাম বসিয়ে দেবে |
| 11 | `sourceYear` | ঐচ্ছিক | চার অঙ্কের বছর; `examCode` থাকলে সিস্টেম নিজে পূরণ করবে |
| 12 | `taxonomyNodeCode` | সুপারিশকৃত | পূর্ণ কোড-পাথ, যেমন `bangla/grammar/usage`; এর মূল অংশ `subject`-এর সঙ্গে মিলতে হবে; অজানা কোড হলে সারিটি বাতিল |
| 13 | `examCode` | **PYQ ফাইলে** | `bcs-{n}-pre` (যেমন `bcs-44-pre`), বিশেষ BCS হলে `bcs-{n}-special-pre`; এটিই `exams.exam_id` |
| 14 | `questionNo` | **PYQ ফাইলে** | 1–200, একই `examCode`-এর মধ্যে অনন্য |
| 15 | `questionType` | ঐচ্ছিক | `standard` (ডিফল্ট), `statement` (i/ii/iii সমন্বয়), `negative` (কোনটি নয়), `matching`, `fill-blank` |
| 16 | `difficulty` | ঐচ্ছিক | `easy`, `medium`, `hard`, অথবা ফাঁকা (এডিটরের অনুমান মাত্র) |
| 17 | `answerStatus` | ঐচ্ছিক | `confirmed` (ডিফল্ট), `disputed`, `corrected`, `cancelled` (BPSC বাতিল করেছে; স্কোরিং থেকে বাদ) |
| 18 | `officialOptionKeys` | ঐচ্ছিক | `corrected`/`disputed` হলে BPSC বা প্রচলিত গাইডের উত্তর; ফরম্যাট `correctOptionKeys`-এর মতো |
| 19 | `answerNote` | ঐচ্ছিক | বিতর্ক বা হালনাগাদ তথ্যের ব্যাখ্যা ("বর্তমানে ... পরিবর্তিত") |
| 20 | `reference` | ঐচ্ছিক | উত্তরের প্রমাণ: বই + পৃষ্ঠা অথবা URL |
| 21 | `timeSensitive` | ঐচ্ছিক | `true`/`false`; ফাঁকা মানে `false` |
| 22 | `tags` | ঐচ্ছিক | ছোট হাতের kebab-case, কমা দিয়ে আলাদা (`liberation-war,constitution`); টপিকের বিকল্প হিসেবে নয় |
| 23 | `imageUrl` | ঐচ্ছিক | https URL (চিত্রভিত্তিক মানসিক দক্ষতা বা জ্যামিতি প্রশ্নের জন্য) |
| 24 | `sameAs` | ঐচ্ছিক | বিদ্যমান প্রশ্নের `id`। দিলে নতুন সারি তৈরি হবে না, শুধু `examCode`/`questionNo` দিয়ে লিংক যোগ হবে |

সারসংক্ষেপে: **৭টি কলাম সব ফাইলে বাধ্যতামূলক** (questionText, subject, optionA–D, correctOptionKeys)। **২টি PYQ ফাইলে বাধ্যতামূলক** (examCode, questionNo)। **২টি সুপারিশকৃত** (explanation, taxonomyNodeCode)। বাকি **১৩টি ঐচ্ছিক**। মোট ২৪টি। আমদানির আগে পরীক্ষাটি অ্যাডমিনে তৈরি থাকতে হবে, কারণ পরীক্ষা-স্তরের তথ্য প্রতিটি সারিতে বারবার লেখা হবে না।

### ২. ডাটাবেস: ৭টি টেবিলে ৭৩টি ফিল্ড

| টেবিল | ফিল্ড | উৎস | সংখ্যা |
|---|---|---|---|
| `questions` (বিদ্যমান) | id, question_text, subject, options, correct_option_keys, explanation, source, source_year, created_at | Excel (created_at সিস্টেম) | 9 |
| `questions` (নতুন) | taxonomy_code, question_type, difficulty, answer_status, official_option_keys, answer_note, reference, time_sensitive, tags TEXT[], image_url | Excel | 10 |
| `questions` (নতুন) | status (`draft`/`ready`/`retired`), text_hash, updated_at, extra JSONB | সিস্টেম | 4 |
| `exam_questions` | exam_id, question_id, syllabus_node_id, assigned_at + **question_no** | Excel (examCode, questionNo, sameAs) | 5 |
| `exams` | বিদ্যমান ৯টি + **kind** (`pyq`/`model`/`live`), **bcs_number**, **variant** (`regular`/`special`), **set_name**, **held_on** | অ্যাডমিন ফর্ম | 14 |
| `exam_result_answers` | result_id, question_id, selected_key, is_correct, syllabus_node_id + **time_spent_ms** | অ্যাপ (প্রতিটি অ্যাটেম্পট) | 6 |
| `question_stats` (নতুন) | question_id, attempt_count, correct_count, skip_count, p_value, avg_time_ms, option_pick_counts JSONB, computed_difficulty, appearance_count, last_appeared_year, computed_at | ব্যাচে হিসাব | 11 |
| `user_question_marks` (নতুন) | user_id, question_id, is_bookmarked, note, created_at, updated_at | ব্যবহারকারী | 6 |
| `question_reports` (নতুন) | id, question_id, user_id, type (`wrong-key`/`typo`/`outdated`/`duplicate`/`other`), message, status (`open`/`fixed`/`rejected`), created_at, resolved_at | ব্যবহারকারী/অ্যাডমিন | 8 |
| | | **মোট** | **73** |

Excel থেকে মোট **২০টি ফিল্ড** লেখা হয়: `questions`-এর ১৮টি (৪টি অপশন কলাম মিলে একটি `options`) এবং `exam_questions`-এর ২টি। `sameAs` কোনো কলাম নয়। এটি আমদানির সময়ের একটি নির্দেশনা মাত্র। বাকি ফিল্ডগুলো যেভাবে আসে:

- **"কতবার এসেছে" ও ট্রেন্ড:** `appearance_count` = `kind = 'pyq'` পরীক্ষাগুলোতে `exam_questions` সারির সংখ্যা। ট্রেন্ড = `taxonomy_code × held_on` অনুযায়ী GROUP BY।
- **হিসাব করা কঠিনতা:** `computed_difficulty` আসে p-value থেকে, ন্যূনতম ৩০টি অ্যাটেম্পট হলে (এটি বিচারভিত্তিক সংখ্যা)। তার আগে Excel-এর `difficulty` দেখানো হবে।
- **ব্যবহারকারীর অবস্থা:** ভুল, অনুত্তরিত বা অদেখা প্রশ্নের তালিকা বের হবে `exam_result_answers` থেকে, আলাদা কোনো টেবিল লাগবে না।

### ৩. প্রতিযোগীদের ফিচার বনাম এই স্কিমা

| ফিচার/ফিল্টার | কারা দেয় | এই স্কিমায় যেভাবে হবে |
|---|---|---|
| পেপার ধরে বিগত প্রশ্ন, বছর, সেট | Satt Academy, Explained, BD Job Prep | `examCode`, `held_on`, `set_name` ✔ |
| বিষয়/অধ্যায়/টপিক অনুযায়ী কাস্টম টেস্ট | BCS Prostuti, Satt, Live MCQ | `subject` + `taxonomy_code` ✔ |
| ট্যাগ বা কীওয়ার্ড সার্চ | Satt (Tag), BCS Prep, Live MCQ স্মার্ট সার্চ | `tags` + `pg_trgm` ✔ |
| কঠিনতা ফিল্টার | Medha, Magoosh, Embibe | `difficulty` → `computed_difficulty` ✔ |
| "কোথায় কোথায় এসেছে" / পুনরাবৃত্তি | ডাইজেস্ট (অনুমিত); প্রকাশ্যে কোনো অ্যাপে পাওয়া যায়নি | `exam_questions` M:N ✔ (প্রতিযোগীদের থেকে এগিয়ে) |
| অধ্যায়ভিত্তিক ট্রেন্ড | com.bcsquestionbank, Anantam IAS | GROUP BY ✔ |
| ভুল/অনুত্তরিত, Mistake Vault | Live MCQ, Satt, UWorld | `exam_result_answers` ✔ |
| বুকমার্ক + নিজস্ব নোট | com.bcsquestionbank, Prostuti | `user_question_marks` ✔ |
| বিতর্কিত বা সংশোধিত উত্তর | Live MCQ, Explained | `answerStatus`, `officialOptionKeys`, `answerNote` ✔ |
| পরিবর্তিত তথ্যের সতর্কতা | Live MCQ ডাইনামিক ইনফো | `timeSensitive` + `answerNote` ✔ |
| রেফারেন্স | com.bcsquestionbank, BCS Prep | `reference` ✔ |
| ভুল রিপোর্ট | Prostuti, Explained | `question_reports` ✔ |
| সময়-বিশ্লেষণ, টপারের সঙ্গে তুলনা | Oliveboard, Embibe | `time_spent_ms`, `avg_time_ms` ✔ |
| ০.৫ নেগেটিভ মার্কিংসহ মডেল টেস্ট, বিষয়ভিত্তিক ফল | Live MCQ, Explained | `exams.negative_marks` + `subject` ✔ |
| স্পেসড রিপিটিশন | BCS Prep (hibcs1) | ✘ এখন নয়; পরে নতুন টেবিল দিয়ে যোগ করা যাবে |
| দ্বিভাষিক প্রশ্ন, Bloom লেভেল, ideal time, IRT | BCS Prep, Embibe | ✘ এখন নয় |

([BCS Prep](https://play.google.com/store/apps/details?id=com.hibcs1.app), [Oliveboard](https://www.oliveboard.in/blog/ai-based-mock-test-analysis/), [Magoosh](https://gre.magoosh.com/faq), [UWorld](https://tech.medicine.wsu.edu/technology/medical-education/uworld/question-bank-students/), [Embibe](https://www.embibe.com/in-en/best-education-content/tests-that-not-just-evaluate-but-also-diagnose/))

### ৪. যা ইচ্ছা করেই এখন যোগ করা হচ্ছে না

| বাদ দেওয়া জিনিস | কারণ |
|---|---|
| **Moodle-ধাঁচের অপরিবর্তনীয় `question_versions`** | একজন অ্যাডমিনের জন্য খরচ বেশি। উত্তর সংশোধনের প্রয়োজন `answer_status` + `official_option_keys` + `updated_at` দিয়েই মিটে যায়। দরকার হলে পরে শুধু insert-only `question_edits` লগ টেবিল যোগ করলেই চলবে, বিদ্যমান কলামে হাত দিতে হবে না। |
| **আলাদা `topic`/`subtopic` কলাম, বা প্রশ্নপ্রতি একাধিক টপিক** | একটি পূর্ণ-পাথ `taxonomyNodeCode` সংগতি বজায় রাখে। দ্বিতীয় টপিক রাখলে ট্রেন্ড-গণনায় একই প্রশ্ন দুবার গোনা হবে। পার্শ্ব-বিষয়ের জন্য `tags` আছে। |
| **`optionE`, অপশনপ্রতি `fixed`/shuffle ফ্ল্যাগ** | BCS-এ সবসময় ৪টি অপশন থাকে। "সবগুলো" ধরনের অপশন ভাঙা এড়াতে আপাতত PYQ-এর অপশন শাফল করবেন না। দরকার হলে `options` JSONB-তেই ফ্ল্যাগ যোগ করা যাবে, স্কিমা বদলাতে হবে না। |
| **`language` / দ্বিভাষিক ফিল্ড** | ভাষা `subject` থেকেই বোঝা যায় (`english` হলে ইংরেজি)। English-version পেপার আলাদা `examCode`। |
| **Bloom লেভেল, ideal time, IRT প্যারামিটার** | Embibe-এর মতো বড় ডেটা আর মেশিন-ট্যাগিং লাগে। IRT-তে বড় নমুনা দরকার ([UMN](https://conservancy.umn.edu/server/api/core/bitstreams/96001aa7-3f14-4e13-bb20-cf3b0cc1a5ab/content))। p-value দিয়েই শুরু করুন। |
| **`factAsOf` / `validUntil` তারিখ** | তারিখ পাওয়া যায় পরীক্ষার `held_on` থেকে। কোনো স্ট্যান্ডার্ডও এমন ফিল্ড নির্ধারণ করে না। `timeSensitive` + `answerNote` যথেষ্ট। |
| **`question_relations` টেবিল, pgvector embedding** | `sameAs` + `text_hash` + `pg_trgm` দিয়েই হুবহু ও প্রায়-হুবহু মিল ধরা যায়। প্যারাফ্রেজ শনাক্ত করা পরে নতুন টেবিল দিয়ে যোগ করা যাবে। |
| **Excel-এ `status` বা `important` ফ্ল্যাগ** | স্ট্যাটাস অ্যাডমিন-ওয়ার্কফ্লোর অংশ। "গুরুত্বপূর্ণ" বের হয় `appearance_count` আর ট্রেন্ড থেকে, হাতে লেবেল বসানোর দরকার নেই। |
| **স্পেসড রিপিটিশন (`next_review_at`)** | এটি পরে `user_question_marks`-এ বা নতুন টেবিলে যোগ করা যাবে। প্রশ্ন বা Excel-এ কোনো প্রভাব পড়বে না। |

শেষ নীতি: Excel হেডার আর `questions` টেবিলের ২৩টি কলাম এখন থেকে স্থির। নতুন চাহিদা এলে প্রথম বিকল্প নতুন টেবিল, দ্বিতীয় বিকল্প `extra` JSONB। বিদ্যমান কলামের নাম বা অর্থ কখনো বদলাবেন না।
