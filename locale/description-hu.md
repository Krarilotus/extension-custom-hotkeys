# Custom Hotkeys

**Röviden:** A 0.1.5 az UCP bájtminta-felismerését használja az EXE hash szerinti korlátozása helyett. Az építési és rácsos gyorsbillentyűk nem mozdítják el az egérmutatót. Aktiváld a modult, és nyomd meg az F12-t; a többjátékos mód, a Recorder és az Automarket továbbra is tesztelhető.

Módosítsd a gyorsbillentyűket a játékban, és ments saját profilokat. Három billentyűzetkiosztást tartalmaz: eredeti játékvezérlés, modern RTS és rács.

Aktiváld a modult az UCP-ben, majd indítsd el a játékot: azonnal működik, nincs külön bekapcsoló vagy további testreszabási lehetőség az indítóban. Nyisd meg a gyorsbillentyűk menüpontját a főmenüben, vagy nyomd meg az **F12** billentyűt egy támogatott menüben vagy folyamatban lévő egy- vagy többjátékos játékban. Az **Ctrl+Shift+F12** akkor is megnyitja a szerkesztőt, ha az F12-t átállítottad. Kattints egy sorra, vagy jelöld ki és nyomj **Enter**-t, majd add meg a kombinációt. A **Delete** törli a kijelölt kötést; alkalmazd a változtatásokat a mentéshez. A szerkesztő a **játék nyelvét**, ez a leírás az indító nyelvét követi.

Az UCP2-Legacy **nem szükséges**. Ha aktív, a gyorsbillentyű-módosításait (`o_keys.enabled`) **ki kell kapcsolni**. A modul ezt az értéket megköveteli és aktiválás előtt ellenőrzi. Oldd fel az ütközéseket, majd indítsd újra a játékot.

**Tesztverzió:** az egérgombok átállítása, az épületcsoportok, a mentett kamerapozíciók és a teljes billentyűzetes kezelés még fejlesztés alatt áll. Teszteld az egyjátékos és többjátékos módot, a Recorder-visszajátszást és az Automarket-kombinációkat. Ez a verzió nem tilt Recorder-verzió vagy visszajátszás alapján. A játék vezérlőinek elérhetősége és a szövegmezők beviteli fókusza továbbra is érvényes. Az SHC 1.41 és az Extreme 1.41 tesztelhető; a teljes kompatibilitás ellenőrzése még hátravan.

![Gyorsbillentyűk kiválasztása a játékban](https://raw.githubusercontent.com/Krarilotus/extension-custom-hotkeys/f67fc6d9779f8ffe12b6ebd72462f317a565a160/docs/images/hotkeys-ingame.jpg)
