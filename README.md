# Batman-v-Superman-IMAX-Restorer
*Created by [@teymourb](https://github.com/teymourb) and [@rsquared256](https://github.com/rsquared256)*

![BvS_Poster](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/25df373b-859c-4074-b82a-663acdd5db4b)


<p align="center">
    <a href="https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases" target="_blank" rel="noopener"><img src="https://img.shields.io/github/release/teymourb/Batman-v-Superman-IMAX-Restorer.svg" alt="Latest releases" /></a>
</p>

***Batman-v-Superman-IMAX-Restorer*** is an experimental program from the fanedit community which allows you to restore your preferred IMAX version of the 4K Ultra HD Blu-Ray of *Batman v Superman: Dawn of Justice Ultimate Edition* with HDR10 (2021 Remaster).

Choose between two **constant-width** IMAX restorations:

- [IMAX 1.78:1](#1-imax-1781): IMAX scenes are vertically centre-cropped and upscaled; suited to 16:9 screens.
- [IMAX 1.43:1 (unmasked)](#2-imax-1431-unmasked): IMAX scenes retain their full height; Scope scenes are downscaled and windowboxed.

## Requirements

- Windows with Windows PowerShell 5.1 and its standard file/folder dialogs.
- An unaltered `.mkv` rip of *Batman v Superman: Dawn of Justice Ultimate Edition*, 4K Ultra HD Blu-ray, **2021 Remaster**.
- Enough free space for a temporary extracted video track, the restoration's working videos and the final MKV. Several film-sized files may coexist during processing; the displayed free space is not a guarantee that the run will fit.

> [!WARNING]
> No other version of the movie will work. Only the video track must match the supported disc; you may keep whichever audio and subtitle tracks you wish in your rip.

The program checks the video track before restoration and stops if it does not
match. This check reads and temporarily extracts the video without re-encoding
it. Your original MKV is unchanged.

## Download and run

1. Download the **complete application ZIP** from [Releases](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases). GitHub's automatically generated **Source code** archives do not include the processing tools.
2. Extract the entire ZIP to its own folder on a drive with sufficient free space. Do not run the program from inside the ZIP. Keep your source MKV outside the application folder.
3. Double-click **`Batman-v-Superman-IMAX-Restorer.bat`**.
4. Read the source requirements, then press Enter to open the source-file dialog. Choose your MKV.
5. Press Enter to open the destination-folder dialog. Choose an existing folder for the restored MKV.
6. Choose restoration **1** or **2**, review the paths, restoration and storage information, then enter **Y** to begin. Enter **N** or **Q** to cancel.
7. Keep the program window open and your PC awake. Encoding can take several hours. Progress messages identify the current stage; a quiet window does not necessarily mean processing has stopped.

If a file/folder dialog is cancelled or unavailable, you can enter the full path
manually or quit. Paths with spaces and Unicode characters are supported. Paths
containing `!`, `%`, `^`, embedded quotes or control characters are refused with
guidance; use a simpler name for that file or folder.

The final MKV is saved in your selected output folder. Your original source is
not modified, and existing destination files are not overwritten.

## Temporary files and troubleshooting

The application uses `docs/temp` for generated working videos. These are removed
automatically after successful completion and when you confirm a fresh run.
Do not store source movies or personal files in `docs/temp`.

If processing stops, close the program before changing temporary files. You may
then delete `docs/temp` to reclaim space, or keep it while troubleshooting. A new
run starts from the beginning; **automatic resume is not available**. Never
delete or move temporary files while the program is running.

Small diagnostic records are kept separately in `docs/logs`. If you need help,
share the relevant logs and the message shown in the program window; do not
upload your film. A destination file left after an error may be incomplete.

## Source presentation

On the 4K Blu-ray disc of BvS, the different types of scenes are encoded as follows:
- The video file container is 3840 x 2160 (1.78:1 / 16:9).
- The IMAX sequences have an active image of 3080 x 2160 (1.43:1) pillarboxed (*black bars right and left*) within a 3840 x 2160 (1.78:1) container.
- The Scope sequences have an active image of 3840 x 1606 (2.39:1) letterboxed (*black bars top and bottom*) within a 3840 x 2160 (1.78:1) container.

![IMAX 1 43 - variable width](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/88eb1174-3b0c-4d0b-9249-8e6eac907e47)

---

<br>

## 1. IMAX 1.78:1
> ...*à la Nolan* IMAX Blu-ray discs
  - IMAX sequences **cropped** to 3080 x 1732 (1.78:1), then
  - IMAX sequences upscaled to **3840 x 2160** (**1.78:1**)
  - Scope sequences left unaltered at active picture of **3840 x 1606** (**2.39:1**), **letterboxed** within a 3840 x 2160 (1.78:1) container
  - Picture **Constant-width**: 3840, Variable height: 2160 (IMAX 1.78:1 sequences), 1606 (Scope 2.39:1 sequences)
  - Active image: 3840 x 2160 (1.78:1)
  - **Container**: 3840 x 2160 (1.78:1)

**Best suited for 16:9 screens**

![IMAX 1 78](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/a18b611d-afda-47fe-9d22-59c31c8a7026)

<br>

---

## 2. IMAX 1.43:1 (unmasked)
> Mom's "*We have IMAX GT 1.43:1 at home*"
  - Scope sequences downscaled to **3080 x 1288** (**2.39:1**) active picture, 3080 x 1732 (1.78:1) container, then
  - Scope sequences container **windowboxed** (pillarboxed + letterboxed) to 3840 x 2160 (1.78:1)
  - IMAX sequences left unaltered at active picture of **3080 x 2160** (**1.43:1**), **pillarboxed** within a 3840 x 2160 (1.78:1) container
  - Picture Constant-width: 3080, Variable height: 2160 (IMAX 1.43:1 sequences), 1288 (Scope 2.39:1 sequences)
  - Active image: 3080 x 2160 (1.43:1)
  - **Container**: 3840 x 2160 (1.78:1)

**Best suited for:**
  - Projectors with ~1.43:1 wall/screen (or with decent masking options)
  - ~1.43:1 displays such as 4:3 TVs, tall monitors/screens (such as MacBooks)
  - Perfect for most recent iPads (1.43:1)
  - VR (if viewing app has a cropping tool or if pillarboxing won't be noticeable/distracting)  

> For MacBooks and native 4:3 projectors/displays, you should crop 380 px left and 380 px right of the image in your media player's settings (VLC, MPC...)

![IMAX 1 43](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/7d156169-9167-4aaf-824f-cd3eb833e2de)

---

## Community and discussion

[Reddit | r/fanedits Restoration thread](https://www.reddit.com/r/fanedits/comments/1637r5g/batman_v_superman_dawn_of_justice_ultimate/)  
[Reddit | r/fanedits Program thread](https://www.reddit.com/r/fanedits/comments/171rpft/beta_testing_fanedit_program_batman_v_superman/)  
[fanedit.org | Forums Restoration thread](https://forums.fanedit.org/threads/batman-v-superman-dawn-of-justice-ultimate-edition-imax-1-43-1-1-78-1-restorations-4k-uhd-hdr10.29021/)
