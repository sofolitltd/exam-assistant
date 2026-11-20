# How Indian government-exam prep platforms classify and filter MCQs (to inform a BCS preliminary question-bank schema)

Research date: 2026-11-20. About 20 search/fetch calls. Several primary pages failed to load or were not indexed: Testbook question pages, the Unacademy tech blog (socket hang-up twice), and the Adda247 and Testbook Play Store listings. Coverage of Testbook, Adda247, Unacademy, PracticeMock and Gradeup/BYJU'S therefore rests mostly on marketing pages and third-party listings. Embibe has the deepest public documentation. Examside, a PYQ site that was not on the original list, gave the clearest visible per-question metadata, so it is included as a reference.

## Q1. What metadata does each question carry?

### Takeaway
The documented per-question fields across platforms are:
- **Source paper:** exam, tier, date and shift.
- **Taxonomy:** subject or section, then topic. Embibe goes much deeper: subject, unit, chapter, topic, concept.
- **Format and scoring:** question type, positive and negative marks, and an English/Hindi language toggle.
- **Answer content:** correct option and explanation.
- **Embibe only:** difficulty, ideal time and Bloom level.

Difficulty is set by editors at first, and the advanced players (Embibe, Unacademy) then recompute it from attempt data. No platform in this set publicly documents frequency or "asked N times" counts per question, Bloom tags (apart from Embibe), or answer-key challenge fields.

