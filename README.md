# Batman-v-Superman-IMAX-Restorer
*Created by [@teymourb](https://github.com/teymourb) and [@rsquared256](https://github.com/rsquared256)*

![BvS_Poster](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/25df373b-859c-4074-b82a-663acdd5db4b)


<p align="center">
    <a href="https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/releases" target="_blank" rel="noopener"><img src="https://img.shields.io/github/release/Batman-v-Superman-IMAX-Restorer/Batman-v-Superman-IMAX-Restorer.svg" alt="Latest releases" /></a>
</p>

***Batman-v-Superman-IMAX-Restorer*** is an experimental program that allows you to restore your preferred IMAX version of the 4K Ultra HD Blu-Ray of *Batman v Superman: Dawn of Justice Ultimate Edition* with HDR10 (2021 Remaster) .

Choose between 2 **constant-width** IMAX Restorations:
<!-- toc -->

- [1. IMAX 1.78:1 - *à la Nolan* IMAX Blu-ray discs](#1-imax-1781)
- [2. IMAX 1.43:1 (unmasked) - Mom's *We have IMAX GT 1.43:1 at home*](#2-imax-1431-unmasked)

<!-- tocstop -->

#### REQUIREMENTS:  
- An unaltered .mkv rip of the 4K Ultra HD Blu-ray disc *Batman v Superman: Dawn of Justice Ultimate Edition* (2021 Remaster)
- 160 GB of free space (not including the source .mkv file)

> [!WARNING]
> No other version will work with this program! You are free to keep whichever audio and subtitle tracks you wish when ripping your disc. Only the video track needs to be the same.

<br>

#### INSTRUCTIONS:  
- Extract the zip file in a drive where you have at least 160 GB of free space  
- Select your source rip .mkv file when prompted  
- Select your destination folder for the output file  
- If prompted to accept or decline a command towards the end of the encoding, enter y for yes
- If the program is interrupted at any point or has failed, making sure to delete the *temp* folder in /docs/. This will be done automatically if the program is executed again.

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
