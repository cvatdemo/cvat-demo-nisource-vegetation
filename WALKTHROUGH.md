# Walkthrough: NiSource demo on open-source CVAT

A self-guided tour of the same flow you saw in the demo, on your own machine. Open `clickthrough.html` next to this file to see each screen as it looked in CVAT Online.

Each step is marked **Free** (works in open-source CVAT) or **CVAT Online** (a paid feature, shown in the click-through only). Run `bash start.sh` first (or `bash scripts/setup.sh` and `bash scripts/restore.sh`); the links below are printed by `restore.sh` and saved in `demo/local-urls.txt`.

## a. Connects to your architecture

1. **Attach cloud storage** (Free). You run gas and electric, and you manage vegetation around both. The aerial tiles of your rights-of-way and your line corridors stay in your own cloud bucket, on AWS, Azure or Google Cloud, and CVAT reads them in place. Nothing is copied into a new system, and you can cut access at any time.
   - Try it: open Cloud Storages in the top bar and click the plus button to see the form.
2. **Projects** (Free). Each use case gets its own project. Vegetation management is one. If you later split the work another way, or add a new use case, that is a new project with its own labels and rules.
3. **NiSource project** (Free). Everything for this use case lives here, the labels, the imagery and the quality rules. Data and labels go in and out from the Actions menu, so this sits between your imagery and your model and fits around the tools your team already uses.
   - Try it: open the `project` link from `demo/local-urls.txt`.
4. **Project actions** (Free). Import brings in any labels you already have, so earlier work is not lost. Export sends finished labels out in the format your training code expects. Nothing changes on your side: your imagery in, your training format out.
5. **Export formats** (Free). These are the standard formats, such as COCO and YOLO, so your training code uses the export directly with no conversion step. Your engineers can do the same from the API, the Python SDK or the command line, inside your own pipeline.
   - Try it: Actions, Export dataset, then open the format list.

## b. Project setup

6. **Labels set once** (Free). Here is your question written as labels: one vegetation polygon to outline the canopy, and a per-tile tag that records the baseline a utility cares about, is there vegetation on this tile or not. You set them once here, and every batch inherits them, so every annotator works to the same definitions.
7. **The per-tile baseline** (Free). It records one decision for the whole tile, vegetation or clear. That is the baseline before any outline, the question your crews start from. Changing its options later is one edit here.
   - Try it: click the pencil on the tile_baseline label, look, then Cancel.
8. **The batches** (Free). Tiles come in as batches, called tasks. Each one inherits the labels we just saw. Here is one batch, ready to work on.

## c. Automatic annotation

9. **A batch of 100 tiles** (Free). There are 100 aerial tiles here, split into jobs of 25 so several people can work at the same time. The answer key mixes leaf-on and leaf-off tiles, because your crews work year round.
10. **Task actions** (Free). Before anyone draws anything, a model takes the first pass over the whole batch. People then correct, they don't start from a blank tile.
11. **Choose a model** (CVAT Online). First we choose which model takes the first pass over the batch.
   - On open source: not available. See this screen in `clickthrough.html`.
12. **Models you can use** (CVAT Online). Any model connected to the account shows here. Your own, one from Hugging Face, or Roboflow. For this batch we use a public tree-segmentation model as an honest first pass.
   - On open source: not available. See this screen in `clickthrough.html`.
13. **Automatic annotation** (CVAT Online). Pick a model and map what it knows to your labels. Here a public tree-segmentation model maps to your vegetation label, with no training on your data. Your own model plugs in the same way. One click and every tile in the batch gets a first pass in seconds.
   - On open source: this dialog needs models deployed with Nuclio, a separate setup. The simpler route is `scripts/auto_annotate.sh`, which runs a model on your machine and uploads its shapes.
14. **The job the model labeled** (Free). Here it is in the job list. Let's open it and see what the model did on these tiles.
15. **Model pre-labels** (Free). The model has already made its first pass. It marks where there is obviously vegetation, but it cannot delineate the canopy, and on leaf-off tiles a generic model finds almost nothing. That gap is exactly what people fill in, and exactly what the quality check measures.
   - Try it: open the `model_job` link. Press F and D to move between tiles.

## d. Human in the loop

16. **Filter by who made it** (Free). People fix what the model missed. A reviewer can show only what the model drew, or only what a person drew, and correct from there. Every shape keeps track of who made it, so you can always see what was checked and your team keeps the final say.
   - Try it: in the job, click Filters, Add rule, pick Source.
17. **Back to the batch** (Free). The question is who does the correcting at your volume.
18. **Add annotators** (CVAT Online). If you need more hands, Outsource Labeling sends the batch to CVAT's annotators. They work to the same labels and the same quality rules, alongside your own people, and NiSource keeps the final say. You do not need to staff a labeling team to get started.
   - On open source: not included. CVAT's annotators are a CVAT Online service.

## e. Quality you can measure

19. **The answer key** (Free). It is a small set of tiles, 20 here, labeled carefully once. Every job is scored against it automatically, whoever drew the labels, a model, our annotators or your team. Quality is measured, not assumed. The key mixes leaf-on and leaf-off, so the score covers the hard tiles too.
   - Try it: open the `answer_key` link.
20. **A batch an annotator calls done** (Free). Here is a job with only the model's first pass in it. Let's pretend an annotator has worked it and calls it done.
   - Try it: open the `bounce_job` link; it is a light check task that bounces in under a second.
21. **Finish the job** (Free). The annotator clicks Finish the job.
22. **Confirm finishing** (Free). because finishing hands the job over as completed work.
23. **The job bounces** (CVAT Online). It checked the job against the answer key before accepting it, and it names what is missing. The work goes back to the annotator, not on to you. For a utility, that is the point, a missed encroachment near a gas line or a conductor is caught before it reaches a crew. A bad batch never becomes training data.
   - On open source: the job completes without the check. Run `scripts/quality_report.sh` afterwards to get the same scores.
24. **Quality control** (CVAT Online). This is where you, or we, check quality at any time, not just when a job is finished.
   - On open source: not available. See this screen in `clickthrough.html`.
25. **A score for every job** (CVAT Online). Every job gets a score against the answer key. You see exactly how far a model, or a person, is from your standard before you rely on the labels. The generic model scores low here, which is the point. On your own tiles, with your own model, this is the number a pilot measures.
   - On open source: run `scripts/quality_report.sh` for the same per-job scores in the terminal. The score screens in the browser are CVAT Online.
26. **Your quality rules** (CVAT Online). These are your rules. The vegetation outline must be 80 percent right and the per-tile baseline tag 90 percent. A missed encroachment must be caught 95 percent of the time, because near a gas line or a conductor a missed one is the expensive error. You set these, and every job is held to them.
   - On open source: the rules are loaded from `demo/quality.json` by `scripts/restore.sh` and used by the report. The requirements screen itself is CVAT Online.
27. **Export for training** (Free). Once a batch passes, the checked labels export in your training format, for both the gas and the electric work. Your team, or a training partner, trains on them. CVAT does not train your model. It makes sure what you train on is right. If you later plug your own model in for the first pass, the answer key keeps checking every batch whichever model drew it.
   - Try it: on the task page: Actions, Export task dataset.

---

The photos are a public dataset, not your data: Aerial imagery from OpenAerialMap contributors, tree-crown annotations from the Restor Foundation OAM-TCD dataset (restor/tcd on Hugging Face). Licensed CC BY 4.0. Only CC-BY-4.0-licensed tiles are used.. Details in `LICENSES.md`.

