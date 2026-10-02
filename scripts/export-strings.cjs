#!/usr/bin/env node
/**
 * Exports the Fire TV app's UI string table (src/i18n/strings.ts) and the
 * ALLERGEN_NAMES map to JSON resources bundled by the tvOS app.
 *
 * Usage (from this repo root):
 *   TV_REPO=../fifirecipes-amazonfire node scripts/export-strings.cjs
 *
 * The TV repo's own copy of jiti does the TypeScript evaluation, so this
 * script stays dependency-free in this repo.
 *
 * The Fire TV table already uses remote/TV wording ("press Retry", "big
 * screen"), so unlike the iOS export there are no wording overrides — only
 * EXTRA, the tvOS-only keys the other platforms don't need.
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const tvRepo = path.resolve(process.env.TV_REPO || '../fifirecipes-amazonfire');
const jiti = require(path.join(tvRepo, 'node_modules/jiti/lib/jiti.cjs'))(__filename);

const stringsPath = path.join(tvRepo, 'src/i18n/strings.ts');
const mod = jiti(stringsPath);
const { STRINGS, EN } = mod;

if (!STRINGS || !EN) throw new Error('STRINGS/EN exports not found in strings.ts');
if (Object.keys(STRINGS).length !== 25) {
  throw new Error(`expected 25 languages, got ${Object.keys(STRINGS).length}`);
}

// tvOS-only strings. WKWebView doesn't exist on tvOS, so videos hand off to
// the YouTube Apple TV app — this is the fallback when it isn't installed.
const EXTRA = {
  youtubeAppNeeded: {
    en: 'The YouTube app isn’t installed on this Apple TV. Install it free from the App Store to watch.',
    ar: 'تطبيق يوتيوب مش متسطّب على Apple TV ده. سطّبيه ببلاش من App Store عشان تشوفي الفيديو.',
    de: 'Die YouTube-App ist auf diesem Apple TV nicht installiert. Installiere sie kostenlos aus dem App Store, um das Video anzusehen.',
    el: 'Η εφαρμογή YouTube δεν είναι εγκατεστημένη σε αυτό το Apple TV. Εγκαταστήστε τη δωρεάν από το App Store για να παρακολουθήσετε.',
    es: 'La app de YouTube no está instalada en este Apple TV. Instálala gratis desde el App Store para ver el video.',
    fa: 'اپلیکیشن YouTube روی این Apple TV نصب نیست. برای تماشا، آن را رایگان از App Store نصب کنید.',
    fr: 'L’app YouTube n’est pas installée sur cette Apple TV. Installez-la gratuitement depuis l’App Store pour regarder la vidéo.',
    he: 'אפליקציית YouTube לא מותקנת על Apple TV הזה. התקינו אותה בחינם מה-App Store כדי לצפות.',
    hi: 'इस Apple TV पर YouTube ऐप इंस्टॉल नहीं है। वीडियो देखने के लिए इसे App Store से मुफ़्त इंस्टॉल करें।',
    id: 'Aplikasi YouTube belum terpasang di Apple TV ini. Pasang gratis dari App Store untuk menonton.',
    it: 'L’app YouTube non è installata su questa Apple TV. Installala gratis dall’App Store per guardare il video.',
    ja: 'この Apple TV には YouTube アプリが入っていません。App Store から無料でインストールしてご覧ください。',
    ko: '이 Apple TV에는 YouTube 앱이 설치되어 있지 않아요. App Store에서 무료로 설치하면 시청할 수 있어요.',
    ku: 'Sepana YouTube li ser vê Apple TV’yê ne sazkirî ye. Ji bo temaşekirinê wê ji App Store’ê belaş saz bike.',
    nl: 'De YouTube-app is niet geïnstalleerd op deze Apple TV. Installeer hem gratis via de App Store om te kijken.',
    pl: 'Aplikacja YouTube nie jest zainstalowana na tym Apple TV. Zainstaluj ją za darmo z App Store, aby obejrzeć.',
    ps: 'په دې Apple TV کې د YouTube اپ نه دی نصب شوی. د لیدلو لپاره یې له App Store څخه وړیا نصب کړئ.',
    pt: 'O app do YouTube não está instalado nesta Apple TV. Instale-o gratuitamente na App Store para assistir.',
    ru: 'Приложение YouTube не установлено на этом Apple TV. Установите его бесплатно из App Store, чтобы посмотреть видео.',
    sv: 'YouTube-appen är inte installerad på den här Apple TV:n. Installera den gratis från App Store för att titta.',
    te: 'ఈ Apple TVలో YouTube యాప్ ఇన్‌స్టాల్ చేయలేదు. చూడటానికి దాన్ని App Store నుండి ఉచితంగా ఇన్‌స్టాల్ చేయండి.',
    sw: 'Programu ya YouTube haijasakinishwa kwenye Apple TV hii. Isakinishe bure kutoka App Store ili kutazama.',
    tr: 'Bu Apple TV’de YouTube uygulaması yüklü değil. Videoyu izlemek için App Store’dan ücretsiz yükleyin.',
    ur: 'اس Apple TV پر YouTube ایپ انسٹال نہیں ہے۔ ویڈیو دیکھنے کے لیے اسے App Store سے مفت انسٹال کریں۔',
    zh: '此 Apple TV 未安装 YouTube 应用。可从 App Store 免费安装后观看。',
  },
};

for (const [lang, t] of Object.entries(STRINGS)) {
  for (const [key, table] of Object.entries(EXTRA)) {
    t[key] = table[lang] ?? table.en;
  }
}

// ALLERGEN_NAMES is module-private; strings.ts exposes allergenName().
// Rebuild the per-language map through the public function so the JSON
// carries the same fallback-resolved values.
const fsSrc = fs.readFileSync(stringsPath, 'utf8');
const am = fsSrc.match(/const ALLERGEN_NAMES[^=]*=\s*(\{[\s\S]*?\n\});/);
if (!am) throw new Error('ALLERGEN_NAMES literal not found');
const ALLERGEN_NAMES = new Function(`return (${am[1]})`)();

const outDir = path.join(repoRoot, 'FifiRecipesTV', 'Resources');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(
  path.join(outDir, 'ui-strings.json'),
  JSON.stringify({ strings: STRINGS, allergens: ALLERGEN_NAMES }, null, 0) + '\n',
);
console.log(`wrote ui-strings.json: ${Object.keys(STRINGS).length} languages, ` +
  `${Object.keys(ALLERGEN_NAMES).length} allergen tables`);