### Cited Findings
**Examside (PYQ site; clearest example of per-question fields)**
- An SSC CGL PYQ page shows these fields:
  - Exam "SSC CGL Tier I", date "27th July 2023", "Shift 1".
  - Section "General Awareness", topic "Polity".
  - Breadcrumb `SSC CGL Tier I > General Awareness > Polity > Marks 2`, with marking "+2 −0.5".
  - Type "MCQ (Single Correct Answer)" with 4 options, plus the correct option and explanation text.
  - English/Hindi language toggle.
  - No difficulty or tags are shown.
  — [Examside question page](https://questions.examside.com/past-years/ssc/question/who-among-the-following-served-the-shortest-tenure-as-the-pr-ssc-cgl-tier-i-general-awareness-uyaajihprntvvrec)
- Examside's topic listing URL follows the path exam-board / exam / section / topic (`/past-years/ssc/ssc-cgl-tier-i/general-awareness/polity`). — [Examside Polity listing](https://questions.examside.com/past-years/ssc/ssc-cgl-tier-i/general-awareness/polity)

**Testbook**
- Testbook's practice hub is organized first by exam goal ("Select Your Goal": SSC Exams, Banking/Insurance, "GATE Previous Year Questions", "SSC JE Previous Year Questions"), then by subject categories such as General Knowledge, Quantitative Aptitude and Previous Year Questions, each with question counts. — [Testbook practice-questions](https://testbook.com/practice-questions); [Testbook SSC questions](https://testbook.com/ssc-exams-questions)
- Testbook states that practice questions "are available in English as well as Hindi" and come with "Detailed solutions and analytics". — [Testbook practice-questions](https://testbook.com/practice-questions)
- Testbook-hosted PYQ PDFs carry a "Testbook Solution" block per question (correct option plus explanation). Third-party copies of Testbook mocks show "Question ID", "Status" and "Chosen Option" fields per question. — [Testbook PDF, SSC CGL 3 Mar 2020 Shift 3](https://blogmedia.testbook.com/blog/wp-content/uploads/2020/07/ssc-cgl-3-march-2020-shift-3_eng-a7eaa2d4.pdf); [Scribd copy](https://www.scribd.com/document/624824439/Ggn)

**Industry paper labels**
- Across the industry, PYQ papers are labelled as exam + tier + date + shift, e.g. "SSC CGL PYQ Solved Paper (Held On 27/7/2023, Shift 3)" and "SSC CGL 2024 (Tier-I) Previous Year Paper (17-Sep-2024) (Shift 3)". — [Chronicle India catalog](https://www.chronicleindia.in/catalog/sample-download/749); [Prepp](https://prepp.in/practice/69832399071eb2de338ddd91/instruction); [Adda247 PDF "DDA Patwari Official Paper Held On 19 Aug 2023 Shift 2"](https://www.adda247.com/jobs/wp-content/uploads/sites/22/2025/09/13170922/DDA-Patwari-Official-Paper-Held-On_-19-Aug-2023-Shift-2.pdf)

**Embibe (deepest documented model)**
- Embibe's MetaTags Ranker suggests tags for "subject, unit, chapter, topic and concept", plus difficulty level, ideal time and Bloom level. It is a "human-in-a-loop semi-automatic tagging process" that replaces purely manual subject-matter-expert tagging. The problem is framed as extreme multi-class classification over 74,000+ concept classes, which are not mutually exclusive. — [Embibe MetaTags Ranker](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education-articles/meta-tags-ranker/)
- Embibe's team manually tagged hundreds of thousands of questions with concepts, syllabus, skills, difficulty, ideal time and Bloom level to create training data. — [Embibe learning-outcomes AI stack](https://embibe.com/in-en/artificial-intelligence-ai-in-education/building-the-learning-outcomes-ai-stack) (via search snippet)
- Embibe derives question difficulty and a discrimination factor from the weights of a deep neural network trained on student attempt data. The model implements a classical two-parameter item response theory (2PL IRT) model. — [Embibe Question Discrimination Factor](https://embibe.com/in-en/artificial-intelligence-ai-in-education/question-discrimination-factor) (via search snippet)
- Embibe's Bloom categories are "Application, Comprehension, Rote Learning, Analysis". — [Embibe tests that diagnose](https://www.embibe.com/in-en/best-education-content/tests-that-not-just-evaluate-but-also-diagnose/)

**Unacademy (computed difficulty)**
- Unacademy's engineering blog describes a baseline difficulty estimate built from the proportion of incorrect versus correct answers plus the median time learners take on the question. — [Unacademy tech: question difficulty estimation](https://tech.unacademy.com/question-difficulty-estimation/) (search snippet only; the full page failed to load)

**UPSC PYQ analysers (taxonomy depth)**
- Anantam IAS tags each of 1,403 UPSC prelims questions (2013–2026) with one subject tag and one topic tag "applied at the time of entry". Cross-subject questions are counted once, under the subject the tagger chose. There is no subtopic level, and no difficulty or question-format tags. — [Anantam IAS PYQ topic-wise](https://anantamias.com/upsc-prelims-pyq-topic-wise/)
- SuperKalam shows difficulty only as yearly Easy/Medium/Hard percentages, not per question. Its practice-launch URLs carry year, subject, topic and "filter" parameters. — [SuperKalam PYQ analysis](https://superkalam.com/upsc-prelims/previous-year-question-paper/analysis)

### Inferences
- **Minimum fields:** exam, tier or paper, date and shift (so year can be derived), section, topic, type, marks and negative marks, language variants, correct option, explanation, and a stable question ID. Examside's breadcrumb matches this almost exactly. Testbook and Adda247 paper titles use the same exam/date/shift identity.
- **Two-level taxonomy is the norm for PYQ banks:** subject, then topic, maybe a subtopic. Embibe's five-level graph is unusually deep and needs machine-assisted tagging to maintain. For a BCS bank with a fixed syllabus, three levels is a pragmatic ceiling: subject (the BCS syllabus section), then chapter/topic, then an optional subtopic or concept.
- **Store difficulty twice:** an editorial seed and a computed value from attempts (percent correct plus median time, or IRT). This mirrors Embibe and Unacademy.
- **"Asked in" for repeated questions:** none of the platforms surfaced a per-question "asked in" list. Since repeated PYQs are common (SuperKalam shows repeated-question examples), a one-to-many link from a question to its source papers is better than a single year field. This is design inference, not documented practice.

### Gaps
- No public JSON or API payload of a Testbook, Adda247, Oliveboard or Unacademy question object was found.
- Testbook's per-question "previously asked in … (Held On … Shift …)" label could not be verified. Testbook question pages did not surface in search, and I did not include it from memory.
- Nothing was found on answer-key challenge or correction fields, Bloom tagging outside Embibe, or how ideal time is set (expert, historical median, or model).
- I found no source on Gradeup/BYJU'S question metadata.

## Q2. What filters and modes do users get?

### Takeaway
Every platform offers the same core modes:
- **Practice and test modes:** full mock tests, sectional tests, chapter/topic tests, PYQ papers by exam/date/shift, topic-wise practice with re-attempt, and bookmarks.
- **Analytics:** score, percentile, All India Rank, accuracy, section-wise breakdown, time split (correct/wrong/unattempted), per-question time compared with the topper, and weak/strong topic labels.

Difficulty filters and "most-asked" filters are rarely documented. Adaptive practice and attempt-quality analysis are documented mainly by Embibe.

### Cited Findings
**Oliveboard** (blog, Nov 2022)
- Test summary: attempted, correct and wrong counts; score; rank; top score; percentile; accuracy; section-wise scores.
- Time split: total time and time on correct, wrong and unanswered questions; a minute-by-minute "progress tracker".
- Comparison with the topper: score and time.
- Weak and strong areas, and which section to focus on. The older version used topic labels "very strong / strong / weak / very weak".
- Solutions tab: per-question time for you and for the topper, with the difference; grid or list views colour-coded correct/incorrect/unattempted; a "Reatt" (re-attempt) button per question.
— [Oliveboard AI mock analysis](https://www.oliveboard.in/blog/ai-based-mock-test-analysis/)

**Testbook**
- Free practice with "Reattempt"; access tiers (Pass, Pass Pro, Super Pass) gate PYQs and tests. — [Testbook practice-questions](https://testbook.com/practice-questions)
- Full tests, chapter tests and sectional tests; 200,000+ mock tests and PYQ papers (third-party listings). — [SoftwareSuggest](https://www.softwaresuggest.com/testbook/mobile-app); [BlueStacks listing](https://www.bluestacks.com/apps/educational/testbook-exam-preparation-app-on-pc.html)
- Each test can be attempted once, but the solutions and paper analysis can be viewed any number of times. — [Testbook DRDO test series](https://testbook.com/amp/drdo-sta/test-series)

**Adda247**
- Topic-wise question bank (e.g., Quant and Reasoning for banking, Maths and English for SSC).
- Question bookmarking.
- PYQ papers under the Study Material tab, covering Banking, SSC, Railways, Teaching, Defence and State PSC exams.
— [Adda247 App Store](https://apps.apple.com/in/app/adda247/id1618943840); [Bankersadda PYP guide](https://www.bankersadda.com/how-to-avail-previous-year-papers-for-free-from-adda247-app/); [Adda247 PYP product](https://www.adda247.com/product-testseries/22848/previous-years-papers-bank-insurance-ssc-railways-teaching-defence-state-psc-upsc-ae-je-and-others-online-test-series-by-adda247)

**PracticeMock** (blog guidance only)
- Its guides tell users to review score, accuracy, time spent, wrong answers, skipped questions and section-wise performance, and to track average time per question and topic-wise accuracy. — [PracticeMock RRB PO analysis](https://www.practicemock.com/blog/ibps-rrb-po-mock-test-analysis/); [PracticeMock RBI Grade B](https://www.practicemock.com/blog/?p=188033)

**BYJU'S Exam Prep (ex-Gradeup)**
- Test series with "detailed solutions and performance analysis and an All India rank and score"; "150+ Interactive Quizzes, 30+ Mock Test". — [BYJU'S Exam Prep test series](https://byjusexamprep.com/online-test-series); [BYJU'S Exam Prep mock challenge](https://byjusexamprep.com/ibps-clerk-prelims-2021-mega-mock-challenge--register-now-i)

**Embibe**
- Overall behaviour types ("Careless", "Jumping Around", "Getting There", etc.).
- Question-wise attempt quality: Too Fast Correct, Perfect Attempt, Overtime Correct, Too Fast Incorrect, Overtime Incorrect, Wasted Attempt, Incorrect, Unattempted.
- Skill-wise (Bloom) analysis, concept-level strengths and weaknesses, "Sincerity Scores", and chapter tests.
— [Embibe tests that diagnose](https://www.embibe.com/in-en/best-education-content/tests-that-not-just-evaluate-but-also-diagnose/)
- Definitions: a correct answer in under 25% of the question's ideal time is "too fast correct"; a correct answer taking more than the ideal time is "overtime correct". — [Embibe mastery tracking](https://embibe.com/in-en/best-education-content/solving-the-hard-problem-of-tracking-a-students-mastery-on-every-concept) (via search snippet)
- Embibe markets "dynamic and adaptive practice" to raise competency levels. — [Embibe adaptive practice](https://embibe.com/in-en/best-education-content/dynamic-and-adaptive-practice-to-increase-competency-levels)

**UPSC PYQ tools**
- SuperKalam: "timed quizzes" from past papers, filterable by year, subject and topic, with performance tracking across syllabus topics. — [SuperKalam](https://superkalam.com/upsc-prelims/previous-year-question-paper/analysis)

### Inferences
- **Filter set to support:** exam, year, paper/shift, subject, topic, PYQ versus non-PYQ, bookmarked, incorrect, unattempted, and difficulty, plus a custom quiz builder that combines these. This requires indexed fields for each.
- **Fields needed for Oliveboard- or Embibe-style analytics:**
  - per question: `ideal_time_sec` and a computed average/median time;
  - per attempt: `time_spent_ms`, chosen option, `is_correct`, and a timestamp.
- **Negative marking must be stored per paper or per question.** It drives score and percentile; SSC uses +2/−0.5, and BCS preliminary uses 1 mark and −0.5.

### Gaps
- I could not confirm from primary help-centre pages whether Testbook, Adda247 or Unacademy offer a difficulty filter, a "most asked" filter, or a custom quiz builder.
- No current (2025–2026) help-centre documentation for Testbook or Adda247 analysis screens was found. The Oliveboard description dates from 2022.

## Q3. Public documentation revealing question data models

### Takeaway
Only Embibe publishes substantive data-model and AI documentation. Unacademy has one engineering post on difficulty. The others expose their models only implicitly, through URL structures, breadcrumbs and PDF layouts.

### Cited Findings
- Embibe AI articles cover:
  - MetaTags Ranker;
  - automated discovery of knowledge-graph nodes (a BERT-based phrase extractor);
  - auto-classification of relations between nodes, using a DKT (deep knowledge tracing) model to rank suggested relations;
  - question discrimination factor.
  — [MetaTags Ranker](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education-articles/meta-tags-ranker/); [KG node discovery](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education/automated-discovery-of-knowledge-graph-nodes/); [KG relation classification](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education/auto-classification-of-relationships-between-knowledge-graph-nodes/)
- Embibe's data team uses text classification, topic modelling and deep learning to auto-tag concepts onto questions, answers and chapters. It claims its tagging finds the most relevant concept 82% of the time, versus 18% for crowd-sourced faculty. This is a company claim and was not independently verified. — [Embibe data team (Medium)](https://medium.com/embibe/embibes-data-team-300-billion-insights-the-love-of-data-in-education-25142d89728e)
- Unacademy engineering post on question difficulty estimation. — [tech.unacademy.com](https://tech.unacademy.com/question-difficulty-estimation/)

### Inferences
- Implicit models from URLs and breadcrumbs:
  - Examside: board > exam > section > topic.
  - Testbook: goal (exam) > subject > topic.
  - SuperKalam: year/subject/topic/filter query parameters.

### Gaps
- No network-payload (JSON) inspection was possible in this research.
- No Testbook, Adda247, Oliveboard or PracticeMock engineering blogs about the question schema were found.

## Q4. Embibe's knowledge graph, and how topic-wise PYQ trends are presented

### Takeaway
- **Embibe's graph:** a curriculum-agnostic graph of about 74–75k concept nodes, about 189k interconnections and 16 relation types (including prerequisites). Questions are mapped to concepts through machine suggestions plus a human in the loop.
- **PYQ trends:** shown as a subject- or topic-by-year count grid, multi-year averages, volatility, and a share of total. Trends are computed by simply counting the subject or topic tag on each PYQ.

### Cited Findings
**Embibe knowledge graph**
- 75,000+ nodes, each a "discrete unit of academic knowledge", with 16 relation types between concepts. — [Embibe KG relation classification](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education/auto-classification-of-relationships-between-knowledge-graph-nodes/)
- About 74,000+ nodes, about 189,380 interconnections and about 215,062 competencies. — [MetaTags Ranker](https://www.embibe.com/in-en/artificial-intelligence-ai-in-education-articles/meta-tags-ranker/)

**Anantam IAS trend presentation**
- A year-by-year grid of question counts per subject for 2013–2026; for example, Environment 19/27/18/22/14 and Indian Polity 16/10/14/5/22 for 2013–2017.
- Averages for two 7-year windows, with the shift between them.
- Per-subject lowest year, highest year and standard deviation (Polity: 5, 22, σ 4.0).
- Topic breakdowns within a subject (e.g., Environmental Pollution 43 questions, 17.6%).
- Totals: Economy 232, Environment 245, Polity 198, Science and Technology 183, Geography 149.
— [Anantam IAS](https://anantamias.com/upsc-prelims-pyq-topic-wise/)

**Other UPSC trend sources**
- SuperKalam: a subject × year table (each year totals 100), averages such as about 17 Economy questions per year, and yearly Easy/Medium/Hard percentages. — [SuperKalam](https://superkalam.com/upsc-prelims/previous-year-question-paper/analysis)
- Vision IAS publishes yearly paper analyses with subject counts, e.g. 2025: Ancient History 6, Art and Culture 1, Basic Science 2, Economics 15 (partial list). — [Vision IAS GS Prelims 2025 analysis](https://visionias.in/blog/prelims-pyqs/detailed-analysis-of-upsc-paper-1-gs-prelims-2025)
- Vajiram & Ravi's figures differ from the other sources (e.g., 2013 Polity 16, Environment 17). Different taxonomies produce different counts. — [Vajiram topic-wise](https://vajiramandravi.com/upsc-exam/topic-wise-upsc-prelims-questions/)

**Published PYQ books**
- Disha's "31 Topic-wise UPSC Prelims PYQs 1995–2025" (16th edition, Mrunal Patel) is organized topic-wise across GS and CSAT. Seller listings mention "trend analysis" and option-wise explanations. An older edition grouped GS into 8 units. I could not retrieve the full table of contents. — [Flipkart listing](https://www.flipkart.com/disha-31-topic-wise-upsc-civil-services-ias-prelims-previous-year-solved-papers-1-2-1995-2025-mrunal-patel-16th-general-studies-aptitude-csat-pyqs-question-bank-2026-exam/p/itm08916ee53a58f); [eLucky listing](https://eluckybookstore.com/p/disha-31-topic-wise-upsc-civil-services-ias-prelims-previous-year-solved-papers-1-2-1995-2025-by-mrunal-patel-16th-edition-general-studies-aptitude-csat-pyqs-question-bank-for-2026-exam)
- Physics Wallah and Oswaal market "32 years" topic-wise UPSC PYQ books built around repeating-trend analysis. — [PW store blog](https://store.pw.live/blogs/upsc-exams/how-pw-32-years-upsc-pyq-book-helps-identify-repeating-trends); [Oswaal blog](https://oswaalbooks.com/blogs/our-products/upsc-prelims-2027-what-32-years-of-previous-year-questions-reveal-about-exam-trends)

### Inferences
- "X questions from topic Y in the last N years" is a simple GROUP BY on (topic, paper year). That only works if each PYQ carries exactly one canonical primary topic, as Anantam IAS does with one subject and one topic per question. Secondary or cross-listed topics should go in a separate many-to-many field so they don't double-count in trend statistics.
- A frozen, versioned taxonomy matters. Different tagging schemes (Vajiram, Anantam, SuperKalam) give inconsistent counts for the same papers.

### Gaps
- How Embibe surfaces PYQ trends to users (if it does for government exams) was not found.
- Exact current Disha and Arihant tables of contents were not retrieved.
- ClearIAS PYQ bank features were not covered: no results were retrieved for ClearIAS.
