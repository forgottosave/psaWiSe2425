# Team 03 - Praktikum Systemadministration

<p align="center">
  <a href="mailto:ge71zig@tum.de"><img src="https://img.shields.io/badge/-ge71zig%40tum.de-red?logo=mail.ru&logoColor=white"></img></a>
  <a href="https://github.com/forgodtosave/"><img src="https://img.shields.io/badge/-Benjamin Liertz-gray?logo=github&logoColor=white"></img></a>
  <a href="[https://director.net.in.tum.de/](https://director.net.in.tum.de/teaching/ws2425/psa.html)"><img src="https://img.shields.io/badge/-https://director.net.in.tum.de/-blue?logo=onnx&logoColor=white"></img></a>
  <a href="https://github.com/forgottosave/"><img src="https://img.shields.io/badge/-Timon Ensel-gray?logo=github&logoColor=white"></img></a>
  <a href="mailto:timon.ensel@tum.de"><img src="https://img.shields.io/badge/-timon.ensel%40tum.de-red?logo=mail.ru&logoColor=white"></img></a>
</p>

This repository contains all the [documentation](README.md#Wiki) & all [NixOS config files](README.md#Configs) of Team 3 of the "Praktikum Systemadministration".
We use currently use [obsidian](https://obsidian.md/) as the Markdown editor for everything.

## TODOs

- [x] 1) dirs von anderen Teammembers von deren fileserver -> T1 geht nicht. T2 & T4 gemountet. Soll ich noch mehr machen?
- [x] 1) security team 9 network scann
- [ ] 1) mail tests
- [ ] 1) export github to wiki (Blatt 9)
- [x] 2) homeassistant prometheus
- [x] 2) fix no_root_squash + webserver accessrm b
- [x] 2) rebuild + (restart) order (fileserver, db, router, ....) (done: VM 6,8,)
- [ ] 2) git squash
- [ ] 3) ldap grafana
- [ ] 4) web + mails quellen
- [ ] 4) dns zone transver
- [ ] 5) curl bug
- [ ] 5) test_skripts only on vms according to number

Submission:

| Blatt | Doku (in psa.in.tum.de) | VMs (laufen) | Anmerkungen                  |
| ----- | ----------------------- | ------------ | ---------------------------- |
| all   |                         |              |                              |

## Virtual Machines

Team VMs: https://psa.in.tum.de/xwiki/bin/view/PSA%20WiSe%202024%20%202025/Teams/

| VM | Purpose | Works | Config Ready | Anmerkungen (was fehlt)                     |
| -- | ------- | ----- | ------------ | ------------------------------------------- |
| 1  | default | X     | !            |                                             |
| 2  | db-copy |       | !            | abhängig VM 4                               |
| 3  | router  |       |              |                                             |
| 4  | db      |       | !            | abhängig VM 8                               |
| 5  | web-app | !     | !            |                                             |
| 6  | website |       | !            | abhängig VM 8                               |
| 7  | ldap    |       |              | fehlt komplett!                             |
| 8  | files   |       |              | *broken*                                    |
| 9  | mail    |       |              |                                             |
| 10 | monitor | !     | !            |                                             |

- *Works* = is providing its intended service
- *Config Ready* = config probably complete (regardless of if it runs right now)

## Wiki

The documentation of all projects can be found in `wiki/`.

- [`Blatt 01`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt01.md)
- [`Blatt 02`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt02.md)
- [`Blatt 03`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt03.md)
- [`Blatt 04`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt04.md)
- [`Blatt 05`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt05.md)
- [`Blatt 06`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt06.md)
- [`Blatt 07`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt07.md)
- [`Blatt 08`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt08.md)
- [`Blatt 09`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt09.md)
- [`Blatt 10`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt10.md)
- [`Blatt 11`](https://github.com/forgottosave/psaWiSe2425/blob/main/wiki/blatt11.md)

## NixOS Configuration

see [here](https://github.com/forgottosave/psaWiSe2425/blob/main/scrips/README.md)
