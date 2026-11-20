# Item-bank standards and best practice for MCQ question-bank schema (QTI, Moodle, psychometrics, dedup, qbank UX)

Research date: 2026-11-20. Fourteen tool calls. Primary sources: 1EdTech QTI 3.0 docs, MoodleDocs, university testing-office pages. Commercial qbank (UWorld, Magoosh) details come mostly from their own blogs/FAQs plus some third-party pages; I flag these where it matters.

## 1. IMS/1EdTech QTI 3.0 (and LOM profile): which item fields exist

### Takeaway
QTI splits an MCQ into two parts. The item XML holds identifier, title, language, the interaction, the response declaration with the correct response, the outcome/score and the feedback. The package manifest holds descriptive metadata: QTI metadata plus a LOM profile with version, status, contributors, keywords and classification/taxonPath for subject and curriculum. QTI explicitly does **not** recommend an editorial LOM "difficulty" field, and it has no item-statistics model.

### Cited Findings
- `qti-assessment-item` required attributes: `identifier`, `title`, `time-dependent`. Optional: `label`, `xml:lang` (recommended), `tool-name`, `tool-version`, `adaptive` (default false). — [QTI 3.0 Best Practices & Implementation Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- For a single-answer MCQ: `qti-response-declaration` with `cardinality="single"` and `base-type="identifier"`. The key is in `qti-correct-response`/`qti-value`. Partial credit uses `qti-mapping` with `qti-map-entry`, plus `lower-bound`, `upper-bound` and `default-value`. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- `qti-choice-interaction` has `response-identifier`, `max-choices` and `shuffle="true"`. Each option is a `qti-simple-choice` with its own `identifier`, and `fixed` pins an option (e.g. "All of the above") during shuffling. The stem goes in `qti-prompt`. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- Outcomes are typically `qti-outcome-declaration identifier="SCORE" cardinality="single" base-type="float"`. Scoring is usually the `match_correct` response-processing template. Feedback uses `qti-modal-feedback` (item level) and `qti-test-feedback`. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- QTI metadata (`qtiMetadata`) holds `itemTemplate`, `timeDependent`, `composite`, `interactionType` (e.g. `choiceInteraction`), `feedbackType` (adaptive/nonadaptive/none), `solutionAvailable`, `scoringMode` (human/externalmachine/responseprocessing), `toolName`, `toolVersion` and `toolVendor`. — [QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind)
- LOM profile fields recommended for items:
  - General: Identifier, Title, Language, Description, Keyword
  - Lifecycle: **Version, Status, Contribute** (authors/editors with dates)
  - Educational: Learning Resource Type, Context, Typical Learning Time, Description, Language. **`Difficulty` is listed as not recommended.**
  - Rights: Cost, Copyright, Description
  - Relation: Kind, including `ispartof`, `haspart`, `requires`, and the non-LOM `precludes`
  - Classification: subject via `purpose=discipline`, finer topics via `purpose=idea`, with `taxonPath.source` naming the scheme (e.g. a curriculum)

  — [QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind)
- The metadata binding defines no usage-data or item-statistics elements (no p-value or IRT fields). — [QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind) (first ~100k characters reviewed)
- The impl guide says learning standards and CASE identifiers are associated with items through manifest metadata, and the item identifier should be repeated in the LOM metadata. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- LOM classification may repeat. Each taxonPath has a source system and an ordered list of taxa, where each level refines the previous one. — [IMS LOM XML binding 1.2.1](https://www.imsglobal.org/metadata/imsmdv1p2p1/imsmd_bindv1p2p1.html); [APIP PARCC LOM checklist](https://www.imsglobal.org/sites/default/files/APIP/PARCC/apipv1p0_parcc_lomresourcev1p0_v1p0.html)

### Inferences
- Columns that map well to QTI:
  - `question_id` (stable identifier)
  - `title`/`label`
  - `language`
  - `stem` (prompt)
  - options, each with a **stable option identifier (A/B/C/D or option_id), not just position**
  - `correct_option_id` (correct-response)
  - `shuffle_allowed`, plus a per-option `fixed` flag for "সবগুলো/কোনটিই নয়" options
  - `explanation` (modal/solution feedback)
  - `keywords`/tags
  - `version`, `status`, `author`/`reviewer` with dates
  - a taxonomy path (subject > topic > subtopic) that has a source/scheme code
- The LOM Relation `precludes` kind is the standards-based analogue of "enemy items". A `question_relations` table with kinds like `duplicate_of`, `variant_of`, `precludes` fits this.
- Following QTI, don't make editorial difficulty authoritative. Keep it optional and derive empirical difficulty from attempts (see section 3).

### Gaps
- I could not see the full manifest example or the CASE-alignment section of the 437k-character impl guide (fetch truncation). The exact element for curriculum-standard alignment (e.g. `curriculumStandardsMetadata`) is unverified.
- Bloom's taxonomy level is not a named QTI/LOM field in what I reviewed. The usual approach is LOM classification with `purpose=educational objective`, but I didn't confirm this in QTI 3 docs.

## 2. Moodle question bank fields, versions, status and statistics

### Takeaway
Moodle (4.x/5.x) stores these things for a question:
- a hierarchical category, name, an optional `idnumber`, question text with a format, general feedback
- default mark (`defaultgrade`), penalty, the hidden flag and tags
- answers with a fraction and per-answer feedback
- single/multi, shuffleanswers and answernumbering

It also keeps **immutable versions**: each edit creates a new version, and quizzes pin either "Always latest" or a specific version. A Ready/Draft status gates use in quizzes. The bank shows Usage, Last used, Comments, Facility index, Discriminative efficiency and "Needs checking" columns.

### Cited Findings
- Moodle XML multichoice elements:
  - `<question type="multichoice">`, `name`, `questiontext format=(html|moodle_auto_format|plain_text|markdown)`
  - `generalfeedback`, `defaultgrade`, `penalty`, `hidden`
  - `tags/tag`
  - `answer fraction="100|0"` with `text` and per-answer `feedback`
  - `single` (true/false), `shuffleanswers`, `answernumbering` (none/abc/ABCD/123)
  - `correctfeedback`, `partiallycorrectfeedback`, `incorrectfeedback`
  - Category is set with a separate `type="category"` pseudo-question holding a path like `$course$/XXXX`.

  — [MoodleDocs: Moodle XML format](https://docs.moodle.org/en/Moodle_XML_format)
- Moodle 5.0 bank columns and filters:
  - Columns: **Version** (with a History action), **Status** (ready/draft), **Usage** (number of quizzes using it), **Last used**, **Comments** (peer review/QA), **Needs checking**, **Facility index**, **Discriminative efficiency**
  - Filters: Category, Hidden, Type, Time modified, Status, and keyword search over name, **ID number**, question text and general feedback
  - Only "Ready" questions can be added to quizzes, and quizzes can use a fixed version instead of the latest.

  — [MoodleDocs 5.0: Question banks](https://docs.moodle.org/500/en/Question_banks)
- Each edit creates a new version, and the full history is available. A quiz slot can pin version n instead of "Always latest". Changing status doesn't modify the question. — [MoodleDocs 5.0 Question banks](https://docs.moodle.org/500/en/Question_banks) via search summary; also [Elon Univ. KB: Question Versioning](https://elon.teamdynamix.com/TDClient/1947/ITSelfServicePortal/KB/Article/148347/Question-Versioning) (secondary)
- Moodle per-question statistics and bands:

  | Statistic | Definition | Bands / thresholds |
  |---|---|---|
  | Facility index (F) | Mean score on the item | 35–65 "about right" |
  | SD | Spread of scores | Below 1/3 of max is not satisfactory |
  | Random guess score | Expected score from guessing; MCQ, deferred feedback | Above 40% is unsatisfactory |
  | Intended weight | Weight as a percentage of the test score | — |
  | Effective weight | Based on the covariance of the question score with the total | Should sum to 100% |
  | Discrimination index | Correlation of the question score with the **rest of the test** | ≥50 very good; 30–50 adequate; 20–29 weak; 0–19 very weak; negative means probably invalid |
  | Discriminative efficiency | Discrimination relative to the maximum possible given difficulty | >50% achievable; max discrimination needs F ≈ 30–70% |

  - Test level: Coefficient of internal consistency (>75% good, <64% unsatisfactory), Error ratio, and SE = SD×ER/100.
  - The discrimination index drives the "Need for revision" column in 4.0+.
  - The statistics are designed for summative tests with one attempt.

  — [MoodleDocs dev: Quiz report statistics](https://docs.moodle.org/dev/Quiz_report_statistics); [MoodleDocs 4.1 Quiz statistics report](https://docs.moodle.org/401/en/Quiz_statistics_report)

### Inferences
- Adopt Moodle's split between **question (stable identity)** and **question_version (immutable content snapshot)**.
- Attempts and exam-paper links should reference the version actually shown, so that a fixed typo or a changed key never silently rewrites history. An exam paper is like a quiz pinning version n; practice mode uses "latest Ready".
- Keep `status` (draft/ready/…) separate from `hidden`/`retired`.
- Moodle's `idnumber` is a human-assigned stable external code. The BCS equivalent is a code like `BCS-44-Q073` for a source-paper position, distinct from the internal UUID.
- Store per-question aggregates: attempts count, facility, discrimination, last_used, and a needs_checking flag.

### Gaps
- I did not fetch the 4.x MoodleDocs page that shows the DB columns (`question_bank_entries`, `question_versions`). The table names come from my background knowledge, not from cited sources in this session.

## 3. Psychometric item statistics (CTT, distractors, IRT) and data-driven difficulty

### Takeaway
Standard item banks store classical statistics computed from responses:
- p-value/facility, the proportion correct
- discrimination, as a point-biserial or corrected item-total correlation
- per-option selection rates, for distractor analysis

IRT parameters (a, b, c under 3PL) are added once there are large calibration samples. Difficulty is the observed proportion correct rather than an editorial label. Thresholds are rules of thumb that vary by source.

### Cited Findings
- Difficulty is usually the p-value, the proportion who answer correctly, from 0 to 1. — [BYU Open: Item statistics and analysis](https://open.byu.edu/Assessment_Basics/item_analsyis) (from search snippet); [UT Austin: Interpreting Test Results](https://testingservices.utexas.edu/interpreting-test-results)
- UT Austin bands:
  - Difficulty: p > 0.90 is very easy; p < 0.20 is very difficult.
  - Point-biserial: ≥0.40 very good; 0.30–0.39 good; 0.20–0.29 fairly good.
  - Item-analysis data are tentative and depend on the sample and on instruction.

  — [UT Austin Testing Services](https://testingservices.utexas.edu/interpreting-test-results)
- Penn State: ideally PBS > .20. Values between .00 and .20 should be examined. — [Penn State Schreyer Institute](https://www.schreyerinstitute.psu.edu/scanning/UnderstandingExamAnalysisReport)
- Univ. of Twente: the optimal p is slightly above the midpoint between chance (1/k options) and 1. That is about 0.60 for 5 options, and the same rule gives about 0.62–0.65 for 4 options. — [U Twente: Analyze test results](https://www.utwente.nl/en/learning-teaching/assessment/Toolbox/Analyze_test_results/)
- Distractor analysis:
  - A distractor chosen by fewer than 5% of examinees is commonly called "non-functioning".
  - A distractor chosen more often than the key, especially one with a positive correlation to the total, flags a possible miskey or ambiguity.

  — search summary of [HKU item analysis workshop](https://bimhse.med.hku.hk/wp-content/uploads/2026/05/Item_Analysis_Workshop_PDF_BIMHSE.pdf) and related pages (secondary; thresholds vary)
- 3PL IRT parameters:
  - a = slope at the inflection point (discrimination)
  - b = location (difficulty)
  - c = lower asymptote (pseudo-guessing)
  - c is the hardest to estimate and needs low-ability examinees. Parameter accuracy improves with larger samples; one study cites about 2000.
  - Rasch advocates dispute the value of c.

  — [De Ayala ch. 6 (Guilford)](https://www.cms.guilford.com/excerpts/deayala_ch6.pdf?t=1); [rasch.org: 3PL or Rasch?](https://rasch.org/rmt/rmt91b.htm); [UMN calibration paper](https://conservancy.umn.edu/server/api/core/bitstreams/96001aa7-3f14-4e13-bb20-cf3b0cc1a5ab/content)
- The classic item-bank record includes author, date written, status (new/pilot/active/retired), Angoff ratings, correct answer, item format, **CTT statistics, IRT statistics, linkage to the test blueprint, item history (usage dates, reviews)** and user-defined fields. — [Wikipedia: Item bank](https://en.wikipedia.org/wiki/Item_bank)
- On commercial qbanks, Magoosh lists a difficulty level for each question. A GMAT Club forum user describes a Magoosh question as one "about 60% of customers got right over time" (unofficial). — [Magoosh GRE FAQ](https://gre.magoosh.com/faq); [GMAT Club forum](https://gmatclub.com/forum/difficulty-of-math-questions-227181.html)

### Inferences
- Statistics table (`question_stats`, per question_version, recomputed in batch):
  - `n_attempts`, `n_correct`, `p_value`
  - `point_biserial` (corrected: item vs rest-of-test score, within full mock exams only)
  - per-option `selection_count` stored as JSON or a child table
  - `avg_time_ms`, `skip_rate`, `last_computed_at`
  - optional `irt_a`, `irt_b`, `irt_c`, `irt_model`, `calibration_n`
- How difficulty works:
  - Derive `difficulty_band` (easy/medium/hard) from p-value once n ≥ some minimum (e.g. 30–100; my judgment, not sourced).
  - Fall back to `editorial_difficulty` below that.
  - Keep both columns.
- BCS preliminary uses 4 options with negative marking (0.5). Moodle's "random guess score" and the 4-option chance level of 0.25 matter, and practice-app data are low-stakes and self-selected. Treat discrimination from free practice as noisy, and compute it only from full-length mocks.
- Auto-flag `needs_review` when any of these hold: p < 0.2 with a distractor out-selecting the key, a negative point-biserial, or any option at <5% (non-functioning). The first two are a likely wrong-key signal.

### Gaps
- No authoritative single minimum sample size for stable p-values or IRT calibration was found. Results vary by study.
- I found no official Magoosh, UWorld or Kaplan documentation on how their displayed difficulty is computed.

## 4. Near-duplicate detection and linking "same item across papers"

### Takeaway
Testing programs treat overly similar items as "enemy items". Detection compares stem, key and stem+key texts with similarity scores (cosine over lexical or semantic vectors) against a threshold, then sends candidates to human review. MinHash/LSH remains the robust, cheap baseline for near-exact duplicates, and embeddings catch paraphrases. No published head-to-head comparison on MCQ banks was found.

### Cited Findings
- US patent 10741093 ("Automated determination of degree of item similarity…") defines enemy items as lexically, syntactically or semantically similar items. It scores pairs by cosine similarity with a threshold, which can be tuned by a model trained on human enemy judgments. Pairwise review scales badly: 1,770 pairs for a 60-item form and 499,500 for a 1,000-item pool. — [Google Patents US10741093](https://patents.google.com/patent/US10741093)
- A paper in the Journal of Applied Testing Technology reports that NLP narrowed expert review and found enemy pairs that had previously gone unnoticed. An ABOG example applied cosine similarity to stems, keys, and stem+key. — search summary; the paper itself was not fetched (see [PARE/UMass listing](https://openpublishing.library.umass.edu/pare/article/2117/galley/3180/view/))
- RETSim: MinHash-based LSH has long been the standard for near-duplicate detection. Neural embeddings had not consistently beaten it on robust near-dup detection until RETSim. Its benchmarks are on web/news text, not exam items. — [RETSim, arXiv 2311.17264](https://arxiv.org/pdf/2311.17264)
- Unsupervised detection of duplicate and related questions on e-learning platforms is an active research area. — [arXiv 2301.05150](https://arxiv.org/pdf/2301.05150)

### Inferences
These are design recommendations, not sourced facts.
- Normalization pipeline:
  - Unicode NFC
  - Convert Bangla digits to ASCII, or the reverse, consistently
  - Strip punctuation, whitespace and zero-width joiners (ZWJ/ZWNJ)
  - Lowercase Latin text
  - Unify common Bangla spelling variants (e.g. ী/ি, য়/য় composed forms)
- Fingerprints and matching:
  - Compute `stem_norm_hash` (exact) and `fingerprint = hash(stem_norm + sorted(normalized options))`. Sorting makes the comparison option-order-independent.
  - Add MinHash/trigram similarity (Postgres `pg_trgm`) for near-exact matches, and optionally pgvector embeddings for paraphrases.
  - Also compare the normalized **correct-answer text**. The same stem with a different key indicates a dispute or a changed fact, which is not a duplicate.
- Model one canonical `question` row with a many-to-many `exam_question` table, i.e. `(exam_id, question_id/version_id, question_no, original_option_order, original_key)`. That captures "appeared in BCS 10th, 35th, 41st" without duplicating rows.
- Keep a `question_relations` table, `(a, b, kind ∈ duplicate_of | near_duplicate | variant_of | precludes, similarity, confirmed_by, confirmed_at)`, so merges are human-confirmed and reversible.

### Gaps
- I found no published thresholds for MCQ near-dup cosine/Jaccard cut-offs, and no Bangla-specific normalization guidance in authoritative sources.

## 5. Time-sensitive facts, answer-key disputes and errata

### Takeaway
Item banks track status through a lifecycle (new/pilot/active/retired), keep a review history, and filter by status at assembly. Retired items stay stored rather than being deleted, so historical references resolve. I found no authoritative standard for "valid-until" dates or errata. This area relies on established general practice rather than a spec.

### Cited Findings
- Item status lifecycle examples are new, pilot, active and retired. Banks track "item history (e.g., usage date(s) and reviews)". — [Wikipedia: Item bank](https://en.wikipedia.org/wiki/Item_bank)
- In TAO (an open-source QTI platform), a manager can retire an item, after which it can no longer be edited or deleted. Status has no binding effect on test use, so items should be filtered by status during test assembly. — [TAO user guide: Item status](https://userguide.taotesting.com/user-documentation/latest/public/item-status)
- In Moodle, status (ready/draft) gates quiz use. Edits produce new versions, and quizzes can pin old versions. — [MoodleDocs 5.0 Question banks](https://docs.moodle.org/500/en/Question_banks)
- LOM Lifecycle provides `Version`, `Status`, and `Contribute` (role + entity + date) for each item. — [QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind)
- General data practice is to mark records inactive with a status rather than deleting them, so historical references stay resolvable. — [IF4IT inventory best practice](https://if4it.org/best-practices/enterprise-inventory-management/retire-inventory-entries-properly-mark-as-inactive-before-removing/)

### Inferences
Recommendations for BCS:
- **Two separate keys:**
  - `official_key`: what the PSC/BCS answer key or consensus said at the time
  - `current_correct_key`: the key used for scoring now

  Add a `key_dispute` flag/note with sources, because popular BCS guides often disagree with each other.
- **Time-sensitive facts:**
  - `is_time_sensitive` (bool) and `fact_as_of` (date)
  - `review_due_at`/`valid_until` (date, nullable)
  - `outdated_note` (e.g. "the capital/president/statistic has since changed")

  When outdated, keep the item for "past paper" view but exclude it from scored practice by default.
- **Errata:** every content or key change creates a new `question_version` with `change_reason` (`typo|key_correction|fact_update|translation`) and `changed_by`/`changed_at`.
  - On `key_correction`, re-score affected attempts or mark them, since that is the rescoring practice in exams.
  - User-reported issues go to a `question_reports` table (`type`: wrong key, typo, outdated, duplicate) that feeds `needs_review`.
- Status enum (codes, not labels): `draft`, `review`, `ready`, `flagged`, `retired`. `hidden` is not needed if `retired` exists.

### Gaps
- No primary standard (QTI/LOM/ITC) on "valid-until" or fact-expiry fields was found in this session. ITC/NCME test-development guidelines were not checked.

## 6. How commercial qbanks (UWorld, Kaplan, Magoosh, Khan Academy) tag and filter

### Takeaway
Commercial qbanks build custom tests from two dimensions:
- **user-state filters:** Unused, Incorrect, Marked/flagged, Omitted, Correct, All
- **content filters:** subject/system/topic, plus difficulty and question count/mode in some products (timed/tutor)

They also allow tests to be built from performance reports. Content tagging is hierarchical (subject > system/topic).

### Cited Findings
- UWorld (NCLEX) "Question Mode": Unused, Incorrect, Marked, All, Custom. These combine with subject/system filters, e.g. repeat incorrect Cardiology questions. — [WSU UWorld QBank guide](https://tech.medicine.wsu.edu/technology/medical-education/uworld/question-bank-students/) (institutional, secondary); third-party guides also list "omitted"
- UWorld lets you create a test from Reports, using questions previously answered correctly, incorrectly or omitted. New questions go through "Create Test". — [UWorld blog: Creating a Test from Reports](https://medical.uworld.com/blog/product-updates/creating-a-test-from-the-reports-section/)
- Forum users disagree on whether omitted questions count as "used". — [SDN forum](https://forums.studentdoctor.net/threads/skipped-questions-in-uworld.1058719) (anecdotal)
- Magoosh GRE custom practice sessions let you choose the number of questions plus Section, Difficulty and "previously answered questions". Each question shows a difficulty level. — [Magoosh GRE FAQ](https://gre.magoosh.com/faq)
- Magoosh GMAT practice tests are question-adaptive within a section. — [Magoosh GMAT practice test](https://magoosh.com/gmat/gmat-practice-test)

### Inferences
- Per-user state table `user_question_state (user_id, question_id, last_version_id, times_seen, times_correct, last_result ∈ correct|incorrect|omitted, is_marked, last_seen_at, next_review_at)` supports the Unused/Incorrect/Marked/Omitted filters cheaply.
- Content filters need stable codes:
  - `subject_code`, `topic_code`, `subtopic_code` (BCS preliminary syllabus: বাংলা, English, বাংলাদেশ বিষয়াবলি, আন্তর্জাতিক বিষয়াবলি, ভূগোল, বিজ্ঞান, কম্পিউটার, গণিত, মানসিক দক্ষতা, নৈতিকতা)
  - `source_exam` (via the exam_question link)
  - `difficulty_band`
  - `year`

### Gaps
- I did not retrieve Khan Academy or Kaplan primary docs on skill/concept tagging (Khan's mastery system ties exercises to skills, but this is not sourced here).
- I found no official UWorld help-center page listing exact filter labels; the current labels vary by product.

## 7. Schema stability: stable IDs, codes vs labels, versioning, M:N links

### Takeaway
The standards converge on a few rules:
- an immutable, globally unique item identifier, separate from the human-readable label/idnumber (QTI identifier vs title/label; Moodle internal id vs idnumber)
- versions as immutable snapshots that consumers pin
- status as an enum code
- taxonomy as a coded classification path with a declared source scheme
- extensibility via "user-defined fields" or metadata extensions rather than changing core columns

### Cited Findings
- QTI requires a unique `identifier` plus a separate `title` and optional `label`. Choices have their own `identifier`, so keys reference option IDs, not positions. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl)
- The item identifier should be repeated in the LOM metadata. Classification uses `taxonPath.source` to name the scheme. — [QTI 3.0 Impl Guide](https://www.imsglobal.org/spec/qti/v3p0/impl); [QTI 3.0 Metadata binding](https://www.imsglobal.org/spec/qti/v3p0/md-bind)
- Moodle keeps an internal id, an optional human `idnumber` (searchable in 5.0), versions, and quizzes pinning versions. — [MoodleDocs 5.0 Question banks](https://docs.moodle.org/500/en/Question_banks)
- Item banks include "user-defined fields". — [Wikipedia: Item bank](https://en.wikipedia.org/wiki/Item_bank)
- Retire with a status rather than deleting. — [TAO](https://userguide.taotesting.com/user-documentation/latest/public/item-status); [IF4IT](https://if4it.org/best-practices/enterprise-inventory-management/retire-inventory-entries-properly-mark-as-inactive-before-removing/)

### Inferences
Concrete proposal for the BCS app, synthesized from the above:
- **Postgres core**
  - `questions(id uuid PK, code text unique /* human, e.g. Q-000123 */, current_version_id, status, created_at)`
  - `question_versions(id, question_id, version_no, stem, options jsonb [{id:'A', text, fixed}], correct_option_id, explanation, language, editorial_difficulty, is_time_sensitive, fact_as_of, valid_until, change_reason, changed_by, created_at)`, immutable
  - `taxonomy_nodes(code PK, parent_code, label_bn, label_en, scheme)`, where labels change and codes never do
  - `question_taxonomy(question_id, node_code, is_primary)`, M:N
  - `tags` / `question_tags`
  - `exams(id, code e.g. BCS-44-PRE, year, body, date)`
  - `exam_questions(exam_id, question_version_id, question_no, original_option_order, official_key)`, M:N
  - `question_relations`
  - `question_stats`
  - `question_reports`
  - `user_question_state`
  - `extra jsonb` for future fields
- **Excel import columns** (fixed order; optional columns appended at the end only, never reordered):
  - `question_code` (blank means new)
  - `exam_code`, `question_no`
  - `subject_code`, `topic_code`, `subtopic_code`
  - `stem`, `option_a`…`option_d`, `correct_option` (A–D)
  - `explanation`
  - `tags` (semicolon-separated)
  - `editorial_difficulty` (1–3/blank)
  - `is_time_sensitive`, `fact_as_of`
  - `official_key` (if it differs)
  - `key_note`, `source_ref`, `status`
- **Import rules:**
  - Match on `question_code` when present. Otherwise run fingerprint dedup and link to the existing question, adding only an `exam_questions` row.
  - Any content change creates a new version.
  - Validate that the codes exist in the taxonomy table, i.e. never accept free-text labels as keys.

### Gaps
- No single authoritative "schema evolution" standard for item banks was found. The append-only column advice is general data-engineering practice, not sourced from an assessment standard.
