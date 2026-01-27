#!/usr/bin/env node

/**
 * Screenshot Generator for Govorilka App Store
 *
 * Usage:
 *   node generate.js                    # Generate all screenshots
 *   node generate.js --platform=ios     # Only iOS
 *   node generate.js --platform=macos   # Only macOS
 *   node generate.js --locale=ru        # Only Russian
 *   node generate.js --locale=en-US     # Only English
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const config = require('./config');

// Parse CLI arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    platform: null,
    locale: null,
    size: null,
  };

  for (const arg of args) {
    const [key, value] = arg.replace('--', '').split('=');
    if (key in options) {
      options[key] = value;
    }
  }

  return options;
}

// Get text for locale
function getText(item, locale) {
  const lang = locale.startsWith('en') ? 'en' : locale;
  return item[lang] || item.en;
}

// Read and process HTML template
function loadTemplate(templatePath, text, colors) {
  let html = fs.readFileSync(templatePath, 'utf8');

  // Replace placeholders
  html = html.replace(/\{\{TEXT\}\}/g, text);
  html = html.replace(/\{\{BG_START\}\}/g, colors.bgStart);
  html = html.replace(/\{\{BG_END\}\}/g, colors.bgEnd);
  html = html.replace(/\{\{PINK_PRIMARY\}\}/g, colors.pinkPrimary);
  html = html.replace(/\{\{PINK_LIGHT\}\}/g, colors.pinkLight);
  html = html.replace(/\{\{PINK_SOFT\}\}/g, colors.pinkSoft);
  html = html.replace(/\{\{TEXT_COLOR\}\}/g, colors.textColor);
  html = html.replace(/\{\{TEXT_WHITE\}\}/g, colors.textWhite);
  html = html.replace(/\{\{CLOUD_START\}\}/g, colors.cloudStart);
  html = html.replace(/\{\{CLOUD_END\}\}/g, colors.cloudEnd);
  html = html.replace(/\{\{EYE_COLOR\}\}/g, colors.eyeColor);
  html = html.replace(/\{\{BLUSH_COLOR\}\}/g, colors.blushColor);
  html = html.replace(/\{\{SHADOW\}\}/g, colors.shadow);
  html = html.replace(/\{\{GLOW\}\}/g, colors.glow);

  return html;
}

// Ensure output directory exists
function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

// Generate a single screenshot
async function generateScreenshot(browser, platform, locale, item, size) {
  const templatePath = path.join(__dirname, config.templates[platform], `${item.id}.html`);

  if (!fs.existsSync(templatePath)) {
    console.warn(`  [SKIP] Template not found: ${templatePath}`);
    return null;
  }

  const text = getText(item, locale);
  const html = loadTemplate(templatePath, text, config.colors);

  const page = await browser.newPage();
  await page.setViewport({
    width: size.width,
    height: size.height,
    deviceScaleFactor: 1,
  });

  await page.setContent(html, { waitUntil: 'networkidle0' });

  // Wait for fonts and images to load
  await page.evaluate(() => document.fonts.ready);
  await new Promise(resolve => setTimeout(resolve, 500));

  const outputDir = path.join(__dirname, config.output, platform, locale);
  ensureDir(outputDir);

  const outputPath = path.join(outputDir, `${item.id}.png`);
  await page.screenshot({ path: outputPath, type: 'png' });

  await page.close();

  return outputPath;
}

// Main generation function
async function generate(options) {
  console.log('\n🎨 Govorilka Screenshot Generator\n');
  console.log('Options:', options);
  console.log('');

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  });

  const platforms = options.platform ? [options.platform] : config.platforms;
  const locales = options.locale ? [options.locale] : config.locales;

  let generated = 0;
  let skipped = 0;

  for (const platform of platforms) {
    const sizeKey = options.size || config.defaultSizes[platform];
    const size = config.sizes[platform][sizeKey];

    if (!size) {
      console.error(`Unknown size "${sizeKey}" for platform "${platform}"`);
      continue;
    }

    console.log(`📱 Platform: ${platform.toUpperCase()} (${size.width}x${size.height})`);

    for (const locale of locales) {
      console.log(`  🌐 Locale: ${locale}`);

      const items = config.texts[platform];

      for (const item of items) {
        const result = await generateScreenshot(browser, platform, locale, item, size);

        if (result) {
          console.log(`    ✅ ${item.id}.png`);
          generated++;
        } else {
          skipped++;
        }
      }
    }

    console.log('');
  }

  await browser.close();

  console.log('─'.repeat(40));
  console.log(`✨ Done! Generated: ${generated}, Skipped: ${skipped}`);
  console.log(`📁 Output: ${path.join(__dirname, config.output)}`);
  console.log('');
}

// Run
const options = parseArgs();
generate(options).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
