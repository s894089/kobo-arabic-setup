# إعداد كوبو للقراءة العربية

<div dir="rtl">

إعداد جاهز لقراءة العربية على أجهزة **Kobo**: قارئ **KOReader** مع خطوط نسخ
عربية، وقاموسَي عربي‑إنجليزي وإنجليزي‑عربي، ومجموعة إضافات مختارة — بأمر واحد.

**كتبك ومواضع قراءتك وتظليلاتك وإحصاءاتك لا تُمَسّ.**

📖 **[الدليل الكامل — عربي وإنجليزي](docs/guide.html)** — ما هو Kobo وNickelMenu
وKOReader، والتهيئة على كل نظام، وما الذي يتغيّر بالضبط، وكيف ترتّب مكتبتك.
افتحه في المتصفّح بعد الاستنساخ.

</div>

---

## ما الذي يُثبَّت

<div dir="rtl">

| | |
|---|---|
| **KOReader** | الإصدار v2026.07.1 — أقوى بكثير من قارئ Kobo، خصوصًا مع ملفات PDF |
| **Amiri** | خط نسخ كلاسيكي، ومعه **AmiriQuran** المضبوط للتشكيل الكامل |
| **عربي ← إنجليزي** | ‏٢٦٬٥٧٨ كلمة، مع فهرس تصريفات (فتُعرَف «والكتاب» على أنها «كتاب») |
| **إنجليزي ← عربي** | ‏٨٧٬٤٢٣ كلمة |
| **Project: Title** | واجهة مكتبة أوضح وأسرع تصفّحًا |
| **App Store** | تصفّح إضافات KOReader وثبّتها وحدّثها من الجهاز نفسه |
| **LocalSend** | نقل ملفات لاسلكي، بلا كابل ولا خادم |

ويُضبط كذلك: العربية لغةً لنصّ الكتاب — فيصحّ ضبط الأسطر وفصل المقاطع.
أمّا **واجهة البرنامج فتبقى بالإنجليزية**؛ المتغيّر هو طريقة عرض النص لا القوائم.

</div>

---

## المتطلّبات

<div dir="rtl">

