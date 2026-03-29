# Mar 28, 2026

## 資料搜尋

# Mar 29, 2026

## Game Generation via Large Language Models

This PDF isn't available for now, I'd requested in [Research Gate](https://www.researchgate.net/publication/383501745_Game_Generation_via_Large_Language_Models).

## Large Language Models and Video Games: A Preliminary Scoping Review

Venue: arXiv:2403.02613, Mar 2024
Author: Penny Sweetser — The Australian National University

### Core Contribution

A scoping review surveying 76 papers (from 2,260 Google Scholar results) published between 2022 and early 2024 on LLMs applied to video games. Provides a foundational snapshot of the field, categorizing research into four key themes plus one adjacent topic.

### Key Findings

- Most used LLM: GPT (85.5%), followed by LLaMA (9.2%), Codex and BERT (6.6% each)
- 90.7% of papers were published in 2023, indicating rapid growth
- Positives: human interpretability, social behaviours, empowerment of non-developers, LLM+RL combinations outperforming baselines
- Negatives: lack of logical reasoning, unpredictability in live content generation, inconsistency/incoherence in AI-native games

### Themes

1. Game AI and Agents (35.5%, 27 papers) — agent design/behaviours, LLMs+RL, human-AI collaboration and multi-agent coordination (Voyager, MindAgent, LLM-Co Framework, Overcooked-AI)
2. Game Development and Play (32.9%, 25 papers) — content/level generation, serious games, game design, RPG tools, bug detection
3. Narrative, Story, and Dialogue (22.4%, 17 papers) — NPC dialogue, interactive story, quest generation
4. Game Research and Reviews (9.2%, 7 papers) — game review analysis, synthetic research data generation
5. Recommendation (bonus, 9 papers) — game datasets used in LLM4Rec research

### Game Design Sub-theme (6 papers)

Papers specifically on game design within the "Game Development and Play" theme:

| Ref | Paper | DOI |
|-----|-------|-----|
| [4] | Amresh 2023 — Integrating Reinforcement AI Into the Design of Educational Games | `10.34190/ecgbl.17.1.1709` |
| [27] | Huang & Sun 2023 — Create Ice Cream: Real-time Creative Element Synthesis Framework Based on GPT-3 | `10.1109/CoG57401.2023.10333153` |
| [28] | Gatti Junior et al. 2023 — How ChatGPT can inspire and improve serious board game design | `10.17083/ijsg.v10i4.645` |
| [34] | Lanzi & Loiacono 2023 — ChatGPT as evolutionary engines for online collaborative game design | `10.1145/3583131.3590351` |
| [56] | Saito et al. 2023 — Double Impact: Children's Serious RPG Generation/Play with a LLM | `10.1007/978-3-031-44751-8_21` |
| [70] | Tinterri et al. 2024 — AI in board Game-Based Learning | No DOI (CEUR Workshop Proceedings) |

- Idea generation [34]: collaborative design framework simulating the human design process, using LLMs for recombination and variation of ideas
- Game mechanic design [27]: element synthesis game where LLM evaluates combinations based on physical/chemical properties and logical reasoning; effective but LLM uncertainty can adversely affect game mechanics
- Serious games [4, 28, 56, 70]: LLMs supporting educators in brainstorming, choosing game types, suggesting themes/mechanics aligned with curriculum, and offering feedback on prototypes

## Automated Unity Game Template Generation from GDDs via NLP and Multi-Modal LLMs

Venue: arXiv:2509.08847, Sep 2025
Author: Amna Hassan — UET Taxila

### Core Contribution

End-to-end framework that parses GDDs and generates functional Unity C# game templates using a fine-tuned LLaMA-3-8B-Instruct model. The system combines: (1) a GDD parsing pipeline that extracts structured JSON from PDF/TXT/DOCX, (2) a LoRA-fine-tuned LLM for Unity-specific code synthesis, and (3) a custom Unity Editor package that integrates parsing, script analysis, code generation, and documentation into the editor workflow.

### Data and Fine-tuning

- 57 GDDs collected from GameScrye, GameDocs.org, Al Lowe's collection, PixelProspector — standardized into structured JSON (title, genre, mechanics, characters, levels)
- Unity code dataset sourced from the "Mix and Jam" YouTube channel (high-quality recreations of famous game mechanics). GPT-4 generated corresponding GDDs for each implementation to create paired (GDD, Unity Code) training data
- Fine-tuning: LLaMA-3-8B-Instruct + LoRA via PEFT, ~1.9M trainable parameters, ~120 training steps (single epoch), FP16 precision
- Deployed via Google Colab + ngrok + FastAPI

### Unity Package Architecture

Custom Unity Editor package with 5 components:
1. GDD Parser — uploads and extracts structured info from design documents
2. Script Analyzer — determines required scripts and builds a dependency graph
3. Script Generator — interfaces with the fine-tuned LLM via FastAPI to generate C# scripts
4. Documentation Generator — creates usage instructions and setup guides
5. Unity Editor Integration — in-editor UI for the full workflow

### Evaluation

3 experienced Unity developers scored each model (0–5) across 3 game genres (Platformer, Action RPG, Puzzle Game) on 4 metrics:

- Compilation Success — does the code compile cleanly in Unity?
- GDD Adherence — does the code faithfully implement mechanics specified in the GDD?
- Unity Best Practices — proper use of `MonoBehaviour`, `GetComponent<>()`, Input system, component-based architecture
- Modular Code — logical separation of concerns into distinct classes and methods

| Model | Comp. | Adher. | BestPrac. | Modular. | Avg |
| --- | --- | --- | --- | --- | --- |
| LLaMA 3 8B Inst. | 4.5 | 4.2 | 4.0 | 4.2 | 4.2 |
| Gemma 2 Inst. | 3.8 | 3.5 | 3.5 | 3.2 | 3.5 |
| Qwen 1.5 Chat | 2.0 | 4.8 | 2.5 | 2.8 | 3.0 |
| LLaMA 4 Maverick | 4.8 | 4.8 | 4.5 | 4.6 | 4.7 |
| Theirs (fine-tuned) | 5.0 | 4.9 | 4.5 | 4.8 | 4.8 |

### Key Findings

- Domain-specific fine-tuning on paired GDD-code data beats even larger/newer general-purpose models
- Qwen 1.5 Chat had high GDD adherence (4.8) but terrible compilation (2.0) — understanding requirements ≠ producing working code
- Action RPGs exposed the biggest gap between models due to interdependent systems (inventory, combat, progression)
- Platformers had the smallest gap since platformer patterns are well-represented in training data

### Limitations

- Small scale: 57 GDDs, 3 evaluators, 3 game genres
- No multimodal understanding of diagrams/concept art within GDDs
- No runtime performance evaluation of generated code
- Model deployed via Colab + ngrok — not production-ready infrastructure

## GDD Generation for Hyper-Casual Games Using Large Language Models: A Comparative Evaluation

Venue: BEU Fen Bilimleri Dergisi (Bitlis Eren University Journal of Science), Vol. 14, Issue 3, 2025
Authors: Muhammet Emin Aydinalp, Buket Doğan, Abdullah Bal — Istanbul Sabahattin Zaim University / Marmara University, Türkiye
DOI: 10.17798/bitlisfen.1664312

### Core Contribution

Compares a human-expert-written GDD with an LLM-generated GDD (ChatGPT-4) for the hyper-casual game "Pool Wars". Four domain experts blindly scored both documents on 8 criteria using a 5-point Likert scale. The LLM GDD scored 4.71/5 overall vs. 3.29/5 for the human GDD, with lower standard deviation (0.23 vs. 0.36).

### Prompt Engineering Strategy

Three complementary techniques were used to generate the LLM GDD:

1. Step-by-step instructions — divided the GDD into sections (game summary, basic mechanics, level system, design elements, game economy) and prompted each separately, then combined
2. Example-supported prompts — fed sample GDDs from similar games to guide structure and content
3. Role-playing prompts — "You are a game designer" persona to produce more user-focused, target-audience-aware output

Visual assets were generated with Google's ImageFX (text-to-image).

### Evaluation Criteria and Results

| Criteria | Human GDD | LLM GDD | Difference |
| --- | --- | --- | --- |
| Completeness | 3.67 | 4.67 | +1.00 |
| Clarity | 3.33 | 5.00 | +1.67 |
| Consistency | 3.00 | 4.67 | +1.67 |
| Creativity & Innovation | 4.00 | 4.00 | 0.00 |
| Practicality | 3.00 | 5.00 | +2.00 |
| Level of Detail | 2.67 | 5.00 | +2.33 |
| User-Centric Approach | 3.00 | 5.00 | +2.00 |
| Visual Adequacy | 3.67 | 4.33 | +0.66 |

Largest gaps: Level of Detail (+2.33), Practicality (+2.00), User-Centric (+2.00). No gap: Creativity & Innovation (tied at 4.00). Smallest gap: Visual Adequacy (+0.66).

### What Is NOT Measured

- No time/cost comparison between human and LLM GDD production
- Only one game (Pool Wars), only one genre (hyper-casual), only one LLM (ChatGPT-4 free tier)
- Only 4 evaluators — too few for statistical significance tests
- Creativity tie at 4.00 may reflect a ceiling effect (both scored "good") rather than genuine parity
- Evaluators scored the final documents, not the process — no insight into iteration effort or prompt refinement cycles
- Used free-tier GPT-4 with session interruptions, requiring manual merging across sessions — a paid API would likely yield more consistent output
- No downstream validation: the GDD was never used to actually build the game, so "practicality" is expert opinion, not empirical

### Risks Identified by Authors

- LLMs can introduce conflicting mechanics or technically impossible features across sections
- Over-reliance on LLMs may reduce originality over time
- Copyright/ownership of LLM-generated text is unresolved for commercial use
- Human expert oversight at each step remains essential

### Relevance to My Research

This paper is directly citable as evidence for the "documentation quality" axis:

| Dimension | This paper | My work |
| --- | --- | --- |
| Direction | LLM generates GDD from prompts | LLM extracts knowledge from existing GDDs |
| Game scope | Single hyper-casual game | Multiple slot/casino games with mathematical specs |
| Evaluation | Expert Likert scoring of document quality | Downstream utility (retrieval, competitive analysis, spec incubation) |

The 4.71 vs. 3.29 result supports the claim that LLMs handle structured documentation well — but this paper evaluates GDD generation (writing), not GDD comprehension (reading/extracting). My work requires the inverse capability: can LLMs accurately extract and structure knowledge from existing GDDs? The quality gap this paper demonstrates is encouraging but not directly transferable.

The 8-criterion evaluation framework (completeness, clarity, consistency, creativity, practicality, detail, user-centric, visual adequacy) could be adapted for evaluating extracted knowledge quality, with modifications: replacing "creativity" with "extraction accuracy" and "visual adequacy" with "structural fidelity to source."

## GameGoogle: A Search Engine for Mechanics in Video Games

Venue: AIIDE 2025 (Twenty-First AAAI Conference on Artificial Intelligence and Interactive Digital Entertainment)
Authors: Brooke Szajda, M Charity — University of Richmond

[LittleBigPlanet 2 Story Mode - Basketball](https://youtu.be/AvyW0J94geE?t=11)
[Thief Gold - Playing Basketball in the Tutorial (Easter Egg)](https://youtu.be/v8YbhZ9sWXw?t=170)

### Core Contribution

A prototype search engine (GG) that searches within a game's entire gameplay space for specific mechanics, not just by genre or title. Example: searching "basketball" returns not only NBA 2K but also LittleBigPlanet (basketball minigame) and Thief: The Dark Project (basketball easter egg).

### System Architecture

- Dataset: ~4,500 game entries, top 50 rated games per year from 1975–2025 (sourced from GlitchWave.com)
- Text sources: game manuals, walkthroughs, guides from Vimm's Lair, IGN, GameFAQs, Steam Community
- Tokenized using NLTK and SpaCy, extracting only nouns and verbs
- MySQL database with two tables: `gameData` (game info) and `inverseGameWords` (inverted index)
- Hosted on AWS, web frontend with multiple ranking/filter options

### Ranking Formula

`R_i = 0.5(K_i) + 0.2(T_i) + 0.15(G_i) + 0.15(A_i)`

- `K_i`: keyword frequency ratio (query keywords / total words for that game)
- `T_i`: title match percentage
- `G_i`: genre match percentage
- `A_i`: tag match percentage

### Evaluation

- Metric: nDCG@20 (Normalized Discounted Cumulative Gain, top 20 results)
- nDCG meaning: 1.0 = perfect alignment with user expectations, 0.0 = no expected games in top 20
- Ground truth: 60 participants named first game they associated with each of 16 words
- 16 query words: bike, block, castle, city, dice, dog, dungeon, farm, fire, ghost, horse, pizza, puzzle, school, spy, sword
- Random baseline scored 0 across all terms
- Best: `dungeon` and `ghost` (~0.5), worst: `fire` (0, verb/noun ambiguity — "press to fire" dominated older game manuals)
- Most terms landed in the 0.1–0.3 range

### What Is NOT Measured

- No comparison between ranking filters (default vs. exact match vs. date/rating)
- No ablation on ranking formula weights
- No precision/recall or MAP — only nDCG@20
- No comparison against existing systems (IGDB, MobyGames, etc.)
- No dataset coverage statistics
- The nDCG metric only measures whether GG surfaces games users already know — it does NOT evaluate GG's stated core purpose of discovering obscure/hidden mechanics

### Relevance to My Research

Structural parallel: both approaches use natural language text artifacts that describe gameplay as the basis for retrieval/matching, rather than playing or observing the game directly.

| Dimension | GameGoogle | My work |
| --- | --- | --- |
| Source text | Walkthroughs, manuals, community guides (post-release, user-generated) | Game Design Documents (pre-release, authorial intent) |
| Who wrote it | Players and community | Designers |
| Stage in game lifecycle | After ship | Before ship |
| Vocabulary | Casual player language | Domain jargon, tacit knowledge |

If GDD-extracted knowledge were merged into GG's database, the expected nDCG improvement would be minimal (~0.02–0.08) because: (1) the evaluation ground truth comes from player associations, not designer intent; (2) GDD jargon rarely overlaps with casual query vocabulary; (3) the bottleneck is ranking algorithm issues, not data coverage; (4) well-known games already have thorough walkthroughs, so GDD adds redundant keywords.

However, the real value of GDD extraction lies in a dimension GG's current metric cannot capture — finding obscure mechanics that no walkthrough documents. This is qualitatively complementary, not quantitatively better on their metric.

## Digital Game Development Using Large Language Models (LLMs): An Exploratory Study

Venue: SBGames 2025 (XIV Simpósio Brasileiro de Jogos e Entretenimento Digital), Salvador/BA
Authors: Cristiano Barroso Serra, Gabriel Mattos Barroso Serra, Tadeu Moreira de Classe — UNIRIO / UVA, Brazil

### Core Contribution

Proposes PromptingGameCraft (PGC), a pipeline that takes a human-written Game Design Document (GDD) as input and automatically generates:

1. A Game Design File (GDF) — structured JSON formalizing all mechanics and interactions
2. A class diagram — using a custom notation (not standard UML)
3. A directory/file structure
4. Game source code (JavaScript via the Phaser framework)

Backend: DeepSeek-Reasoner model API on Google Cloud + Python web server.

### Pipeline (4 Phases)

| Phase | Output |
| --- | --- |
| Design Input | GDD artifact |
| Semantic Interpretation | Game semantic model |
| Architectural Inference | Architectural blueprint |
| Scaffold Instantiation | System scaffold + executable code |

Four prompt functions drive each phase: `Prompt_GDF`, `Prompt_Pattern`, `Prompt_Structure`, `Prompt_Code`.

### GDF — The Key Intermediary Artifact

The GDF sits between design intent and code. It organizes interactions into three categories: game descriptions, system interactions, and game interactions. Each interaction has structured fields: `id`, `name`, `type`, `description`, `parameters`, `next`. This pre-formalization acts as a semantic control layer that reduces context inconsistency in LLM generation.

### Proof of Concept: Basket Catch Game

A 2D ball-catching game was built entirely from PGC outputs. Only 1% code variation after manual fixes — the only intervention needed was adding `.js` extensions to import paths (ECMAScript module syntax issue). Structured prompt architecture scored 9.5/10 vs. 6.25/10 for single-shot baseline (evaluated independently by GPT-o3).

### Critical Limitations Noted in Discussion

- No before/after human effort comparison. The paper provides zero data on person-months, development hours, or cost savings comparing PGC vs. traditional development. It cannot be cited as evidence for productivity gains.
- The "before/after" in Table 9 compares *raw LLM output* vs. *manually adjusted code* — both within PGC. It is not a comparison against traditional workflows.
- Output quality is tightly coupled to GDD quality — garbage in, garbage out.
- Manual intervention still needed for asset integration and engine-specific adjustments.
- Currently supports only single-game, single-engine (Phaser) workflows.

### What This Paper Is (and Is Not)

Is: A proof-of-concept that GDD → structured intermediate (GDF) → code automation *works*, with structured prompting significantly outperforming single-shot generation.

Is not: A controlled experiment measuring efficiency, effort reduction, or cost savings compared to traditional development.

### Relevance to Research

- Provides a concrete GDD → GDF → class diagram → code pipeline architecture to reference.
- The GDF concept (structured intermediate representation) is a useful design pattern for knowledge extraction systems.
- Empirical evidence that structured multi-stage prompting (9.5) is superior to single-shot (6.25) supports the argument for pipeline-based prompt architecture.
- Cannot support claims about time/effort savings — such evidence must come from other sources (e.g., Hassan et al. on Unity template generation, cited in Consensus lit review).

# Mar 28, 2026

## Deep Lit Review of Consensus get better results

Using LLM to conduct better prompts(questions) about my concepts, then put them all together to the Deep Lit(erature) Review mode:

![](images/Users/zhounaihong/Documents/project/rwf/wiki/20260328214131.png)

We can get *much, much better* results than traditional search results. But, what are essential differences between traditonal search and literature review?

A search is a *retrieval* process. It is the act of looking for specific documents or data points using keywords, filters, and databases. The goal is to find relevant items. It is often a technical step where you try to get a list of results that match your criteria. Think of it as *gathering the raw materials* for your work.

A literature review is a **synthesis** process. It is the act of *reading, evaluating, and connecting the items* you found during your search. The goal is to provide a comprehensive overview of a topic. It involves critical thinking to explain how different studies compare, where they disagree, and what is currently missing from the field. *It turns those raw materials into a structured narrative*.

### Lit Review

[How does the automated extraction of knowledge from Game Design Documents (GDD) using Large Language Models improve game development efficiency and knowledge reuse? What are the measurable benefits of semantic search over keyword-based search for retrieving game mechanics and mathematical specifications from game design documentation?](https://consensus.app/search/game-design-document-knowledge-extraction/T2FunD2NSuqZgCcG0-IFKA/?utm_source=share&utm_medium=clipboard)

#### LLM Extraction from GDDs: Efficiency & Knowledge Reuse

##### Pipeline benefits

- Tools that parse GDDs and generate structured specs (JSON/GDF), class diagrams, and starter code significantly reduce manual translation from design to implementation, improving *transition speed, modularity, and reusability* [1](https://consensus.app/papers/digital-game-development-using-large-language-models-llms-serra-serra/a85830304d3d51c0aa2d6c11bfbd5d6c/?search_id=r9ddrY7ZRMeQlr52mIUYsQ)[5](https://consensus.app/papers/automated-unity-game-template-generation-from-gdds-via-nlp-hassan/aada41802a2a55b6ad2bb72351534387/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).
- Automated Unity template generation from GDDs shows higher scores than baseline LLMs on *compilation success, adherence to GDD, and code modularity (≈4.8/5)*, directly cutting prototyping time and making specs more consistently reusable across genres [5](https://consensus.app/papers/automated-unity-game-template-generation-from-gdds-via-nlp-hassan/aada41802a2a55b6ad2bb72351534387/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).
- LLM‑generated GDDs can be *clearer and more detailed* than expert-written ones (overall 4.71/5 vs. 3.29/5 on expert ratings), which supports downstream automation and cross‑team understanding [4](https://consensus.app/papers/gdd-generation-for-hypercasual-games-using-large-language-aydinalp-do%C4%9Fan/bf30b8c2a9cc526ab2b0677d7edbe46e/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).
- Knowledge-graph–enhanced LLM frameworks accumulate structured game knowledge across versions and use it to target playtests more efficiently, reducing test steps for incremental updates [12](https://consensus.app/papers/knowledge-graphenhanced-large-language-model-for-mu-cai/7bfe7e73cd345e2c8677dd00038175b0/?search_id=r9ddrY7ZRMeQlr52mIUYsQ). This illustrates how extracted knowledge supports *incremental reuse* at scale.

##### Example Impacts

| Aspect | Reported Effect | Citations |
| --- | --- | --- |
| Design→code time | Faster pipeline, automated boilerplate/template generation | [1](https://consensus.app/papers/digital-game-development-using-large-language-models-llms-serra-serra/a85830304d3d51c0aa2d6c11bfbd5d6c/?search_id=r9ddrY7ZRMeQlr52mIUYsQ)[5](https://consensus.app/papers/automated-unity-game-template-generation-from-gdds-via-nlp-hassan/aada41802a2a55b6ad2bb72351534387/?search_id=r9ddrY7ZRMeQlr52mIUYsQ) |
| Consistency/modularity | Higher modularity, better alignment with GDD | [1](https://consensus.app/papers/digital-game-development-using-large-language-models-llms-serra-serra/a85830304d3d51c0aa2d6c11bfbd5d6c/?search_id=r9ddrY7ZRMeQlr52mIUYsQ)[5](https://consensus.app/papers/automated-unity-game-template-generation-from-gdds-via-nlp-hassan/aada41802a2a55b6ad2bb72351534387/?search_id=r9ddrY7ZRMeQlr52mIUYsQ) |
| Documentation quality | Higher clarity/detail ratings for LLM GDDs | [4](https://consensus.app/papers/gdd-generation-for-hypercasual-games-using-large-language-aydinalp-do%C4%9Fan/bf30b8c2a9cc526ab2b0677d7edbe46e/?search_id=r9ddrY7ZRMeQlr52mIUYsQ) |
| Testing effort | Fewer steps to cover impacted features via KG+LLM | [12](https://consensus.app/papers/knowledge-graphenhanced-large-language-model-for-mu-cai/7bfe7e73cd345e2c8677dd00038175b0/?search_id=r9ddrY7ZRMeQlr52mIUYsQ) |

Figure 1 Effects of LLM-based GDD extraction on pipeline quality and reuse.

#### Semantic vs. Keyword Search for Mechanics & Math Specs

Direct comparisons in games are scarce, but related work in *semantic models and math embeddings* shows measurable gains:

-   Distributional/semantic similarity metrics predict *faster and more accurate semantic retrieval* in complex word-game search tasks than simpler baselines, suggesting better alignment with human conceptual search [2](https://consensus.app/papers/semantic-memory-search-and-retrieval-in-a-novel-kumar-steyvers/6e86131633ce5c888678d1b01a53b40a/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).
-   Math-word embeddings improve *math-term similarity and search via query expansion*, outperforming purely lexical matching in retrieving relevant mathematical concepts and expressions [16](https://consensus.app/papers/mathword-embedding-in-math-search-and-semantic-extraction-greiner-petter-youssef/ba09fbb1e2a754a4bc4fa973a7a283ed/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).
-   Semantic-web and crowdsourced game-based approaches show that semantic term networks enable *more precise exploratory and facet-like search* than keyword-only engines [6](https://consensus.app/papers/data-linking-for-the-semantic-web-systems-%C5%A1imko/96573f393dce5d1daeda9ac3775e714f/?search_id=r9ddrY7ZRMeQlr52mIUYsQ)[9](https://consensus.app/papers/semantics-discovery-via-human-computation-games-simko-tvarozek/ac0ca415c1c75297b9a9e7bab1c77ee6/?search_id=r9ddrY7ZRMeQlr52mIUYsQ)[19](https://consensus.app/papers/building-a-semantic-search-engine-with-games-and-wieser/10dcffbe9727504db2ea923f88d0b2c9/?search_id=r9ddrY7ZRMeQlr52mIUYsQ).

Applied to GDDs, these results imply that embedding-based semantic search should:

-   Retrieve mechanics described with different wording (e.g., “lock-on targeting” vs. “auto-aim”).
-   Match math specs by conceptual role (e.g., “Elo‑like progression” even if formula differs).
-   Reduce missed results and noisy hits compared to keyword search, especially in heterogeneous, informal GDDs.

#### Conclusion

Current evidence shows that LLM-based extraction and structuring of GDDs can measurably improve development efficiency, modularity, and cross-version knowledge reuse, while semantic/embedding-based search offers clear advantages over keyword search for retrieving conceptually defined mechanics and mathematical specifications. Empirical head‑to‑head evaluations on real GDD corpora remain an open research opportunity.

[Digital Game Development Using Large Language Models (LLMs): An Exploratory Study](https://sol.sbc.org.br/index.php/sbgames/article/view/37365)

[GameGoogle: A Search Engine for Mechanics in Video Games](https://ojs.aaai.org/index.php/AIIDE/article/view/36847)

[GDD Generation for Hyper-Casual Games Using Large Language Models: A Comparative Evaluation](https://dergipark.org.tr/en/pub/bitlisfen/article/1664312)

[Automated Unity Game Template Generation from GDDs via NLP and Multi-Modal LLMs](https://arxiv.org/abs/2509.08847)

[Grammar-Based Game Description Generation Using Large Language Models](https://ieeexplore.ieee.org/document/10807354)

[Large Language Models and Video Games: A Preliminary Scoping Review](https://dl.acm.org/doi/10.1145/3640794.3665582)

[Game Generation via Large Language Models](https://ieeexplore.ieee.org/document/10645597)

# 2026-03-22

## 論文新方向的思考

上次跟老師的會議中，戴老師提到的問題就是我的題目實在過於工程導向，但卻又沒有足夠多的數據做為支撐。做為EMRD學程的論文，以「技術長」為養成角色的核心目標而言，論文還是應該以策略為導向。舉例來說，如果透過我的論文的研究，有足夠的理論或是數據可以佐證，這個策略能為公司帶來夠大的效益，這才是「技術長」真正的價值。

當然，或許我們會覺得沒有”實測”為準，怎麼會知道實際落地的時候會遭遇什麼樣的困難，是不是真的可行？但做為技術長本來就應該要在最小的成本的前提下，獲得最有可信度的決策依據。全數據推論的決策是有風險，但全實驗的決策未嘗不是一種風險？在投入資源驗證之後才發現不可行，所承受的風險就是機會成本的喪失，風險不一定會比較小。

整個論文的題目是定調為「將規格書知識化後帶來的效益」。除了可以用自然語言檢索以外，更進一步可以做到競品比較，新規格重組孵化，遊戲素材甚至是雛型的生成。原來的題目提的是「利用生成式人工智慧技術從遊戲設計規格書進行知識萃取」，那新的題目呢(如果可以改的話)？

新的題目是「**利用生成式人工智慧技術最大化遊戲規格書價值的策略**」，所以整個架構中提到知識管理和知識萃取的部分應該都不用動，重點比較像是後續「最大化效益」的延伸。

首先是*檢索的效益提升*。單純的搜尋並不能體現其價值，多條件式組合的檢索才是知識庫化的優勢。例如，如果要找的是「遊戲中的倍率分布是怎麼樣的？」或是「中了75倍線獎時是播哪個音效，是迴圈播放嗎？」這類需要推論或複合條件的檢索，才是語料化(Textualization)的優勢。這個優勢會在2個以上的遊戲時體現的更明顯，像是A，B兩個遊戲中有共用音效嗎？Free Game進入條件有什麼差別？我們有多少遊戲的最大倍數超過500倍的等這樣的多遊戲及多條件的複合檢索，正是語料化的最大優勢。

再來是論文中提到僅依靠畫面截圖，配合適當提詞，生成遊戲規格的這個過程，可一定程度上輔助「競品分析」需求。因為競品分析很大程度就是規格上的比較，也就是前一個主題中「檢索優化」中帶來的直接效益。隨著LLM的多模態能力持續成熟，影片分析的能力越來越好，在取得競品規格的準確度及成本都會持續下降。本來編導需要針對影片(不論是原廠放出來的或是直接現場錄製回來的)做人工的理解，再用自己的話寫出來，再做簡報同步給所有人，透過AI的技術成熟，這個過程的成本會大幅降低，將競品的規格給語料化，就能更大程度的享受到透過自然語言做競品分析的效率。例如：

1. 畫面截圖 + 提詞生成規格輔助競品分析：
  - 案例： 某遊戲策劃人員想分析競品A中的「技能樹系統」。他可以對遊戲中技能樹的介面進行多張截圖，並搭配「請根據這些截圖，詳細列出技能樹的層級結構、解鎖條件、技能效果和數值」等提詞。LLM隨後可生成結構化的規格文件，直接用於與自家產品的規格進行比較。  
  - 效益： 省去人工逐一記錄技能樹細節的時間，提高了規格比較的效率和準確性。
2. 多模態影片分析優化競品規格檢索：
  - 案例： 某發行商需要快速掌握競品B的「新手教學流程」和「戰鬥系統操作」。他們可以將競品B的遊玩錄製影片（或官方釋出的教學影片）輸入給具備影片分析能力的LLM。  
  - 提詞： 「請分析此影片，產出詳細的新手教學步驟、操作提示文字，以及戰鬥中每個按鈕的功能和連招組合。」  
  - 效益： LLM自動將影片內容「語料化」，產出標準化的文字規格，取代了編導/策劃人員必須耗費數小時觀看、理解、手動撰寫筆記和簡報的過程，大幅降低了資訊獲取的成本。
3. 語料化規格輔助自然語言競品分析：
  - 案例： 透過上述兩種方式，團隊已經累積了數個競品的規格語料庫（例如，所有競品的付費設計、英雄養成系統、社交功能等都被結構化為文字）。  
  - 進一步提問： 策劃人員可以直接向語料庫提問：「在所有競品中，有哪些遊戲的『付費禮包』設計包含了『限時』和『隨機寶箱』兩種機制？它們的價格區間如何？」  
  - 效益： 相比於人工翻閱多份規格文件，透過自然語言直接查詢，競品分析的速度和深度都得到提升，能更快地從大量數據中找出特定規律或設計趨勢。

繼續延伸出來的是新規格的重組孵化。在擁有足夠多的規格語料之後，對於不同的市場及產品偏好，我們就可以讓AI來生成比較受歡迎的規格。如果我們要針對既有的市場推出新產品，AI雖然已有該市場的喜好資料，但在新規格中是否也可以加入和其他市場類似，甚至是重疊的部分？那為什麼他們會有類似的規格？是不是它們是基於更底層的需求才演變出相似的規格？僅管這可能不是規格書上直接會標註上去的內容，但實際上這可以是AI重組孵化的部分。最後是從*基於這份規格的素材或是雛型生成*。和單純僅依靠一次性的提詞生成截然不同，AI此時此刻的生成已經可說是「有憑有據」。圖像或影片都是這個市場的風格偏好，軟體是符合公司既有框架的源碼片段，完成度自然距離產品是更近的。例如：

1. 素材或雛型生成 (Asset/Prototype Generation)

- 案例情境： 遊戲美術團隊需要為一個以「北歐神話」為主題、具有「高波動性」規格的角子機遊戲快速生成視覺概念。  
- 提詞/生成結果： 「基於[北歐神話主題]規格書中定義的『主神Odin』符號視覺風格，生成一套帶有閃電和符文特效的動畫序列（3秒循環）。同時，生成符合此規格定義的『免費遊戲大廳』的基礎程式碼片段（C# Unity）。」  
- 價值/佐證策略： 有憑有據的生成。 AI生成的圖像和代碼片段直接繼承自知識庫中已驗證的規格、風格偏好和技術標準。美術人員無需重新設計風格，工程師得到符合公司架構的模組化代碼，大幅縮短概念驗證和初期開發時間。

1. 競品分析 (Competitive Analysis)

- 案例情境： 產品經理希望將競品C中一個成功的「特殊圖案收集機制」應用到新遊戲。  
- 提詞/生成結果： 「在所有已語料化的[亞洲市場角子機]規格中，找出所有包含『特殊圖案收集條』機制的遊戲。比較它們的收集門檻、獎勵類型，以及在規格書中標註的玩家回饋曲線（RTP Segment）。」  
- 價值/佐證策略： 效率和深度提升。 相比於人工翻閱數十份PDF，自然語言檢索能在數秒內從海量數據中提取出高度結構化的比較結果。這證明了「將規格書知識化」能直接轉化為市場策略洞察的效率。

1. 新規格重組孵化 (New Specification Incubation)

- 案例情境： 策劃團隊正在為進入「拉丁美洲」市場設計一款新品，需要結合當地偏好（例如，喜愛嘉年華風格）與公司既有的成功機制（例如，多層堆疊符號）。  
- 提詞/生成結果： 「分析[拉丁美洲市場偏好]語料與[公司成功遊戲]語料的相似性。生成一套結合『嘉年華視覺主題』和『連鎖反應疊加獎勵』的數學規格草案。特別說明該規格在『最大賠付倍數』上的設計策略。」  
- 價值/佐證策略： 策略導向的創新。 AI的重組不是隨機生成，而是基於兩種不同來源的知識進行推論（例如，找到兩種市場對"慶典"和"高互動性"的底層需求），確保新規格在滿足創新性的同時，具備市場接受度和成功基礎。

## 要找什麼資料？

遊戲規格書（Game Design Document, GDD）與一般的軟體規格書在結構與目的上有很大的不同。GDD 包含了大量的美術風格描述、數值邏輯（如 RTP 計算）、玩家心理預期以及敘事流程，這類資訊的語意模糊性比純技術規格更高，因此語意搜尋的效益會更明顯。

以下是我為你整理，針對 Consensus 服務在遊戲規格書領域的精準搜尋策略：

### 為什麼遊戲規格書需要更精準的語意搜尋？（我已知的部分）

1. 跨媒介的知識特質： GDD 經常混合了文字說明、數值公式與美術參考。傳統搜尋難以理解「類似 Odin 風格的特效」或「高波動性的數值設計」這種模糊概念，但語意搜尋可以透過向量空間找到概念相近的設計。
2. 邏輯鏈條的複雜性： 遊戲中的一個機制（如 Free Game 觸發條件）會影響到多個檔案。語意搜尋能幫技術長在評估改動時，快速找出所有受影響的設計邏輯，這在軟體開發中稱為 Impact Analysis，但在遊戲業中更偏向「遊戲平衡與體驗的一致性」。

### 針對 Consensus 的精準提詞 (Prompt) 建議

在使用 Consensus 時，建議直接鎖定 Game Design 或 Game Development 領域，並嘗試以下提詞：

1. 針對開發效率與知識重用： How does the automated extraction of knowledge from Game Design Documents (GDD) using Large Language Models improve game development efficiency and knowledge reuse?
2. 針對語意搜尋的優勢比較： What are the measurable benefits of semantic search over keyword-based search for retrieving game mechanics and mathematical specifications from game design documentation?
3. 針對決策支撐與市場競爭力： Does AI-driven analysis of competitive game design specifications lead to better strategic decision-making and lower market research costs in the gaming industry?

### 設定搜尋脈絡與目標

1. 設定脈絡 (Context)： 在 Consensus 的進階過濾器中，建議將 Domain 鎖定在 Computer Science 或 Art & Design。雖然遊戲規格書偏技術，但很多關於「設計方法論」的論文會落在藝術設計類別中。
2. 設定目標 (Objective)： 你的目標是尋找「量化數據」。例如：搜尋時間（Search Time）、錯誤率（Error Rate）、或是對機制理解的準確度（Comprehension Accuracy）。這些數據能直接支持你題目中「最大化價值」的說法。

### 搜尋結果

Consensus[沒有直接結果](https://consensus.app/search/semantic-search-vs-keyword-search/0viSRw8lR_er-XUDem2qvQ/)，

### 整理給老師的論文修改方向

老師好，我這邊針對上次會議的內容，訂出以下的修訂方向：

1. 題目與主軸

- 原方向：利用生成式 AI「從遊戲設計規格書進行知識萃取」。
- 調整後：**利用生成式人工智慧技術最大化遊戲規格書價值的策略**。
- 意涵：知識管理與知識萃取仍是基礎；敘事重心改為下游的效益延伸與價值極大化，而不只停留在「把知識從文件裡取出來」。

1. 可維持不變的部分

- 知識管理與知識萃取／語料化的架構不必大改，它們支撐後續所有應用。

1. 新增強調：四條效益軸線


| 軸線           | 一句話摘要                                                                 |
| ------------ | --------------------------------------------------------------------- |
| 多條件檢索        | 價值不在「能搜」，而在可推論、可組合條件的檢索（倍率分布、音效是否迴圈、跨遊戲比對等）。語料庫中遊戲數量愈多（例如兩款以上），優勢愈明顯。 |
| 競品分析         | 截圖＋提詞產出結構化規格；隨多模態成熟，影片成為輸入；在競品語料庫上以自然語言做模式與趨勢查詢（例如付費設計、價格區間）。         |
| 新規格重組孵化      | 累積足夠規格語料後，依市場與產品偏好生成較受歡迎的規格；可延伸討論跨市場相似性與更底層需求如何支撐重組，而不只是表層抄規格。        |
| 有憑有據的素材／雛型生成 | 生成錨定在規格書、市場風格、公司框架（「有憑有據」），有別於一次性空泛提詞——更接近可落地的圖像、影片與程式片段。             |


1. 給讀者的一條故事線

- 流程：規格語料化 → 檢索與比較（含競品）→ 重組孵化新規格 → 依該知識繼承式地生成素材與雛型。
- 論點：生成式 AI 是槓桿；價值極大化要透過上述四種用法來論證，而不只論證萃取是否準確。

---

看老師你覺得如何，有沒有需要修整的部分？同時間我會開始搜尋相關的論文，如果有不錯的內容，再同步給老師，謝謝～