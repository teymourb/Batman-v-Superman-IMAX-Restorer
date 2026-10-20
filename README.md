# Batman-v-Superman-IMAX-Restorer
*Created by [@teymourb](https://github.com/teymourb) and [@rsquared256](https://github.com/rsquared256)*

![BvS_Poster](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/25df373b-859c-4074-b82a-663acdd5db4b)


<p align="center">
    <a href="https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases" target="_blank" rel="noopener"><img src="https://img.shields.io/github/release/teymourb/Batman-v-Superman-IMAX-Restorer.svg" alt="Latest releases" /></a>
</p>

***Batman-v-Superman-IMAX-Restorer*** is an experimental program from the fanedit community which allows you to restore your preferred IMAX version of the 4K Ultra HD Blu-Ray of *Batman v Superman: Dawn of Justice Ultimate Edition* with HDR10 (2021 Remaster).

Choose between 2 **constant-width** IMAX Restorations:
<!-- toc -->

- [1. IMAX 1.78:1 - *à la Nolan* IMAX Blu-ray discs](#1-imax-1781)
- [2. IMAX 1.43:1 (unmasked) - Mom's *We have IMAX GT 1.43:1 at home*](#2-imax-1431-unmasked)

<!-- tocstop -->

#### REQUIREMENTS:  
- An unaltered .mkv rip of the 4K Ultra HD Blu-ray disc *Batman v Superman: Dawn of Justice Ultimate Edition* (2021 Remaster)
- Published version: 160 GB of free space, excluding the source. The unreleased maintenance version retains intermediate videos and requires substantially more; peak use has not yet been measured.

> [!WARNING]
> No other version will work with this program! You are free to keep whichever audio and subtitle tracks you wish when ripping your disc. Only the video track needs to be the same.

<br>

#### INSTRUCTIONS:  
- Extract the complete application folder to a drive with room for the prepared video, raw and encoded segments, assembled video and final output. The unreleased maintenance version retains all of these; the historical free-space figure above is not its storage requirement.
- Launch *Batman-v-Superman-IMAX-Restorer.bat* and disregard the unknow publisher prompt  
- Select your source rip .mkv file when prompted  
- Select your destination folder for the output file  
- If prompted to accept or decline a command towards the end of the encoding, enter y for yes
- In the 1.0.1 maintenance candidate, a new run preserves any existing `docs/temp` folder and stops. Move that folder somewhere safe before starting a new restoration. Published 1.0.0 still uses automatic startup cleanup: recover temporary work before restarting that version.

<br>

## Original version:

On the 4K Blu-ray disc of BvS, the different types of scenes are encoded as follows:
- The video file container is 3840 x 2160 (1.78:1 / 16:9).
- The IMAX sequences have an active image of 3080 x 2160 (1.43:1) pillarboxed (*black bars right and left*) within a 3840 x 2160 (1.78:1) container.
- The Scope sequences have an active image of 3840 x 1606 (2.39:1) letterboxed (*black bars top and bottom*) within a 3840 x 2160 (1.78:1) container.

![IMAX 1 43 - variable width](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/88eb1174-3b0c-4d0b-9249-8e6eac907e47)

---

<br>
<br>



# 1. IMAX 1.78:1
> ...*à la Nolan* IMAX Blu-ray discs
  - IMAX sequences **cropped** to 3080 x 1732 (1.78:1), then
  - IMAX sequences upscaled to **3840 x 2160** (**1.78:1**)
  - Scope sequences left unaltered at active picture of **3840 x 1606** (**2.39:1**), **letterboxed** within a 3840 x 2160 (1.78:1) container
  - Picture **Constant-width**: 3840, Variable height: 2160 (IMAX 1.78:1 sequences), 1606 (Scope 2.39:1 sequences)
  - Active image: 3840 x 2160 (1.78:1)
  - **Container**: 3840 x 2160 (1.78:1)

<br>

**Best suited for 16:9 screens**

<br>

![IMAX 1 78](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/a18b611d-afda-47fe-9d22-59c31c8a7026)


<br>
<br>
<br>

---

# 2. IMAX 1.43:1 (unmasked)
> Mom's "*We have IMAX GT 1.43:1 at home*"
  - Scope sequences downscaled to **3080 x 1288** (**2.39:1**) active picture, 3080 x 1732 (1.78:1) container, then
  - Scope sequences container **windowboxed** (pillarboxed + letterboxed) to 3840 x 2160 (1.78:1)
  - IMAX sequences left unaltered at active picture of **3080 x 2160** (**1.43:1**), **pillarboxed** within a 3840 x 2160 (1.78:1) container
  - Picture Constant-width: 3080, Variable height: 2160 (IMAX 1.43:1 sequences), 1288 (Scope 2.39:1 sequences)
  - Active image: 3080 x 2160 (1.43:1)
  - **Container**: 3840 x 2160 (1.78:1)

<br>

**Best suited for:**
  - Projectors with ~1.43:1 wall/screen (or with decent masking options)
  - ~1.43:1 displays such as 4:3 TVs, tall monitors/screens (such as MacBooks)
  - Perfect for most recent iPads (1.43:1)
  - VR (if viewing app has a cropping tool or if pillarboxing won't be noticeable/distracting)  

> For MacBooks and native 4:3 projectors/displays, you should crop 380 px left and 380 px right of the image in your media player's settings (VLC, MPC...)

<br>

![IMAX 1 43](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/7d156169-9167-4aaf-824f-cd3eb833e2de)

<br>

  ---

### See also:

[Reddit | r/fanedits Restoration thread](https://www.reddit.com/r/fanedits/comments/1637r5g/batman_v_superman_dawn_of_justice_ultimate/)  
[Reddit | r/fanedits Program thread](https://www.reddit.com/r/fanedits/comments/171rpft/beta_testing_fanedit_program_batman_v_superman/)  
[fanedit.org | Forums Restoration thread](https://forums.fanedit.org/threads/batman-v-superman-dawn-of-justice-ultimate-edition-imax-1-43-1-1-78-1-restorations-4k-uhd-hdr10.29021/)


## Maintenance candidate 1.0.1 — not published

The film-processing recipe is preserved: the same cut points, crops/scaling,
HandBrake encoding settings, Avidemux section order and copy-mode assembly.
Processing tool versions are unchanged. This update improves setup, failure
handling and evidence; it does not fix legacy codec/join compatibility.

Run the BAT and select source, existing output folder, restoration mode and an
explicit check level before confirming:

- **Routine:** tool exit statuses and required nonempty outputs are checked.
  The decoded-frame assembly comparison is **NOT RUN**. This cannot establish
  pristine joins, complete picture identity, timestamps, HDR or synchronization.
- **Exhaustive:** additionally decode the assembly and ordered sections and
  compare every decoded frame's fingerprint, pixel format and geometry. This
  can take many hours. It still does not qualify intended edits, timing, HDR,
  source identity or universal player compatibility. During decoding, progress
  messages appear and the console offers Q to stop while retaining evidence.

FFmpeg does not accept accidental keyboard commands during splitting. Avidemux
runs visibly in the console so its codec-compatibility questions can be answered
explicitly. A warning remains unresolved even if you choose to continue. Full
Avidemux diagnostics appear in the console; processing.log records its stage and
status, not a complete assembly transcript. Other processing diagnostics and
validation reports remain in docs/temp; final mux logs are in final-remux.log.

Tool failures or missing/empty outputs stop the job. The bundled Avidemux may
return success after an incomplete save, so routine checks alone cannot prove
assembly completeness. Check the selected level and assembly-check.txt; a NOT RUN
record is never a PASS. Final completion still requests review and retains work.

All intermediates remain, including after final output creation. Prepared video,
raw/encoded sections, assembly and output may coexist; free-space figures are
not a guarantee the job fits. There is no automatic resume or cleanup. A new run
refuses an existing docs/temp or output. Keep completed encodes/logs after errors.

Dialogs support cancel, manual path entry and quit. Spaces, Unicode, ampersands,
brackets and parentheses are supported. Legacy batch paths containing !, %, ^,
embedded quotes or control characters are rejected with guidance.
Published 1.0.0 downloads remain unchanged. No source fingerprint registry or
new encoding/join engine is introduced. Local source-only candidates require a
separate complete trusted historical installation; they contain no tools/media.