1. **جهاز Kobo عليه [NickelMenu](https://pgaskin.net/NickelMenu/) مسبقًا.**
   هذه الحزمة تُثبّت KOReader ولا تُثبّت NickelMenu. وبما أن NickelMenu هو
   الطريق الوحيد لتشغيل KOReader، فبدونه ستكون ثبّتّ قارئًا لا تستطيع فتحه.
2. **صدفة فيها `rsync` و`git` و`python3`** — انظر نظامك أدناه.
3. **‏٢٠٠ ميغابايت فارغة** على الجهاز.
4. الجهاز **موصول ومفتوح القفل، وضغطت فيه Connect**.

### macOS

كل شيء موجود أصلًا — `rsync` و`git` و`python3` تأتي مع النظام (قد يُطلب منك
تثبيت Xcode command line tools أول مرة).

يظهر الجهاز في `/Volumes/KOBOeReader` ويُكتشَف تلقائيًا.

### Linux

</div>

```bash
sudo apt install git rsync python3          # Debian / Ubuntu
sudo dnf install git rsync python3          # Fedora
```

<div dir="rtl">

يظهر الجهاز عادةً في `/media/$USER/KOBOeReader` أو `/run/media/$USER/KOBOeReader`،
وكلاهما يُكتشَف تلقائيًا.

### Windows

السكربتات مكتوبة بـ bash، فتحتاج إحدى طريقتين:

**الأولى — WSL (المستحسنة).** في PowerShell كمسؤول:

</div>

```powershell
wsl --install
```

<div dir="rtl">

أعد التشغيل، افتح **Ubuntu** من قائمة ابدأ، ثم:

</div>

```bash
sudo apt update && sudo apt install git rsync python3
```

<div dir="rtl">

يظهر الجهاز في WSL كحرف قرص تحت `/mnt` — فإن كان القرص `E:` صار `/mnt/e`،
وتجده السكربتات تلقائيًا.

**الثانية — Git Bash.** يعطيك صدفة bash، لكنه **لا يتضمّن `rsync`** وهو أساس
هذه السكربتات، فتضطر لإضافته يدويًا. لذا WSL أبسط بكثير.

وإن لم يُعثر على جهازك، أشِر إليه مباشرة:

</div>

```bash
KOBO_MOUNT=/mnt/e ./install.sh
```

---

## التثبيت

<div dir="rtl">

ثلاث خطوات. استنسخ في أي مجلد تريد — لا حاجة لمسار معيّن.

**١.** وصّل جهاز Kobo، افتح قفله، واضغط **Connect** على شاشته.

**٢.** استنسخ وادخل المجلد:

</div>

```bash
git clone https://github.com/s894089/kobo-arabic-setup.git
cd kobo-arabic-setup
```

<div dir="rtl">

**٣.** شغّل:

</div>

```bash
./install.sh
```

<div dir="rtl">

هذا كل شيء. يأخذ نسخة احتياطية أولًا، يعرض ما سيفعله، ثم يسألك `y` للمتابعة.
وإن لم يجد جهاز Kobo فسيتوقّف دون أن يغيّر شيئًا.

ثم: أخرِج القرص ← **NickelMenu ← Reboot** ← **NickelMenu ← KOReader+**

أول تشغيل بطيء لأنه يبني ذاكرة الأغلفة. هذا طبيعي.

للمعاينة قبل التنفيذ:

</div>

```bash
./install.sh --dry-run
```

---

## إضافة الكتب

<div dir="rtl">

مجلد `library/` يأتي فارغًا، فالاستنساخ لا يمسّ كتبك. ضع مجلدات كتبك بداخله —
مجلدًا لكل موضوع — ثم شغّل `./install.sh` مرّة أخرى.

</div>

```
kobo-arabic-setup/library/
    تاريخ/
        اسم الكتاب - المؤلف.epub
    روايات/
        اسم الكتاب - المؤلف.epub
```

<div dir="rtl">

نسخ الكتب **يضيف فقط**: لا يحذف شيئًا موجودًا على الجهاز، ولا يلمس مجلدات
`.sdr` التي تحمل التظليلات والملاحظات ومواضع القراءة.

</div>

---

## التراجع

```bash
./install.sh --restore
```

<div dir="rtl">

كل تشغيل يأخذ نسخة احتياطية إلى `backups/<التاريخ>/` قبل أن يكتب أي شيء.

إن لم يُعثر على جهازك:

</div>

```bash
KOBO_MOUNT=/mnt/e ./install.sh
```

---

## ما يُستبدل وما يبقى

<div dir="rtl">

**يُستبدل** — `.adds/koreader/` و`.adds/nm/menu` و`.kobo/dict/` و`fonts/`

**يبقى دائمًا** — كتبك · كل مجلدات `.sdr` (مواضع القراءة والتظليلات) ·
`statistics.sqlite3` · `history.lua` · مفردات vocabulary builder · إعدادات KoInsight

يستعمل المثبّت `rsync --delete` حتى تُزال فعلًا الإضافات التي أسقطتها هذه الحزمة
بدل أن تبقى معلّقة — لكن كل ملف شخصي مذكور أعلاه مستثنى من النسخ ومن الحذف معًا.

</div>

---

## ملاحظة مهمّة على مجلدات `.sdr`

<div dir="rtl">

يحفظ KOReader موضع قراءتك وتظليلاتك وإعدادات كل كتاب في مجلد `.sdr` **بجانب
الكتاب، والربط بينهما بالاسم**. فإن غيّرت اسم كتاب أو نقلته، غيّر اسم مجلده
بالطريقة نفسها في الوقت نفسه، وإلا فقدت تظليلاته.

هذا المثبّت لا يلمس هذه المجلدات إطلاقًا.

</div>

---

## المصادر والرخص

- [KOReader](https://github.com/koreader/koreader) — AGPL-3.0
- [Project: Title](https://github.com/joshuacant/ProjectTitle) — ثبّت الإصدار الذي يذكر رقم KOReader لديك
- [App Store](https://github.com/omer-faruq/appstore.koplugin) — omer-faruq
- [LocalSend for KOReader](https://github.com/kaikozlov/localsend.koplugin) — kaikozlov
- [Amiri](https://github.com/aliftype/amiri) — خالد حسني، رخصة SIL OFL 1.1
- قاموس عربي‑إنجليزي — [wiktionary_stardict](https://github.com/xxyzz/wiktionary_stardict)، بيانات Wiktionary، رخصة CC BY-SA 4.0
- قاموس إنجليزي‑عربي — محوّل عن بيانات [Arabeyes](https://www.arabeyes.org/)

<div dir="rtl">

سكربتات هذا المستودع تحت رخصة MIT. أمّا البرمجيات المضمّنة فتبقى تحت رخصها،
وهي مرفقة بجانب كلٍّ منها.

النسخة الإنجليزية من هذا الملف: **[README.en.md](README.en.md)**

</div>
