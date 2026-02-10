import '../../domain/repositories/gallery_repository.dart';

class LocalGalleryRepository implements GalleryRepository {
  @override
  Future<List<Map<String, String>>> getTemplates() async {
    // Simulate network delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {
        "name": "Crypto Ticker",
        "description": "Live Bitcoin price tracker using CoinGecko API.",
        "content": r'''
// Crypto Ticker
// Fetches BTC price from CoinGecko API

const url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd";

async function run() {
  try {
    const req = new Request(url);
    const json = await req.loadJSON();
    const btcPrice = json.bitcoin.usd;
    
    const w = new ListWidget();
    w.backgroundColor = new Color("#1a1a1a");
    
    const title = w.addText("Bitcoin");
    title.textColor = Color.orange();
    title.font = Font.boldSystemFont(16);
    
    w.addSpacer(8);
    
    const price = w.addText("$" + btcPrice);
    price.textColor = Color.white();
    price.font = Font.systemFont(24);
    
    const date = new Date();
    const time = w.addText("Updated: " + date.toLocaleTimeString());
    time.textColor = Color.gray();
    time.font = Font.systemFont(10);
    
    Script.setWidget(w);
    Script.complete();
    
    console.log("BTC Price: " + btcPrice);
  } catch (e) {
    console.log("Error: " + e);
  }
}

await run();
''',
      },
      {
        "name": "Weather Glass",
        "description": "Beautiful glassmorphism weather widget.",
        "content": r'''
// Weather Glass Widget
// Demonstrates advanced UI features

const w = new ListWidget();
// Premium background
w.backgroundColor = new Color("#F9FAFB");
// w.backgroundImage = ... (if using local image)

const stack = w.addStack();
stack.layoutVertically();

const city = stack.addText("San Francisco");
city.font = Font.boldSystemFont(20);
city.textColor = new Color("#1F2937");

stack.addSpacer(4);

const temp = stack.addText("72°");
temp.font = Font.systemFont(48);
temp.textColor = new Color("#3B82F6");

stack.addSpacer(8);

const condition = stack.addText("Partly Cloudy");
condition.font = Font.mediumSystemFont(14);
condition.textColor = Color.gray();

// Add Glassmorphism effect via native modifier (if supported in future)
// For now, relies on native rendering style.

Script.setWidget(w);
Script.complete();
''',
      },
      {
        "name": "System Status",
        "description": "Monitor system device info.",
        "content": r'''
// System Status
// Shows device information

const w = new ListWidget();
w.backgroundColor = new Color("#22C55E");

const title = w.addText("System Online");
title.textColor = Color.white();
title.font = Font.boldSystemFont(18);

w.addSpacer();

const deviceName = Device.name();
const osVersion = Device.systemVersion();

const info = w.addText(deviceName + " • iOS " + osVersion);
info.textColor = Color.white();
info.textOpacity = 0.8;
info.font = Font.systemFont(12);

Script.setWidget(w);
Script.complete();
''',
      },
      {
        "name": "Quote of Day",
        "description": "Inspirational quotes API.",
        "content": r'''
// Quote of the Day
const url = "https://api.quotable.io/random";

async function fetchQuote() {
  const req = new Request(url);
  const data = await req.loadJSON();
  return data;
}

const data = await fetchQuote();
const w = new ListWidget();
w.backgroundColor = new Color("#8B5CF6");

const text = w.addText('"' + data.content + '"');
text.textColor = Color.white();
text.font = Font.italicSystemFont(16);
text.centerAlignText();

w.addSpacer(10);

const author = w.addText("- " + data.author);
author.textColor = Color.white();
author.textOpacity = 0.8;
author.rightAlignText();
author.font = Font.systemFont(12);

Script.setWidget(w);
Script.complete();  
''',
      },
    ];
  }
}
