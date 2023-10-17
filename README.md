# Batman-v-Superman-IMAX-Restorer
Restore your preferred IMAX version of the 4K Ultra HD Blu-Ray of Batman v Superman: Dawn of Justice Ultimate Edition (Remastered) HDR10.

On the 4K Blu-ray disc of BvS, the different types of scenes are encoded as follows:
- The video file container is 3840 x 2160 (1.78:1 / 16:9).
- The IMAX sequences have an active image of 3080 x 2160 (1.43:1) pillarboxed (black bars right and left) within a 3840 x 2160 (1.78:1) container.
- The Scope sequences have an active image of 3840 x 1606 (2.39:1) letterboxed (black bars top and bottom) within a 3840 x 2160 (1.78:1) container.

![IMAX 1 43 - variable width](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/7ecbed44-5201-4299-ae5e-8234d3ebfff2)

Choose between the following 2 constant-width IMAX versions:

---

1) IMAX 1.78:1 - à la Nolan IMAX Blu-ray discs
  - IMAX sequences cropped to 3080 x 1732 (1.78:1), then
  - IMAX sequences upscaled to 3840 x 2160 (1.78:1)
  - Scope sequences left unaltered at active picture of 3840 x 1606 (2.39:1), letterboxed within a 3840 x 2160 (1.78:1) container
  - Picture Constant-width: 3840, Variable height: 2160 (IMAX 1.78:1 sequences), 1606 (Scope 2.39:1 sequences)
  - Active image: 3840 x 2160 (1.78:1)
  - Container: 3840 x 2160 (1.78:1)

![IMAX 1 78](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/d7843e2f-b7d7-400a-87a2-aefc1ff61402)

Best suited for 16:9 screens

---

2) IMAX 1.43:1 (unmasked) - Mom's "We have IMAX GT 1.43:1 at home"
  - Scope sequences downscaled to 3080 x 1288 (2.39:1) active picture, 3080 x 1732 (1.78:1) container, then
  - Scope sequences container windowboxed (pillarboxed + letterboxed) to 3840 x 2160 (1.78:1)
  - IMAX sequences left unaltered at active picture of 3080 x 2160 (1.43:1), pillarboxed within a 3840 x 2160 (1.78:1) container
  - Picture Constant-width: 3080, Variable height: 2160 (IMAX 1.43:1 sequences), 1288 (Scope 2.39:1 sequences)
  - Active image: 3080 x 2160 (1.43:1)
  - Container: 3840 x 2160 (1.78:1)

Best suited for:
  - Projectors with ~1.43:1 wall/screen (or with decent masking options)
  - ~1.43:1 displays such as 4:3 TVs, tall monitors/screens (such as MacBooks)
  - Perfect for most recent iPads (1.43:1)
  - VR (if viewing app has a cropping tool or if pillarboxing won't be noticeable/distracting)
Viewing setups instructions:
  Using VLC, you can crop 380 px left and 380 px right for MacBooks or native 4:3 projectors/displays

![IMAX 1 43_unmasked](https://github.com/teymourb/Batman-v-Superman-IMAX-Restorer/assets/53331006/e47e86e6-9bc2-4fad-bbce-993d7e53db02)
  
  ---

More info here: https://www.reddit.com/r/fanedits/comments/1637r5g/batman_v_superman_dawn_of_justice_ultimate/
